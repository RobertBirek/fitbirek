import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/providers/planner_providers.dart';
import '../data/activity_repository.dart';
import '../domain/activity_schedule.dart';
import '../domain/weekly_schedule.dart';
import '../providers/schedule_providers.dart';
import 'activity_list_page.dart';

class ActivityEditorPage extends ConsumerStatefulWidget {
  const ActivityEditorPage({
    super.key,
    this.ruleId,
    this.type = ActivityType.external,
  });
  final String? ruleId;
  final ActivityType type;
  @override
  ConsumerState<ActivityEditorPage> createState() => _ActivityEditorPageState();
}

class _ActivityEditorPageState extends ConsumerState<ActivityEditorPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _time = TextEditingController(),
      _duration = TextEditingController(),
      _lead = TextEditingController(text: '0');
  ActivitySnapshot? _lease;
  List<SavedPlan> _plans = [];
  Set<int> _days = {};
  late ActivityType _type;
  String? _plan, _error, _account;
  int? _epoch;
  late final CachedAuthWriteAuthority _authority;
  bool _loading = true,
      _busy = false,
      _stale = false,
      _enabled = true,
      _reminders = false;
  bool _guard() =>
      mounted &&
      !_stale &&
      ref.read(cachedAuthWriteAuthorityProvider).epoch == _epoch &&
      ref.read(filterPresetsAccountProvider).valueOrNull == _account;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _account = ref.read(filterPresetsAccountProvider).valueOrNull;
    _authority = ref.read(cachedAuthWriteAuthorityProvider);
    _epoch = _authority.epoch;
    _authority.revision.addListener(_authorityChanged);
    Future.microtask(_load);
  }

  void _authorityChanged() {
    if (mounted && _authority.epoch != _epoch) setState(_invalidate);
  }

  void _invalidate() {
    _stale = true;
    _lease = null;
    _plans = [];
    _days.clear();
    _plan = null;
    _error = null;
    _enabled = false;
    _reminders = false;
    _name.clear();
    _time.clear();
    _duration.clear();
    _lead.clear();
  }

  Future<void> _load() async {
    try {
      if (_account == null) {
        final account = await ref.read(filterPresetsAccountProvider.future);
        if (!mounted ||
            _stale ||
            ref.read(cachedAuthWriteAuthorityProvider).epoch != _epoch) {
          return;
        }
        _account = account;
      }
      if (_account == null) {
        throw StateError('Brak lokalnego dostępu do konta.');
      }
      // Capture once, before reading private templates or showing the form.
      final lease = await ref
          .read(activityRepositoryProvider)
          .snapshot(_account!, isCurrent: _guard);
      if (!_guard()) return;
      final plans = await ref.read(plannerRepositoryProvider).readAll();
      if (!_guard()) return;
      final rule = lease.rules.where((r) => r.id == widget.ruleId).firstOrNull;
      if (widget.ruleId != null && rule == null) {
        throw StateError('Reguła jest niedostępna.');
      }
      _lease = lease;
      _plans = plans
          .where((p) => !p.isUnavailable && p.syncId != null)
          .toList();
      if (rule != null) {
        _type = rule.activityType;
        _name.text = rule.name;
        _time.text = rule.time ?? '';
        _duration.text = rule.durationMinutes?.toString() ?? '';
        _days = rule.weekdays.toSet();
        _plan = rule.planSyncId;
        _enabled = rule.enabled;
        _reminders = rule.reminderEnabled;
        _lead.text = '${rule.reminderMinutesBefore}';
      }
    } catch (e) {
      if (_guard()) _error = '$e';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          if (!_guard()) _invalidate();
        });
      }
    }
  }

  Future<void> _save() async {
    if (_busy ||
        !_guard() ||
        _lease == null ||
        !_form.currentState!.validate()) {
      return;
    }
    if (_days.isEmpty) {
      setState(() => _error = 'Wybierz co najmniej jeden dzień.');
      return;
    }
    if (_plan != null && !_plans.any((p) => p.syncId == _plan)) {
      setState(
        () => _error =
            'Plan niedostępny. Wybierz istniejący szablon lub jawnie trening swobodny.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = ActivityDraft(
        name: _name.text.trim(),
        activityType: _type,
        weekdays: _days,
        time: _time.text,
        effectiveFrom: CalendarDay.local(DateTime.now()),
        durationMinutes: int.tryParse(_duration.text),
        enabled: _enabled,
        planSyncId: _type == ActivityType.fitbirek ? _plan : null,
        reminderEnabled: _reminders,
        reminderMinutesBefore: int.parse(_lead.text),
      );
      final repo = ref.read(activityRepositoryProvider);
      if (widget.ruleId == null) {
        await repo.create(_lease!, draft, isCurrent: _guard);
      } else {
        await repo.update(_lease!, widget.ruleId!, draft, isCurrent: _guard);
      }
      if (mounted && _guard()) context.pop();
    } catch (e) {
      if (_guard()) setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (!_guard()) _invalidate();
        });
      }
    }
  }

  @override
  void dispose() {
    _authority.revision.removeListener(_authorityChanged);
    _name.dispose();
    _time.dispose();
    _duration.dispose();
    _lead.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, _) {
      if (!_guard()) setState(_invalidate);
    });
    ref.listen(filterPresetsAccountProvider, (_, _) {
      if (_loading && _account == null && _lease == null) return;
      if (!_guard()) setState(_invalidate);
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ruleId == null ? 'Nowa aktywność' : 'Edytuj aktywność',
        ),
      ),
      body: _stale
          ? const Center(
              child: Text(
                'Konto zmieniło się. Formularz wyczyszczono. Otwórz go ponownie.',
              ),
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Europe/Warsaw • Godzina terminu, nie przypomnienia. Starsza reguła wymaga jawnego wyboru godziny.',
                    ),
                    if (_error != null) Text(_error!),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nazwa'),
                      maxLength: 80,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Podaj nazwę' : null,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var d = 1; d <= 7; d++)
                          FilterChip(
                            label: Text(activityWeekdays[d - 1]),
                            selected: _days.contains(d),
                            onSelected: _busy
                                ? null
                                : (selected) => setState(() {
                                    if (selected) {
                                      _days.add(d);
                                    } else {
                                      _days.remove(d);
                                    }
                                  }),
                          ),
                      ],
                    ),
                    TextFormField(
                      controller: _time,
                      decoration: InputDecoration(
                        labelText: 'Godzina HH:mm',
                        suffixIcon: IconButton(
                          tooltip: 'Wybierz godzinę',
                          icon: const Icon(Icons.access_time),
                          onPressed: _busy
                              ? null
                              : () async {
                                  final parts = _time.text.split(':');
                                  final hour = parts.length == 2
                                      ? int.tryParse(parts[0])
                                      : null;
                                  final minute = parts.length == 2
                                      ? int.tryParse(parts[1])
                                      : null;
                                  final initial =
                                      hour != null &&
                                          hour >= 0 &&
                                          hour < 24 &&
                                          minute != null &&
                                          minute >= 0 &&
                                          minute < 60
                                      ? TimeOfDay(hour: hour, minute: minute)
                                      : const TimeOfDay(hour: 0, minute: 0);
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: initial,
                                  );
                                  if (time != null && _guard()) {
                                    setState(
                                      () => _time.text =
                                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    );
                                  }
                                },
                        ),
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (v) =>
                          RegExp(
                            r'^(?:[01]\d|2[0-3]):[0-5]\d$',
                          ).hasMatch(v ?? '')
                          ? null
                          : 'Podaj godzinę HH:mm (00:00–23:59)',
                    ),
                    TextFormField(
                      controller: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Czas trwania (min, opcjonalnie)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null ||
                              v.isEmpty ||
                              (int.tryParse(v) != null &&
                                  int.parse(v) >= 1 &&
                                  int.parse(v) <= 1440)
                          ? null
                          : 'Podaj 1–1440 minut',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Włączona'),
                      value: _enabled,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _enabled = v),
                    ),
                    if (_type == ActivityType.fitbirek)
                      DropdownButtonFormField<String>(
                        initialValue: _plan ?? '',
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Szablon'),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Trening swobodny'),
                          ),
                          if (_plan != null &&
                              !_plans.any((p) => p.syncId == _plan))
                            DropdownMenuItem(
                              value: _plan,
                              child: const Text('Plan niedostępny'),
                            ),
                          for (final p in _plans)
                            DropdownMenuItem(
                              value: p.syncId,
                              child: Text(
                                p.nazwa,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _plan = v == '' ? null : v),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Przypomnienie'),
                      value: _reminders,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _reminders = v),
                    ),
                    const Text(
                      'Dostarczenie wymaga osobno włączonych uprawnień i kategorii na tym urządzeniu. Ten formularz nie prosi o zgodę.',
                    ),
                    TextFormField(
                      controller: _lead,
                      decoration: const InputDecoration(
                        labelText: 'Minuty przed terminem',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          int.tryParse(v ?? '') != null &&
                              int.parse(v!) >= 0 &&
                              int.parse(v) <= 1440
                          ? null
                          : 'Podaj 0–1440 minut',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy || _lease == null ? null : _save,
                      child: const Text('Zapisz'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => context.pop(),
                      child: const Text('Anuluj'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
