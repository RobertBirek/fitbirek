(function (root) {
  'use strict';

  const MAX_BYTES = 2 * 1024 * 1024;
  const MAX_SECONDS = 30;
  const PLAYBACK_TTL_MS = 60 * 1000;
  const MIME_TYPES = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4'];
  let generation = 0;
  let recording = null;
  let finishedRecording = null;
  let completed = null;
  let completedError = null;
  let playback = null;
  let disposed = false;
  let lifecycleInstalled = false;

  function supported() {
    return Boolean(root.navigator && root.navigator.mediaDevices &&
      typeof root.navigator.mediaDevices.getUserMedia === 'function' &&
      typeof root.MediaRecorder === 'function');
  }

  function stopTracks(stream) {
    if (stream && typeof stream.getTracks === 'function') {
      stream.getTracks().forEach((track) => track.stop());
    }
  }

  function mimeType() {
    for (const type of MIME_TYPES) {
      if (typeof root.MediaRecorder.isTypeSupported !== 'function' ||
          root.MediaRecorder.isTypeSupported(type)) return type;
    }
    return '';
  }

  function normalizedMime(type) {
    const bare = String(type || '').split(';', 1)[0].toLowerCase();
    if (bare === 'audio/webm' || bare === 'audio/mp4') return bare;
    throw new Error('Nieobsługiwany format nagrania.');
  }

  function clearRecording(state) {
    root.clearTimeout(state.timeout);
    stopTracks(state.stream);
    if (recording === state) recording = null;
  }

  function clearCompleted() {
    completed = null;
    completedError = null;
    finishedRecording = null;
  }

  function isCurrent(state) {
    return !state.cancelled && !disposed && state.generation === generation;
  }

  function cancellationError() {
    return new Error('Nagrywanie zostało anulowane.');
  }

  function rejectState(state, error) {
    if (state.rejected) return;
    state.rejected = true;
    state.chunks.length = 0;
    state.reject(error);
  }

  function settle(state) {
    if (state.closed) return;
    state.closed = true;
    clearRecording(state);
    if (!isCurrent(state)) {
      rejectState(state, cancellationError());
      return;
    }
    finishedRecording = state;
    if (state.tooLarge) {
      completedError = new Error('Nagranie przekracza limit 2 MiB.');
      rejectState(state, completedError);
      return;
    }
    const chunks = state.chunks;
    state.chunks = [];
    Promise.all(chunks.map((chunk) => chunk.arrayBuffer())).then((parts) => {
      if (!isCurrent(state)) throw cancellationError();
      const size = parts.reduce((total, part) => total + part.byteLength, 0);
      if (size > MAX_BYTES) throw new Error('Nagranie przekracza limit 2 MiB.');
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const part of parts) {
        bytes.set(new Uint8Array(part), offset);
        offset += part.byteLength;
      }
      const result = {
        bytes,
        contentType: normalizedMime(state.recorder.mimeType || state.type),
        durationSeconds: Math.min(MAX_SECONDS, Math.max(0, (Date.now() - state.startedAt) / 1000)),
      };
      if (!isCurrent(state)) throw cancellationError();
      completed = result;
      state.resolve(result);
    }).catch((error) => {
      if (isCurrent(state)) completedError = error;
      rejectState(state, error);
    });
  }

  function requestStop(state) {
    if (!state || state.stopRequested) return;
    state.stopRequested = true;
    root.clearTimeout(state.timeout);
    if (state.recorder.state !== 'inactive') state.recorder.stop();
    else settle(state);
  }

  async function startRecording() {
    if (!supported()) throw new Error('Nagrywanie głosu nie jest obsługiwane.');
    cancelRecording();
    disposed = false;
    clearCompleted();
    installLifecycle();
    const requestGeneration = ++generation;
    const stream = await root.navigator.mediaDevices.getUserMedia({ audio: true });
    if (disposed || requestGeneration !== generation) {
      stopTracks(stream);
      throw new Error('Nagrywanie zostało anulowane.');
    }
    const type = mimeType();
    let recorder;
    try {
      recorder = type ? new root.MediaRecorder(stream, { mimeType: type }) : new root.MediaRecorder(stream);
    } catch (error) {
      stopTracks(stream);
      throw error;
    }
    return new Promise((resolveStart, rejectStart) => {
      let resolveDone;
      let rejectDone;
      const state = {
        stream, recorder, type, chunks: [], tooLarge: false,
        startedAt: Date.now(), timeout: null, stopRequested: false, closed: false,
        cancelled: false, rejected: false, generation: requestGeneration,
        done: new Promise((resolve, reject) => {
          resolveDone = resolve;
          rejectDone = reject;
        }),
        resolve: resolveDone,
        reject: rejectDone,
      };
      state.done.catch(() => {});
      recording = state;
      recorder.addEventListener('dataavailable', (event) => {
        if (!event.data || event.data.size === 0 || state.closed || state.cancelled) return;
        state.chunks.push(event.data);
        const bytes = state.chunks.reduce((total, chunk) => total + chunk.size, 0);
        if (bytes > MAX_BYTES) {
          state.tooLarge = true;
          requestStop(state);
        }
      });
      recorder.addEventListener('stop', () => settle(state));
      recorder.addEventListener('error', () => {
        if (!state.closed) {
          state.closed = true;
          clearRecording(state);
          rejectState(state, new Error('Nie udało się nagrać dźwięku.'));
        }
      });
      state.timeout = root.setTimeout(() => requestStop(state), MAX_SECONDS * 1000);
      try {
        recorder.start(250);
      } catch (error) {
        state.closed = true;
        clearRecording(state);
        rejectState(state, error);
        rejectStart(error);
        return;
      }
      resolveStart();
    });
  }

  async function stopRecording() {
    if (completed) return consumeCompleted();
    if (completedError) {
      const error = completedError;
      clearCompleted();
      throw error;
    }
    if (finishedRecording) return consumeAfter(finishedRecording.done);
    if (!recording) throw new Error('Brak aktywnego nagrania.');
    const state = recording;
    requestStop(state);
    return consumeAfter(state.done);
  }

  async function consumeAfter(done) {
    const result = await done;
    if (completed === result) clearCompleted();
    return result;
  }

  function consumeCompleted() {
    const result = completed;
    clearCompleted();
    return result;
  }

  function cancelRecording() {
    generation++;
    const state = recording || finishedRecording;
    clearCompleted();
    if (!state) return;
    state.cancelled = true;
    clearRecording(state);
    if (state.recorder.state !== 'inactive') state.recorder.stop();
    rejectState(state, cancellationError());
  }

  function clearPlayback() {
    if (!playback) return;
    root.clearTimeout(playback.ttl);
    playback.audio.pause();
    playback.audio.currentTime = 0;
    root.URL.revokeObjectURL(playback.url);
    playback = null;
  }

  async function preparePlayback(bytes) {
    disposed = false;
    installLifecycle();
    clearPlayback();
    if (!bytes || bytes.byteLength > MAX_BYTES) {
      throw new Error('Dźwięk przekracza limit 2 MiB.');
    }
    const blob = new root.Blob([bytes], { type: 'audio/mpeg' });
    const url = root.URL.createObjectURL(blob);
    try {
      const audio = new root.Audio(url);
      const state = {
        url,
        audio,
        ttl: root.setTimeout(clearPlayback, PLAYBACK_TTL_MS),
      };
      playback = state;
      if (typeof audio.addEventListener === 'function') {
        audio.addEventListener('error', () => {
          if (playback === state) clearPlayback();
        });
      }
    } catch (error) {
      root.URL.revokeObjectURL(url);
      throw error;
    }
  }

  async function play() {
    if (!playback) throw new Error('Brak przygotowanego dźwięku.');
    try {
      await playback.audio.play();
    } catch (error) {
      clearPlayback();
      throw error;
    }
  }

  function stopPlayback() {
    if (!playback) return;
    playback.audio.pause();
    playback.audio.currentTime = 0;
  }

  function dispose() {
    disposed = true;
    cancelRecording();
    clearPlayback();
    root.document.removeEventListener('visibilitychange', onVisibilityChange);
    root.removeEventListener('pagehide', onPageHide);
    lifecycleInstalled = false;
  }

  function onVisibilityChange() {
    if (root.document.hidden) cancelRecording();
  }

  function onPageHide() {
    cancelRecording();
    clearPlayback();
  }

  function installLifecycle() {
    if (lifecycleInstalled) return;
    if (root.document) root.document.addEventListener('visibilitychange', onVisibilityChange);
    if (typeof root.addEventListener === 'function') root.addEventListener('pagehide', onPageHide);
    lifecycleInstalled = true;
  }

  installLifecycle();

  const api = {
    isSupported: supported,
    startRecording,
    stopRecording,
    cancelRecording,
    preparePlayback,
    play,
    stopPlayback,
    dispose,
  };
  root.fitMentorVoice = api;
  if (typeof module !== 'undefined') module.exports = api;
})(typeof window !== 'undefined' ? window : globalThis);
