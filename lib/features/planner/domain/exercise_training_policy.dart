import '../../../core/models/exercise.dart';
import '../../exercises/domain/exercise_filter_engine.dart';

/// Conservative, catalog-audited movement vocabulary. Unknown/compound labels
/// are deliberately NOT inferred from the first word or an exercise ID.
class ExerciseTrainingPolicy {
  static String _fold(String text) => ExerciseFilterEngine.fold(text).trim();

  static const _families = <String, String>{
    'push horyzontalny': 'horizontal_push',
    'push horyzontalny (tempo)': 'horizontal_push',
    'push wertykalny': 'vertical_push',
    'pull horyzontalny': 'horizontal_pull',
    'pull wertykalny': 'vertical_pull',
    'pull wertykalny eksc': 'vertical_pull',
    'squat': 'squat',
    'squat (jednonoz)': 'squat',
    'hinge': 'hinge',
    'hinge (posladki)': 'hinge',
    'lunge': 'lunge',
    'lunge (jednonoz)': 'lunge',
    'lunge (unilateralne)': 'lunge',
    'push horyzontalny izolacja': 'chest_fly',
    'biceps': 'elbow_flexion',
    'biceps (metoda)': 'elbow_flexion',
    'zginanie lokci': 'elbow_flexion',
    // Generic "Triceps" also labels multi-joint bench dips in the catalog;
    // only an explicit movement function is evidence of elbow isolation.
    'prostowanie lokci': 'elbow_extension',
    'lydka': 'calf_raise',
    'soleus': 'seated_calf_raise',
    'przednia golen': 'dorsiflexion',
    'anty-ekstensja': 'anti_extension',
    'anty-fleksja boczna': 'anti_lateral_flexion',
    'anty-rotacja': 'anti_rotation',
    // Narrow rehabilitation functions; these are not aliases for strength
    // hinges, generic rotation, core, flow or isometry.
    'kontrola pochylenia miednicy': 'pelvic_tilt_control',
    'stabilizacja tulowia bez ruchu konczyn': 'trunk_stabilization',
    'lagodna rotacja tulowia w lezeniu': 'supine_trunk_rotation',
    'rotacja piersiowa w lezeniu bokiem': 'side_lying_thoracic_rotation',
    'zgiecie biodra z lagodnym rozciaganiem plecow': 'hip_flexion_back_stretch',
    'zawias biodrowy z kontrola tulowia': 'controlled_trunk_hip_hinge',
  };
  static const _multiJoint = {
    'horizontal_push',
    'vertical_push',
    'horizontal_pull',
    'vertical_pull',
    'squat',
    'hinge',
    'lunge',
  };
  static const _isolationPatterns = {
    'izolacja',
    'push horyzontalny izolacja',
    'biceps',
    'biceps (metoda)',
    'zginanie lokci',
    'prostowanie lokci',
    'lydka',
    'soleus',
    'przednia golen',
    'boczny akton',
    'przedni akton',
    'tylny akton',
    'rotator',
    'supraspinatus',
    'zginacze',
    'prostowniki',
    'odwodziciele',
    'adduktory',
  };

  static String? movementFamily(Exercise exercise) =>
      _families[_fold(exercise.wzorzecRuchu)];

  /// String keys keep this shared policy independent of plan/wire models.
  static String sectionKeyFor(Exercise exercise) {
    final type = _fold(exercise.typ);
    if (type.contains('rozgrzew')) return 'warmup';
    if (type.contains('rozciag') || type.contains('stretch')) return 'cooldown';
    return 'main';
  }

  static bool _recovery(Exercise exercise) {
    final type = _fold(exercise.typ);
    return sectionKeyFor(exercise) != 'main' ||
        const {'regeneracja', 'mobilnosc', 'joga', 'yoga'}.contains(type);
  }

  static bool _recoveryStyle(List<String> styles) =>
      styles.any(const {'yoga', 'mobility_recovery'}.contains);

  /// Equipment, level and selected filters must ALSO pass the shared engine.
  /// Metadata absence is not permission to guess from the legacy body part.
  static bool compatible({
    required Exercise source,
    required Exercise candidate,
    required ExerciseFilterEngine engine,
  }) {
    final a = engine.metadata.entryFor(source.id);
    final b = engine.metadata.entryFor(candidate.id);
    final family = movementFamily(source);
    if (!engine.classificationAvailable ||
        a == null ||
        b == null ||
        family == null ||
        family != movementFamily(candidate) ||
        a.tracking != b.tracking ||
        a.unilateral != b.unilateral ||
        sectionKeyFor(source) != sectionKeyFor(candidate) ||
        (_recovery(source) || _recoveryStyle(a.styles)) !=
            (_recovery(candidate) || _recoveryStyle(b.styles))) {
      return false;
    }
    final primary = a.primaryMuscles.toSet();
    final other = b.primaryMuscles.toSet();
    return primary.isNotEmpty &&
        !primary.any((m) => m.trim().isEmpty) &&
        primary.length == other.length &&
        primary.containsAll(other);
  }

  /// The same rest decision applies to catalog doses and fallback doses.
  static ({int seconds, bool fallback}) restFor(Exercise exercise) {
    final type = _fold(exercise.typ);
    if (_recovery(exercise)) return (seconds: 0, fallback: false);
    if (const {'wytrzymalosc', 'izometria'}.contains(type)) {
      return (seconds: 30, fallback: false);
    }
    if (type == 'explosive') return (seconds: 120, fallback: false);
    if (type.contains('izolac') ||
        _isolationPatterns.contains(_fold(exercise.wzorzecRuchu))) {
      return (seconds: 60, fallback: false);
    }
    if (_multiJoint.contains(movementFamily(exercise))) {
      if (type == 'sila') return (seconds: 120, fallback: false);
      if (type == 'hipertrofia') return (seconds: 90, fallback: false);
    }
    return (seconds: 30, fallback: true);
  }
}
