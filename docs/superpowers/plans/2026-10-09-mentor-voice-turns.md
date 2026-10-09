# Mentor Voice Turns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a completed microphone recording send a Mentor question and play its reply automatically, while typed chat remains text-only.

**Architecture:** Keep STT, chat and TTS as their existing independent idempotent operations. The page owns the voice-turn intent: after transcription it sends the transcript with an `autoPlayReply` flag, then prepares and attempts playback for the resulting assistant message. A rejected browser play promise leaves the prepared audio available through the existing manual control.

**Tech Stack:** Flutter, Riverpod, flutter_test, browser audio bridge.

---

### Task 1: Define Voice-Turn Regression Tests

**Files:**
- Modify: `test/features/mentor/mentor_flow_test.dart:200-290, 760-807`
- Modify: `lib/features/mentor/presentation/pages/mentor_page.dart:151-318`

- [ ] **Step 1: Extend `VoiceFake` for a rejected automatic play**

Add `bool rejectNextPlay = false;` and make `play()` throw once when it is set:

```dart
@override
Future<void> play() async {
  plays++;
  if (rejectNextPlay) {
    rejectNextPlay = false;
    throw StateError('autoplay denied');
  }
}
```

- [ ] **Step 2: Write the failing voice-turn widget test**

Mount with `ApiFake` and `VoiceFake`, start then stop recording, settle the
widget, and assert that the fake made one STT call, one chat send, one speech
call, one `preparePlayback` call and one `play` call. Assert that the user and
assistant messages are present.

- [ ] **Step 3: Write the failing typed-chat regression test**

Enter text, tap `Wyślij`, settle, and assert that `api.sends == 1`, while the
voice fake has `prepares == 0` and `plays == 0`.

- [ ] **Step 4: Write the failing autoplay-fallback test**

Set `voice.rejectNextPlay = true`, perform the voice turn, and assert that the
manual `Odtwórz` control is visible. Tap it and assert that `api.speechCalls`
remains one while `voice.plays` becomes two.

- [ ] **Step 5: Run the three tests and verify they fail**

Run: `flutter test test/features/mentor/mentor_flow_test.dart --plain-name "voice turn"`

Expected: the current page only fills the text field after transcription, so it
does not send, request TTS or play automatically.

### Task 2: Implement The Voice Turn

**Files:**
- Modify: `lib/features/mentor/presentation/pages/mentor_page.dart:151-318`
- Test: `test/features/mentor/mentor_flow_test.dart`

- [ ] **Step 1: Allow `_send` to opt into reply playback**

Add an `autoPlayReply` parameter defaulting to `false`. After a successful
conversation send, read the newest assistant message only when the original
page generation is still current, then call `_play(reply, autoStart: true)`.
Keep the existing input-clearing condition and leave normal sends with the
default `false`.

- [ ] **Step 2: Complete a recording as one automatic turn**

After successful transcription, assign `_input.text = text`, clear `_voiceBusy`
before dispatching, then call `_send(autoPlayReply: true)`. Do not show the
manual transcript-review notice. Keep the existing generation and mounted checks
before every async transition.

- [ ] **Step 3: Attempt playback without treating autoplay rejection as TTS failure**

Add `autoStart` to `_play`, defaulting to `false`. After `preparePlayback(data)`,
set `_playing` and its existing TTL. If `autoStart` is true, await `_voice.play()`
inside a nested try/catch; on failure show a notice that manual playback is
available and keep `_playing` set. Do not invoke regeneration or request speech
again.

- [ ] **Step 4: Run the focused Mentor widget tests**

Run: `flutter test test/features/mentor/mentor_flow_test.dart`

Expected: PASS, including the existing manual speech test and all three new
voice-turn tests.

- [ ] **Step 5: Format only the touched Dart files**

Run: `dart format lib/features/mentor/presentation/pages/mentor_page.dart test/features/mentor/mentor_flow_test.dart`

Expected: no unrelated files change.

### Task 3: Verify The Full Client

**Files:**
- Verify: `lib/features/mentor/presentation/pages/mentor_page.dart`
- Verify: `test/features/mentor/mentor_flow_test.dart`

- [ ] **Step 1: Run analysis and the complete Flutter suite**

Run: `flutter analyze && flutter test`

Expected: no analysis diagnostics and all tests pass.

- [ ] **Step 2: Inspect the final scope**

Run: `git diff --check && git status --short`

Expected: only the Mentor voice-turn implementation, its tests and the approved
documentation are new changes.
