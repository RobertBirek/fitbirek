# Mentor Context Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Mentor context button unavailable until the current draft contains non-whitespace text.

**Architecture:** Keep the existing `_composeContext` guard as defense in depth. Wrap only the context button in a `ValueListenableBuilder` over the existing `_input` controller, so its enabled state follows edits without rebuilding the conversation page. Add a widget regression test at the page boundary.

**Tech Stack:** Flutter, Material widgets, Riverpod, flutter_test.

---

### Task 1: Cover Context Button State

**Files:**
- Modify: `test/features/mentor/mentor_flow_test.dart:524-570`
- Modify: `lib/features/mentor/presentation/pages/mentor_page.dart:700-705`

- [ ] **Step 1: Write the failing widget test**

Add this test before the existing `context composer previews only consented categories` test:

```dart
testWidgets('context action requires a non-empty draft', (tester) async {
  await mount(
    tester,
    ApiFake(),
    VoiceFake(),
    configuredSettings: mentorSettings(
      consents: const MentorContextConsents(training: true),
    ),
  );

  final contextAction = find.byTooltip('Dodaj kontekst do tej wiadomości');
  expect(tester.widget<IconButton>(contextAction).onPressed, isNull);

  await tester.enterText(find.byType(TextField), '   ');
  await tester.pump();
  expect(tester.widget<IconButton>(contextAction).onPressed, isNull);

  await tester.enterText(find.byType(TextField), 'Sprawdź mój plan');
  await tester.pump();
  expect(tester.widget<IconButton>(contextAction).onPressed, isNotNull);

  await tester.tap(contextAction);
  await tester.pumpAndSettle();
  expect(find.text('Kontekst tej wiadomości'), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/mentor/mentor_flow_test.dart --plain-name "context action requires a non-empty draft"`

Expected: FAIL because the empty draft still leaves the context button enabled.

- [ ] **Step 3: Implement the minimal button-state update**

Replace the current context `IconButton.outlined` with:

```dart
ValueListenableBuilder<TextEditingValue>(
  valueListenable: _input,
  child: const Icon(Icons.tune),
  builder: (context, value, child) => IconButton.outlined(
    tooltip: 'Dodaj kontekst do tej wiadomości',
    onPressed: state.loading || !enabled || value.text.trim().isEmpty
        ? null
        : _composeContext,
    icon: child!,
  ),
),
```

Keep `_composeContext` unchanged: its empty-draft check remains the protection against a programmatic or stale invocation.

- [ ] **Step 4: Run the focused test to verify it passes**

Run: `flutter test test/features/mentor/mentor_flow_test.dart --plain-name "context action requires a non-empty draft"`

Expected: PASS.

- [ ] **Step 5: Run the Mentor widget-test file**

Run: `flutter test test/features/mentor/mentor_flow_test.dart`

Expected: PASS with no changed behavior in sending, voice recording, or the existing context composer flow.

- [ ] **Step 6: Format and commit the focused change**

Run: `dart format lib/features/mentor/presentation/pages/mentor_page.dart test/features/mentor/mentor_flow_test.dart`

```bash
git add lib/features/mentor/presentation/pages/mentor_page.dart test/features/mentor/mentor_flow_test.dart
git commit -m "fix: disable empty mentor context action"
```

### Task 2: Full Flutter Verification

**Files:**
- Verify: `lib/features/mentor/presentation/pages/mentor_page.dart`
- Verify: `test/features/mentor/mentor_flow_test.dart`

- [ ] **Step 1: Run the Flutter quality gate**

Run: `dart format . && flutter analyze && flutter test`

Expected: formatter makes no additional unrelated changes, analysis reports no diagnostics, and all Flutter tests pass.

- [ ] **Step 2: Inspect the final scope**

Run: `git diff --check && git status --short`

Expected: only the Mentor page and its focused test are changed, plus any already-existing unrelated working-tree changes.
