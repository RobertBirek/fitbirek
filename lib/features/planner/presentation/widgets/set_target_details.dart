import '../../domain/set_prescription.dart';
import '../../../../core/models/set_role.dart';

String setTargetDetails(SetPrescription target) =>
    '${SetRole.label(target.setRole)} • '
    '${target.reps == null ? '${target.seconds} s' : '${target.reps} powt.'}'
    '${target.weightKg == null ? '' : ' • ${target.weightKg} kg'}'
    '${target.side == null ? '' : ' • ${const {'left': 'Lewa', 'right': 'Prawa', 'both': 'Obie'}[target.side]}'}'
    ' • praca EST. ${target.workSeconds} s • przerwa ${target.restSeconds} s';
