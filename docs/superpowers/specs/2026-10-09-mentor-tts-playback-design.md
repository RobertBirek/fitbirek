# Mentor Voice Turns

## Problem

Voice recording currently stops after transcription and requires the user to
manually send the text, prepare TTS and start playback. Text chat must remain
text-only.

## Design

Stopping a microphone recording creates one voice turn: the client transcribes
the recording, sends the transcript and requests TTS for the resulting assistant
message. It prepares and attempts to play the returned MP3 automatically.

The existing idempotent STT, chat and TTS operations remain in use. If the
browser rejects automatic playback, the audio remains prepared and the existing
manual playback control is available without another provider request. Typed
messages retain the existing text-only behavior.

## Verification

Add regression tests proving that a recorded turn sends, prepares and plays the
assistant response automatically; typed messages do not use TTS; and an
automatic-playback failure retains a manual retry without new TTS work.
