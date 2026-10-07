const test = require('node:test');
const assert = require('node:assert/strict');

class FakeStream {
  constructor() {
    this.track = { stopped: false, stop: () => { this.track.stopped = true; } };
  }
  getTracks() { return [this.track]; }
}

class FakeRecorder {
  static supported = new Set(['audio/webm;codecs=opus', 'audio/mp4']);
  static instances = [];
  static isTypeSupported(type) { return this.supported.has(type); }
  constructor(stream, options = {}) {
    this.stream = stream;
    this.mimeType = options.mimeType || '';
    this.state = 'inactive';
    this.listeners = {};
    FakeRecorder.instances.push(this);
  }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  emit(name, event = {}) { for (const callback of this.listeners[name] || []) callback(event); }
  start(timeslice) { this.timeslice = timeslice; this.state = 'recording'; }
  stop() { if (this.state === 'inactive') return; this.state = 'inactive'; this.emit('stop'); }
  emitData(bytes, type = this.mimeType) {
    const blob = new Blob([new Uint8Array(bytes)], { type });
    this.emit('dataavailable', { data: blob });
  }
}

function installBrowser({ mediaPromise, getUserMedia, now = () => 0, audioPlay } = {}) {
  FakeRecorder.instances = [];
  const listeners = {};
  const timers = [];
  const urls = [];
  const revokedUrls = [];
  const audios = [];
  const addListener = (name, callback) => (listeners[name] ||= new Set()).add(callback);
  const removeListener = (name, callback) => listeners[name]?.delete(callback);
  Object.defineProperty(global, 'navigator', {
    configurable: true,
    value: { mediaDevices: { getUserMedia: getUserMedia || (() => mediaPromise) } },
  });
  global.MediaRecorder = FakeRecorder;
  global.document = {
    hidden: false,
    addEventListener: addListener,
    removeEventListener: removeListener,
  };
  global.addEventListener = addListener;
  global.removeEventListener = removeListener;
  global.URL = {
    createObjectURL: () => `blob:${urls.push(1)}`,
    revokeObjectURL: (url) => revokedUrls.push(url),
  };
  global.Audio = class {
    constructor(url) { this.url = url; this.pauseCalls = 0; audios.push(this); }
    play() { return audioPlay ? audioPlay() : Promise.resolve(); }
    pause() { this.pauseCalls++; }
  };
  global.Blob = Blob;
  global.Date.now = now;
  global.setTimeout = (callback, delay) => {
    const timer = { callback, delay, cleared: false };
    timers.push(timer);
    return timer;
  };
  global.clearTimeout = (timer) => { if (timer) timer.cleared = true; };
  return {
    listeners,
    timers,
    audios,
    revokedUrls,
    dispatch: (name) => { for (const callback of listeners[name] || []) callback(); },
  };
}

function loadBridge() {
  delete require.cache[require.resolve('../../web/mentor_voice.js')];
  return require('../../web/mentor_voice.js');
}

test('records webm and returns codec-free MIME, bytes and bounded duration', async () => {
  const stream = new FakeStream();
  installBrowser({ mediaPromise: Promise.resolve(stream), now: () => 12_500 });
  const voice = loadBridge();

  await voice.startRecording();
  const recorder = FakeRecorder.instances.at(-1);
  assert.equal(recorder.timeslice, 250);
  recorder.emitData(4);
  const recording = await voice.stopRecording();

  assert.equal(recording.contentType, 'audio/webm');
  assert.equal(recording.bytes.byteLength, 4);
  assert.equal(recording.durationSeconds, 0);
  assert.equal(stream.track.stopped, true);
});

test('uses Safari audio/mp4 when webm is unsupported', async () => {
  FakeRecorder.supported = new Set(['audio/mp4']);
  const stream = new FakeStream();
  installBrowser({ mediaPromise: Promise.resolve(stream) });
  const voice = loadBridge();

  await voice.startRecording();
  const recorder = FakeRecorder.instances.at(-1);
  assert.equal(recorder.mimeType, 'audio/mp4');
  recorder.emitData(1, 'audio/mp4;codecs=mp4a.40.2');
  const recording = await voice.stopRecording();

  assert.equal(recording.contentType, 'audio/mp4');
});

test('stops and rejects recording that exceeds 2 MiB', async () => {
  FakeRecorder.supported = new Set(['audio/webm;codecs=opus']);
  const stream = new FakeStream();
  installBrowser({ mediaPromise: Promise.resolve(stream) });
  const voice = loadBridge();

  await voice.startRecording();
  const recorder = FakeRecorder.instances.at(-1);
  recorder.emitData(2 * 1024 * 1024 + 1);

  await assert.rejects(voice.stopRecording(), /2 MiB/);
  assert.equal(stream.track.stopped, true);
});

