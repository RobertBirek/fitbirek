import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Cel treningowy użytkownika.
enum CelTreningowy { redukcja, sila, masa, kondycja, mix }

extension CelTreningowyLabel on CelTreningowy {
  String get label {
    switch (this) {
      case CelTreningowy.redukcja:
        return 'Redukcja';
      case CelTreningowy.sila:
        return 'Siła';
      case CelTreningowy.masa:
        return 'Masa';
      case CelTreningowy.kondycja:
        return 'Kondycja';
      case CelTreningowy.mix:
        return 'Mix';
    }
  }
}

/// Profil użytkownika aplikacji - single user, bez rejestracji.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @Default(1) int id,
    required String imie,
    required int wiek,
    required double wzrostCm,
    required double wagaKg,
    required CelTreningowy cel,
    required List<String> dostepnySprzet,
    @Default(false) bool onboardingZakonczony,
    required DateTime dataUtworzenia,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
