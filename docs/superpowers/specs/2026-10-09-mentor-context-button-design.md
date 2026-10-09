# Mentor Context Button

## Problem

The context button next to Send appears enabled when the draft is empty, but
its handler returns without feedback because a context selection requires a
message. This looks like a non-responsive control.

## Design

The context button is disabled when the trimmed draft is empty, while a send is
in progress, or when Mentor text chat is unavailable. A `ValueListenableBuilder`
listens to the existing text controller so the button state follows edits without
rebuilding the full conversation page.

## Behavior

- An empty or whitespace-only draft disables the context button.
- Entering non-whitespace text enables it when chat is otherwise enabled.
- Pressing the enabled button opens the existing context composer.
- Voice transcription updates the same controller and therefore enables the
  button when it produces text.

## Verification

Add a widget test that confirms the button is disabled for an empty draft,
enabled after typing text, and opens the context composer.