test('automatically stops at 30 seconds and stop retrieves that recording', async () => {
  let now = 0;
  const stream = new FakeStream();
  const environment = installBrowser({ mediaPromise: Promise.resolve(stream), now: () => now });
  const voice = loadBridge();

  await voice.startRecording();
  const recorder = FakeRecorder.instances.at(-1);
  recorder.emitData(2);
  now = 31_000;
  environment.timers.find((timer) => timer.delay === 30_000).callback();
  const recording = await voice.stopRecording();

  assert.equal(recording.durationSeconds, 30);
  assert.equal(stream.track.stopped, true);
});

test('dispose cancels pending microphone access and cleans the resolved stream', async () => {
  let resolveMedia;
  const mediaPromise = new Promise((resolve) => { resolveMedia = resolve; });
  installBrowser({ mediaPromise });
  const voice = loadBridge();

  const starting = voice.startRecording();
  voice.dispose();
  const stream = new FakeStream();
  resolveMedia(stream);

  await assert.rejects(starting, /anulowane/i);
  assert.equal(stream.track.stopped, true);
  assert.equal(FakeRecorder.instances.length, 0);
});

test('reinstalls page lifecycle cleanup when recording starts after dispose', async () => {
  const first = new FakeStream();
  const second = new FakeStream();
  const environment = installBrowser({
    getUserMedia: (() => {
      const streams = [first, second];
      return () => Promise.resolve(streams.shift());
    })(),
  });
  const voice = loadBridge();

  await voice.startRecording();
  FakeRecorder.instances.at(-1).emitData(1);
  await voice.stopRecording();
  voice.dispose();
  await voice.startRecording();
  environment.dispatch('pagehide');

  assert.equal(second.track.stopped, true);
});

test('does not retain a slow cancelled recording after a new recording starts', async () => {
  const first = new FakeStream();
  const second = new FakeStream();
  let releaseSlowChunk;
  const slowChunk = {
    size: 3,
    arrayBuffer: () => new Promise((resolve) => { releaseSlowChunk = resolve; }),
  };
  installBrowser({
    getUserMedia: (() => {
      const streams = [first, second];
      return () => Promise.resolve(streams.shift());
    })(),
  });
  const voice = loadBridge();

  await voice.startRecording();
  FakeRecorder.instances.at(-1).emit('dataavailable', { data: slowChunk });
  const cancelledStop = voice.stopRecording();
  voice.dispose();
  await voice.startRecording();
  const secondRecorder = FakeRecorder.instances.at(-1);
  secondRecorder.emitData(1);
  releaseSlowChunk(new Uint8Array([7, 8, 9]).buffer);

  await assert.rejects(cancelledStop, /anulowane/i);
  const recording = await voice.stopRecording();
  assert.equal(recording.bytes.byteLength, 1);
});

test('prepares playback without playing until play is explicitly invoked', async () => {
  const stream = new FakeStream();
  const environment = installBrowser({ mediaPromise: Promise.resolve(stream) });
  const voice = loadBridge();

  await voice.preparePlayback(new Uint8Array([1, 2, 3]));
  assert.equal(environment.audios.length, 1);
  await voice.play();
  assert.equal(environment.audios[0].pauseCalls, 0);
  voice.stopPlayback();
  assert.equal(environment.audios[0].pauseCalls, 1);
  voice.dispose();
});

test('bounds playback bytes and revokes the URL after playback error or TTL', async () => {
  const stream = new FakeStream();
  const environment = installBrowser({
    mediaPromise: Promise.resolve(stream),
    audioPlay: () => Promise.reject(new Error('autoplay denied')),
  });
  const voice = loadBridge();

  await assert.rejects(voice.preparePlayback(new Uint8Array(2 * 1024 * 1024 + 1)), /2 MiB/);
  await voice.preparePlayback(new Uint8Array([1]));
  await assert.rejects(voice.play(), /autoplay denied/);
  assert.deepEqual(environment.revokedUrls, ['blob:1']);
  await voice.preparePlayback(new Uint8Array([2]));
  environment.timers.find((timer) => timer.delay === 60_000).callback();
  await assert.rejects(voice.play(), /Brak przygotowanego/);
  assert.deepEqual(environment.revokedUrls, ['blob:1', 'blob:2']);
});
