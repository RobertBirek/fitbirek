// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _imieMeta = const VerificationMeta('imie');
  @override
  late final GeneratedColumn<String> imie = GeneratedColumn<String>(
    'imie',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Robert'),
  );
  static const VerificationMeta _wiekMeta = const VerificationMeta('wiek');
  @override
  late final GeneratedColumn<int> wiek = GeneratedColumn<int>(
    'wiek',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wzrostCmMeta = const VerificationMeta(
    'wzrostCm',
  );
  @override
  late final GeneratedColumn<double> wzrostCm = GeneratedColumn<double>(
    'wzrost_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wagaKgMeta = const VerificationMeta('wagaKg');
  @override
  late final GeneratedColumn<double> wagaKg = GeneratedColumn<double>(
    'waga_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _celMeta = const VerificationMeta('cel');
  @override
  late final GeneratedColumn<String> cel = GeneratedColumn<String>(
    'cel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dostepnySprzetMeta = const VerificationMeta(
    'dostepnySprzet',
  );
  @override
  late final GeneratedColumn<String> dostepnySprzet = GeneratedColumn<String>(
    'dostepny_sprzet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onboardingZakonczonyMeta =
      const VerificationMeta('onboardingZakonczony');
  @override
  late final GeneratedColumn<bool> onboardingZakonczony = GeneratedColumn<bool>(
    'onboarding_zakonczony',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_zakonczony" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dataUtworzeniaMeta = const VerificationMeta(
    'dataUtworzenia',
  );
  @override
  late final GeneratedColumn<DateTime> dataUtworzenia =
      GeneratedColumn<DateTime>(
        'data_utworzenia',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imie,
    wiek,
    wzrostCm,
    wagaKg,
    cel,
    dostepnySprzet,
    onboardingZakonczony,
    dataUtworzenia,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('imie')) {
      context.handle(
        _imieMeta,
        imie.isAcceptableOrUnknown(data['imie']!, _imieMeta),
      );
    }
    if (data.containsKey('wiek')) {
      context.handle(
        _wiekMeta,
        wiek.isAcceptableOrUnknown(data['wiek']!, _wiekMeta),
      );
    } else if (isInserting) {
      context.missing(_wiekMeta);
    }
    if (data.containsKey('wzrost_cm')) {
      context.handle(
        _wzrostCmMeta,
        wzrostCm.isAcceptableOrUnknown(data['wzrost_cm']!, _wzrostCmMeta),
      );
    } else if (isInserting) {
      context.missing(_wzrostCmMeta);
    }
    if (data.containsKey('waga_kg')) {
      context.handle(
        _wagaKgMeta,
        wagaKg.isAcceptableOrUnknown(data['waga_kg']!, _wagaKgMeta),
      );
    } else if (isInserting) {
      context.missing(_wagaKgMeta);
    }
    if (data.containsKey('cel')) {
      context.handle(
        _celMeta,
        cel.isAcceptableOrUnknown(data['cel']!, _celMeta),
      );
    } else if (isInserting) {
      context.missing(_celMeta);
    }
    if (data.containsKey('dostepny_sprzet')) {
      context.handle(
        _dostepnySprzetMeta,
        dostepnySprzet.isAcceptableOrUnknown(
          data['dostepny_sprzet']!,
          _dostepnySprzetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dostepnySprzetMeta);
    }
    if (data.containsKey('onboarding_zakonczony')) {
      context.handle(
        _onboardingZakonczonyMeta,
        onboardingZakonczony.isAcceptableOrUnknown(
          data['onboarding_zakonczony']!,
          _onboardingZakonczonyMeta,
        ),
      );
    }
    if (data.containsKey('data_utworzenia')) {
      context.handle(
        _dataUtworzeniaMeta,
        dataUtworzenia.isAcceptableOrUnknown(
          data['data_utworzenia']!,
          _dataUtworzeniaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      imie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imie'],
      )!,
      wiek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wiek'],
      )!,
      wzrostCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wzrost_cm'],
      )!,
      wagaKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waga_kg'],
      )!,
      cel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cel'],
      )!,
      dostepnySprzet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dostepny_sprzet'],
      )!,
      onboardingZakonczony: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_zakonczony'],
      )!,
      dataUtworzenia: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_utworzenia'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final String imie;
  final int wiek;
  final double wzrostCm;
  final double wagaKg;
  final String cel;
  final String dostepnySprzet;
  final bool onboardingZakonczony;
  final DateTime dataUtworzenia;
  const UserProfile({
    required this.id,
    required this.imie,
    required this.wiek,
    required this.wzrostCm,
    required this.wagaKg,
    required this.cel,
    required this.dostepnySprzet,
    required this.onboardingZakonczony,
    required this.dataUtworzenia,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['imie'] = Variable<String>(imie);
    map['wiek'] = Variable<int>(wiek);
    map['wzrost_cm'] = Variable<double>(wzrostCm);
    map['waga_kg'] = Variable<double>(wagaKg);
    map['cel'] = Variable<String>(cel);
    map['dostepny_sprzet'] = Variable<String>(dostepnySprzet);
    map['onboarding_zakonczony'] = Variable<bool>(onboardingZakonczony);
    map['data_utworzenia'] = Variable<DateTime>(dataUtworzenia);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      imie: Value(imie),
      wiek: Value(wiek),
      wzrostCm: Value(wzrostCm),
      wagaKg: Value(wagaKg),
      cel: Value(cel),
      dostepnySprzet: Value(dostepnySprzet),
      onboardingZakonczony: Value(onboardingZakonczony),
      dataUtworzenia: Value(dataUtworzenia),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      imie: serializer.fromJson<String>(json['imie']),
      wiek: serializer.fromJson<int>(json['wiek']),
      wzrostCm: serializer.fromJson<double>(json['wzrostCm']),
      wagaKg: serializer.fromJson<double>(json['wagaKg']),
      cel: serializer.fromJson<String>(json['cel']),
      dostepnySprzet: serializer.fromJson<String>(json['dostepnySprzet']),
      onboardingZakonczony: serializer.fromJson<bool>(
        json['onboardingZakonczony'],
      ),
      dataUtworzenia: serializer.fromJson<DateTime>(json['dataUtworzenia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'imie': serializer.toJson<String>(imie),
      'wiek': serializer.toJson<int>(wiek),
      'wzrostCm': serializer.toJson<double>(wzrostCm),
      'wagaKg': serializer.toJson<double>(wagaKg),
      'cel': serializer.toJson<String>(cel),
      'dostepnySprzet': serializer.toJson<String>(dostepnySprzet),
      'onboardingZakonczony': serializer.toJson<bool>(onboardingZakonczony),
      'dataUtworzenia': serializer.toJson<DateTime>(dataUtworzenia),
    };
  }

  UserProfile copyWith({
    int? id,
    String? imie,
    int? wiek,
    double? wzrostCm,
    double? wagaKg,
    String? cel,
    String? dostepnySprzet,
    bool? onboardingZakonczony,
    DateTime? dataUtworzenia,
  }) => UserProfile(
    id: id ?? this.id,
    imie: imie ?? this.imie,
    wiek: wiek ?? this.wiek,
    wzrostCm: wzrostCm ?? this.wzrostCm,
    wagaKg: wagaKg ?? this.wagaKg,
    cel: cel ?? this.cel,
    dostepnySprzet: dostepnySprzet ?? this.dostepnySprzet,
    onboardingZakonczony: onboardingZakonczony ?? this.onboardingZakonczony,
    dataUtworzenia: dataUtworzenia ?? this.dataUtworzenia,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      imie: data.imie.present ? data.imie.value : this.imie,
      wiek: data.wiek.present ? data.wiek.value : this.wiek,
      wzrostCm: data.wzrostCm.present ? data.wzrostCm.value : this.wzrostCm,
      wagaKg: data.wagaKg.present ? data.wagaKg.value : this.wagaKg,
      cel: data.cel.present ? data.cel.value : this.cel,
      dostepnySprzet: data.dostepnySprzet.present
          ? data.dostepnySprzet.value
          : this.dostepnySprzet,
      onboardingZakonczony: data.onboardingZakonczony.present
          ? data.onboardingZakonczony.value
          : this.onboardingZakonczony,
      dataUtworzenia: data.dataUtworzenia.present
          ? data.dataUtworzenia.value
          : this.dataUtworzenia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('imie: $imie, ')
          ..write('wiek: $wiek, ')
          ..write('wzrostCm: $wzrostCm, ')
          ..write('wagaKg: $wagaKg, ')
          ..write('cel: $cel, ')
          ..write('dostepnySprzet: $dostepnySprzet, ')
          ..write('onboardingZakonczony: $onboardingZakonczony, ')
          ..write('dataUtworzenia: $dataUtworzenia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imie,
    wiek,
    wzrostCm,
    wagaKg,
    cel,
    dostepnySprzet,
    onboardingZakonczony,
    dataUtworzenia,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.imie == this.imie &&
          other.wiek == this.wiek &&
          other.wzrostCm == this.wzrostCm &&
          other.wagaKg == this.wagaKg &&
          other.cel == this.cel &&
          other.dostepnySprzet == this.dostepnySprzet &&
          other.onboardingZakonczony == this.onboardingZakonczony &&
          other.dataUtworzenia == this.dataUtworzenia);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<String> imie;
  final Value<int> wiek;
  final Value<double> wzrostCm;
  final Value<double> wagaKg;
  final Value<String> cel;
  final Value<String> dostepnySprzet;
  final Value<bool> onboardingZakonczony;
  final Value<DateTime> dataUtworzenia;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.imie = const Value.absent(),
    this.wiek = const Value.absent(),
    this.wzrostCm = const Value.absent(),
    this.wagaKg = const Value.absent(),
    this.cel = const Value.absent(),
    this.dostepnySprzet = const Value.absent(),
    this.onboardingZakonczony = const Value.absent(),
    this.dataUtworzenia = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.imie = const Value.absent(),
    required int wiek,
    required double wzrostCm,
    required double wagaKg,
    required String cel,
    required String dostepnySprzet,
    this.onboardingZakonczony = const Value.absent(),
    this.dataUtworzenia = const Value.absent(),
  }) : wiek = Value(wiek),
       wzrostCm = Value(wzrostCm),
       wagaKg = Value(wagaKg),
       cel = Value(cel),
       dostepnySprzet = Value(dostepnySprzet);
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<String>? imie,
    Expression<int>? wiek,
    Expression<double>? wzrostCm,
    Expression<double>? wagaKg,
    Expression<String>? cel,
    Expression<String>? dostepnySprzet,
    Expression<bool>? onboardingZakonczony,
    Expression<DateTime>? dataUtworzenia,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imie != null) 'imie': imie,
      if (wiek != null) 'wiek': wiek,
      if (wzrostCm != null) 'wzrost_cm': wzrostCm,
      if (wagaKg != null) 'waga_kg': wagaKg,
      if (cel != null) 'cel': cel,
      if (dostepnySprzet != null) 'dostepny_sprzet': dostepnySprzet,
      if (onboardingZakonczony != null)
        'onboarding_zakonczony': onboardingZakonczony,
      if (dataUtworzenia != null) 'data_utworzenia': dataUtworzenia,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? imie,
    Value<int>? wiek,
    Value<double>? wzrostCm,
    Value<double>? wagaKg,
    Value<String>? cel,
    Value<String>? dostepnySprzet,
    Value<bool>? onboardingZakonczony,
    Value<DateTime>? dataUtworzenia,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      imie: imie ?? this.imie,
      wiek: wiek ?? this.wiek,
      wzrostCm: wzrostCm ?? this.wzrostCm,
      wagaKg: wagaKg ?? this.wagaKg,
      cel: cel ?? this.cel,
      dostepnySprzet: dostepnySprzet ?? this.dostepnySprzet,
      onboardingZakonczony: onboardingZakonczony ?? this.onboardingZakonczony,
      dataUtworzenia: dataUtworzenia ?? this.dataUtworzenia,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imie.present) {
      map['imie'] = Variable<String>(imie.value);
    }
    if (wiek.present) {
      map['wiek'] = Variable<int>(wiek.value);
    }
    if (wzrostCm.present) {
      map['wzrost_cm'] = Variable<double>(wzrostCm.value);
    }
    if (wagaKg.present) {
      map['waga_kg'] = Variable<double>(wagaKg.value);
    }
    if (cel.present) {
      map['cel'] = Variable<String>(cel.value);
    }
    if (dostepnySprzet.present) {
      map['dostepny_sprzet'] = Variable<String>(dostepnySprzet.value);
    }
    if (onboardingZakonczony.present) {
      map['onboarding_zakonczony'] = Variable<bool>(onboardingZakonczony.value);
    }
    if (dataUtworzenia.present) {
      map['data_utworzenia'] = Variable<DateTime>(dataUtworzenia.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('imie: $imie, ')
          ..write('wiek: $wiek, ')
          ..write('wzrostCm: $wzrostCm, ')
          ..write('wagaKg: $wagaKg, ')
          ..write('cel: $cel, ')
          ..write('dostepnySprzet: $dostepnySprzet, ')
          ..write('onboardingZakonczony: $onboardingZakonczony, ')
          ..write('dataUtworzenia: $dataUtworzenia')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nazwaPlMeta = const VerificationMeta(
    'nazwaPl',
  );
  @override
  late final GeneratedColumn<String> nazwaPl = GeneratedColumn<String>(
    'nazwa_pl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nazwaEnMeta = const VerificationMeta(
    'nazwaEn',
  );
  @override
  late final GeneratedColumn<String> nazwaEn = GeneratedColumn<String>(
    'nazwa_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partiaGlownaMeta = const VerificationMeta(
    'partiaGlowna',
  );
  @override
  late final GeneratedColumn<String> partiaGlowna = GeneratedColumn<String>(
    'partia_glowna',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partieWspierajaceMeta = const VerificationMeta(
    'partieWspierajace',
  );
  @override
  late final GeneratedColumn<String> partieWspierajace =
      GeneratedColumn<String>(
        'partie_wspierajace',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sprzetMeta = const VerificationMeta('sprzet');
  @override
  late final GeneratedColumn<String> sprzet = GeneratedColumn<String>(
    'sprzet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typMeta = const VerificationMeta('typ');
  @override
  late final GeneratedColumn<String> typ = GeneratedColumn<String>(
    'typ',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _poziomMeta = const VerificationMeta('poziom');
  @override
  late final GeneratedColumn<String> poziom = GeneratedColumn<String>(
    'poziom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wzorzecRuchuMeta = const VerificationMeta(
    'wzorzecRuchu',
  );
  @override
  late final GeneratedColumn<String> wzorzecRuchu = GeneratedColumn<String>(
    'wzorzec_ruchu',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriexPowtorzeniaMeta = const VerificationMeta(
    'seriexPowtorzenia',
  );
  @override
  late final GeneratedColumn<String> seriexPowtorzenia =
      GeneratedColumn<String>(
        'seriex_powtorzenia',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _tempoMeta = const VerificationMeta('tempo');
  @override
  late final GeneratedColumn<String> tempo = GeneratedColumn<String>(
    'tempo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kluczoweWskazowkiMeta = const VerificationMeta(
    'kluczoweWskazowki',
  );
  @override
  late final GeneratedColumn<String> kluczoweWskazowki =
      GeneratedColumn<String>(
        'kluczowe_wskazowki',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _czesteBledyMeta = const VerificationMeta(
    'czesteBledy',
  );
  @override
  late final GeneratedColumn<String> czesteBledy = GeneratedColumn<String>(
    'czeste_bledy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progresjaMeta = const VerificationMeta(
    'progresja',
  );
  @override
  late final GeneratedColumn<String> progresja = GeneratedColumn<String>(
    'progresja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regresjaMeta = const VerificationMeta(
    'regresja',
  );
  @override
  late final GeneratedColumn<String> regresja = GeneratedColumn<String>(
    'regresja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zrodloMeta = const VerificationMeta('zrodlo');
  @override
  late final GeneratedColumn<String> zrodlo = GeneratedColumn<String>(
    'zrodlo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ulubioneMeta = const VerificationMeta(
    'ulubione',
  );
  @override
  late final GeneratedColumn<bool> ulubione = GeneratedColumn<bool>(
    'ulubione',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ulubione" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nazwaPl,
    nazwaEn,
    partiaGlowna,
    partieWspierajace,
    sprzet,
    typ,
    poziom,
    wzorzecRuchu,
    seriexPowtorzenia,
    tempo,
    kluczoweWskazowki,
    czesteBledy,
    progresja,
    regresja,
    zrodlo,
    ulubione,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nazwa_pl')) {
      context.handle(
        _nazwaPlMeta,
        nazwaPl.isAcceptableOrUnknown(data['nazwa_pl']!, _nazwaPlMeta),
      );
    } else if (isInserting) {
      context.missing(_nazwaPlMeta);
    }
    if (data.containsKey('nazwa_en')) {
      context.handle(
        _nazwaEnMeta,
        nazwaEn.isAcceptableOrUnknown(data['nazwa_en']!, _nazwaEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nazwaEnMeta);
    }
    if (data.containsKey('partia_glowna')) {
      context.handle(
        _partiaGlownaMeta,
        partiaGlowna.isAcceptableOrUnknown(
          data['partia_glowna']!,
          _partiaGlownaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partiaGlownaMeta);
    }
    if (data.containsKey('partie_wspierajace')) {
      context.handle(
        _partieWspierajaceMeta,
        partieWspierajace.isAcceptableOrUnknown(
          data['partie_wspierajace']!,
          _partieWspierajaceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partieWspierajaceMeta);
    }
    if (data.containsKey('sprzet')) {
      context.handle(
        _sprzetMeta,
        sprzet.isAcceptableOrUnknown(data['sprzet']!, _sprzetMeta),
      );
    } else if (isInserting) {
      context.missing(_sprzetMeta);
    }
    if (data.containsKey('typ')) {
      context.handle(
        _typMeta,
        typ.isAcceptableOrUnknown(data['typ']!, _typMeta),
      );
    } else if (isInserting) {
      context.missing(_typMeta);
    }
    if (data.containsKey('poziom')) {
      context.handle(
        _poziomMeta,
        poziom.isAcceptableOrUnknown(data['poziom']!, _poziomMeta),
      );
    } else if (isInserting) {
      context.missing(_poziomMeta);
    }
    if (data.containsKey('wzorzec_ruchu')) {
      context.handle(
        _wzorzecRuchuMeta,
        wzorzecRuchu.isAcceptableOrUnknown(
          data['wzorzec_ruchu']!,
          _wzorzecRuchuMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wzorzecRuchuMeta);
    }
    if (data.containsKey('seriex_powtorzenia')) {
      context.handle(
        _seriexPowtorzeniaMeta,
        seriexPowtorzenia.isAcceptableOrUnknown(
          data['seriex_powtorzenia']!,
          _seriexPowtorzeniaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriexPowtorzeniaMeta);
    }
    if (data.containsKey('tempo')) {
      context.handle(
        _tempoMeta,
        tempo.isAcceptableOrUnknown(data['tempo']!, _tempoMeta),
      );
    } else if (isInserting) {
      context.missing(_tempoMeta);
    }
    if (data.containsKey('kluczowe_wskazowki')) {
      context.handle(
        _kluczoweWskazowkiMeta,
        kluczoweWskazowki.isAcceptableOrUnknown(
          data['kluczowe_wskazowki']!,
          _kluczoweWskazowkiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kluczoweWskazowkiMeta);
    }
    if (data.containsKey('czeste_bledy')) {
      context.handle(
        _czesteBledyMeta,
        czesteBledy.isAcceptableOrUnknown(
          data['czeste_bledy']!,
          _czesteBledyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_czesteBledyMeta);
    }
    if (data.containsKey('progresja')) {
      context.handle(
        _progresjaMeta,
        progresja.isAcceptableOrUnknown(data['progresja']!, _progresjaMeta),
      );
    } else if (isInserting) {
      context.missing(_progresjaMeta);
    }
    if (data.containsKey('regresja')) {
      context.handle(
        _regresjaMeta,
        regresja.isAcceptableOrUnknown(data['regresja']!, _regresjaMeta),
      );
    } else if (isInserting) {
      context.missing(_regresjaMeta);
    }
    if (data.containsKey('zrodlo')) {
      context.handle(
        _zrodloMeta,
        zrodlo.isAcceptableOrUnknown(data['zrodlo']!, _zrodloMeta),
      );
    } else if (isInserting) {
      context.missing(_zrodloMeta);
    }
    if (data.containsKey('ulubione')) {
      context.handle(
        _ulubioneMeta,
        ulubione.isAcceptableOrUnknown(data['ulubione']!, _ulubioneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nazwaPl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nazwa_pl'],
      )!,
      nazwaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nazwa_en'],
      )!,
      partiaGlowna: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partia_glowna'],
      )!,
      partieWspierajace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partie_wspierajace'],
      )!,
      sprzet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sprzet'],
      )!,
      typ: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}typ'],
      )!,
      poziom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poziom'],
      )!,
      wzorzecRuchu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wzorzec_ruchu'],
      )!,
      seriexPowtorzenia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seriex_powtorzenia'],
      )!,
      tempo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tempo'],
      )!,
      kluczoweWskazowki: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kluczowe_wskazowki'],
      )!,
      czesteBledy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}czeste_bledy'],
      )!,
      progresja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progresja'],
      )!,
      regresja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regresja'],
      )!,
      zrodlo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zrodlo'],
      )!,
      ulubione: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ulubione'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String nazwaPl;
  final String nazwaEn;
  final String partiaGlowna;
  final String partieWspierajace;
  final String sprzet;
  final String typ;
  final String poziom;
  final String wzorzecRuchu;
  final String seriexPowtorzenia;
  final String tempo;
  final String kluczoweWskazowki;
  final String czesteBledy;
  final String progresja;
  final String regresja;
  final String zrodlo;
  final bool ulubione;
  const Exercise({
    required this.id,
    required this.nazwaPl,
    required this.nazwaEn,
    required this.partiaGlowna,
    required this.partieWspierajace,
    required this.sprzet,
    required this.typ,
    required this.poziom,
    required this.wzorzecRuchu,
    required this.seriexPowtorzenia,
    required this.tempo,
    required this.kluczoweWskazowki,
    required this.czesteBledy,
    required this.progresja,
    required this.regresja,
    required this.zrodlo,
    required this.ulubione,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nazwa_pl'] = Variable<String>(nazwaPl);
    map['nazwa_en'] = Variable<String>(nazwaEn);
    map['partia_glowna'] = Variable<String>(partiaGlowna);
    map['partie_wspierajace'] = Variable<String>(partieWspierajace);
    map['sprzet'] = Variable<String>(sprzet);
    map['typ'] = Variable<String>(typ);
    map['poziom'] = Variable<String>(poziom);
    map['wzorzec_ruchu'] = Variable<String>(wzorzecRuchu);
    map['seriex_powtorzenia'] = Variable<String>(seriexPowtorzenia);
    map['tempo'] = Variable<String>(tempo);
    map['kluczowe_wskazowki'] = Variable<String>(kluczoweWskazowki);
    map['czeste_bledy'] = Variable<String>(czesteBledy);
    map['progresja'] = Variable<String>(progresja);
    map['regresja'] = Variable<String>(regresja);
    map['zrodlo'] = Variable<String>(zrodlo);
    map['ulubione'] = Variable<bool>(ulubione);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      nazwaPl: Value(nazwaPl),
      nazwaEn: Value(nazwaEn),
      partiaGlowna: Value(partiaGlowna),
      partieWspierajace: Value(partieWspierajace),
      sprzet: Value(sprzet),
      typ: Value(typ),
      poziom: Value(poziom),
      wzorzecRuchu: Value(wzorzecRuchu),
      seriexPowtorzenia: Value(seriexPowtorzenia),
      tempo: Value(tempo),
      kluczoweWskazowki: Value(kluczoweWskazowki),
      czesteBledy: Value(czesteBledy),
      progresja: Value(progresja),
      regresja: Value(regresja),
      zrodlo: Value(zrodlo),
      ulubione: Value(ulubione),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      nazwaPl: serializer.fromJson<String>(json['nazwaPl']),
      nazwaEn: serializer.fromJson<String>(json['nazwaEn']),
      partiaGlowna: serializer.fromJson<String>(json['partiaGlowna']),
      partieWspierajace: serializer.fromJson<String>(json['partieWspierajace']),
      sprzet: serializer.fromJson<String>(json['sprzet']),
      typ: serializer.fromJson<String>(json['typ']),
      poziom: serializer.fromJson<String>(json['poziom']),
      wzorzecRuchu: serializer.fromJson<String>(json['wzorzecRuchu']),
      seriexPowtorzenia: serializer.fromJson<String>(json['seriexPowtorzenia']),
      tempo: serializer.fromJson<String>(json['tempo']),
      kluczoweWskazowki: serializer.fromJson<String>(json['kluczoweWskazowki']),
      czesteBledy: serializer.fromJson<String>(json['czesteBledy']),
      progresja: serializer.fromJson<String>(json['progresja']),
      regresja: serializer.fromJson<String>(json['regresja']),
      zrodlo: serializer.fromJson<String>(json['zrodlo']),
      ulubione: serializer.fromJson<bool>(json['ulubione']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nazwaPl': serializer.toJson<String>(nazwaPl),
      'nazwaEn': serializer.toJson<String>(nazwaEn),
      'partiaGlowna': serializer.toJson<String>(partiaGlowna),
      'partieWspierajace': serializer.toJson<String>(partieWspierajace),
      'sprzet': serializer.toJson<String>(sprzet),
      'typ': serializer.toJson<String>(typ),
      'poziom': serializer.toJson<String>(poziom),
      'wzorzecRuchu': serializer.toJson<String>(wzorzecRuchu),
      'seriexPowtorzenia': serializer.toJson<String>(seriexPowtorzenia),
      'tempo': serializer.toJson<String>(tempo),
      'kluczoweWskazowki': serializer.toJson<String>(kluczoweWskazowki),
      'czesteBledy': serializer.toJson<String>(czesteBledy),
      'progresja': serializer.toJson<String>(progresja),
      'regresja': serializer.toJson<String>(regresja),
      'zrodlo': serializer.toJson<String>(zrodlo),
      'ulubione': serializer.toJson<bool>(ulubione),
    };
  }

  Exercise copyWith({
    String? id,
    String? nazwaPl,
    String? nazwaEn,
    String? partiaGlowna,
    String? partieWspierajace,
    String? sprzet,
    String? typ,
    String? poziom,
    String? wzorzecRuchu,
    String? seriexPowtorzenia,
    String? tempo,
    String? kluczoweWskazowki,
    String? czesteBledy,
    String? progresja,
    String? regresja,
    String? zrodlo,
    bool? ulubione,
  }) => Exercise(
    id: id ?? this.id,
    nazwaPl: nazwaPl ?? this.nazwaPl,
    nazwaEn: nazwaEn ?? this.nazwaEn,
    partiaGlowna: partiaGlowna ?? this.partiaGlowna,
    partieWspierajace: partieWspierajace ?? this.partieWspierajace,
    sprzet: sprzet ?? this.sprzet,
    typ: typ ?? this.typ,
    poziom: poziom ?? this.poziom,
    wzorzecRuchu: wzorzecRuchu ?? this.wzorzecRuchu,
    seriexPowtorzenia: seriexPowtorzenia ?? this.seriexPowtorzenia,
    tempo: tempo ?? this.tempo,
    kluczoweWskazowki: kluczoweWskazowki ?? this.kluczoweWskazowki,
    czesteBledy: czesteBledy ?? this.czesteBledy,
    progresja: progresja ?? this.progresja,
    regresja: regresja ?? this.regresja,
    zrodlo: zrodlo ?? this.zrodlo,
    ulubione: ulubione ?? this.ulubione,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      nazwaPl: data.nazwaPl.present ? data.nazwaPl.value : this.nazwaPl,
      nazwaEn: data.nazwaEn.present ? data.nazwaEn.value : this.nazwaEn,
      partiaGlowna: data.partiaGlowna.present
          ? data.partiaGlowna.value
          : this.partiaGlowna,
      partieWspierajace: data.partieWspierajace.present
          ? data.partieWspierajace.value
          : this.partieWspierajace,
      sprzet: data.sprzet.present ? data.sprzet.value : this.sprzet,
      typ: data.typ.present ? data.typ.value : this.typ,
      poziom: data.poziom.present ? data.poziom.value : this.poziom,
      wzorzecRuchu: data.wzorzecRuchu.present
          ? data.wzorzecRuchu.value
          : this.wzorzecRuchu,
      seriexPowtorzenia: data.seriexPowtorzenia.present
          ? data.seriexPowtorzenia.value
          : this.seriexPowtorzenia,
      tempo: data.tempo.present ? data.tempo.value : this.tempo,
      kluczoweWskazowki: data.kluczoweWskazowki.present
          ? data.kluczoweWskazowki.value
          : this.kluczoweWskazowki,
      czesteBledy: data.czesteBledy.present
          ? data.czesteBledy.value
          : this.czesteBledy,
      progresja: data.progresja.present ? data.progresja.value : this.progresja,
      regresja: data.regresja.present ? data.regresja.value : this.regresja,
      zrodlo: data.zrodlo.present ? data.zrodlo.value : this.zrodlo,
      ulubione: data.ulubione.present ? data.ulubione.value : this.ulubione,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('nazwaPl: $nazwaPl, ')
          ..write('nazwaEn: $nazwaEn, ')
          ..write('partiaGlowna: $partiaGlowna, ')
          ..write('partieWspierajace: $partieWspierajace, ')
          ..write('sprzet: $sprzet, ')
          ..write('typ: $typ, ')
          ..write('poziom: $poziom, ')
          ..write('wzorzecRuchu: $wzorzecRuchu, ')
          ..write('seriexPowtorzenia: $seriexPowtorzenia, ')
          ..write('tempo: $tempo, ')
          ..write('kluczoweWskazowki: $kluczoweWskazowki, ')
          ..write('czesteBledy: $czesteBledy, ')
          ..write('progresja: $progresja, ')
          ..write('regresja: $regresja, ')
          ..write('zrodlo: $zrodlo, ')
          ..write('ulubione: $ulubione')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nazwaPl,
    nazwaEn,
    partiaGlowna,
    partieWspierajace,
    sprzet,
    typ,
    poziom,
    wzorzecRuchu,
    seriexPowtorzenia,
    tempo,
    kluczoweWskazowki,
    czesteBledy,
    progresja,
    regresja,
    zrodlo,
    ulubione,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.nazwaPl == this.nazwaPl &&
          other.nazwaEn == this.nazwaEn &&
          other.partiaGlowna == this.partiaGlowna &&
          other.partieWspierajace == this.partieWspierajace &&
          other.sprzet == this.sprzet &&
          other.typ == this.typ &&
          other.poziom == this.poziom &&
          other.wzorzecRuchu == this.wzorzecRuchu &&
          other.seriexPowtorzenia == this.seriexPowtorzenia &&
          other.tempo == this.tempo &&
          other.kluczoweWskazowki == this.kluczoweWskazowki &&
          other.czesteBledy == this.czesteBledy &&
          other.progresja == this.progresja &&
          other.regresja == this.regresja &&
          other.zrodlo == this.zrodlo &&
          other.ulubione == this.ulubione);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> nazwaPl;
  final Value<String> nazwaEn;
  final Value<String> partiaGlowna;
  final Value<String> partieWspierajace;
  final Value<String> sprzet;
  final Value<String> typ;
  final Value<String> poziom;
  final Value<String> wzorzecRuchu;
  final Value<String> seriexPowtorzenia;
  final Value<String> tempo;
  final Value<String> kluczoweWskazowki;
  final Value<String> czesteBledy;
  final Value<String> progresja;
  final Value<String> regresja;
  final Value<String> zrodlo;
  final Value<bool> ulubione;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.nazwaPl = const Value.absent(),
    this.nazwaEn = const Value.absent(),
    this.partiaGlowna = const Value.absent(),
    this.partieWspierajace = const Value.absent(),
    this.sprzet = const Value.absent(),
    this.typ = const Value.absent(),
    this.poziom = const Value.absent(),
    this.wzorzecRuchu = const Value.absent(),
    this.seriexPowtorzenia = const Value.absent(),
    this.tempo = const Value.absent(),
    this.kluczoweWskazowki = const Value.absent(),
    this.czesteBledy = const Value.absent(),
    this.progresja = const Value.absent(),
    this.regresja = const Value.absent(),
    this.zrodlo = const Value.absent(),
    this.ulubione = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String nazwaPl,
    required String nazwaEn,
    required String partiaGlowna,
    required String partieWspierajace,
    required String sprzet,
    required String typ,
    required String poziom,
    required String wzorzecRuchu,
    required String seriexPowtorzenia,
    required String tempo,
    required String kluczoweWskazowki,
    required String czesteBledy,
    required String progresja,
    required String regresja,
    required String zrodlo,
    this.ulubione = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nazwaPl = Value(nazwaPl),
       nazwaEn = Value(nazwaEn),
       partiaGlowna = Value(partiaGlowna),
       partieWspierajace = Value(partieWspierajace),
       sprzet = Value(sprzet),
       typ = Value(typ),
       poziom = Value(poziom),
       wzorzecRuchu = Value(wzorzecRuchu),
       seriexPowtorzenia = Value(seriexPowtorzenia),
       tempo = Value(tempo),
       kluczoweWskazowki = Value(kluczoweWskazowki),
       czesteBledy = Value(czesteBledy),
       progresja = Value(progresja),
       regresja = Value(regresja),
       zrodlo = Value(zrodlo);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? nazwaPl,
    Expression<String>? nazwaEn,
    Expression<String>? partiaGlowna,
    Expression<String>? partieWspierajace,
    Expression<String>? sprzet,
    Expression<String>? typ,
    Expression<String>? poziom,
    Expression<String>? wzorzecRuchu,
    Expression<String>? seriexPowtorzenia,
    Expression<String>? tempo,
    Expression<String>? kluczoweWskazowki,
    Expression<String>? czesteBledy,
    Expression<String>? progresja,
    Expression<String>? regresja,
    Expression<String>? zrodlo,
    Expression<bool>? ulubione,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nazwaPl != null) 'nazwa_pl': nazwaPl,
      if (nazwaEn != null) 'nazwa_en': nazwaEn,
      if (partiaGlowna != null) 'partia_glowna': partiaGlowna,
      if (partieWspierajace != null) 'partie_wspierajace': partieWspierajace,
      if (sprzet != null) 'sprzet': sprzet,
      if (typ != null) 'typ': typ,
      if (poziom != null) 'poziom': poziom,
      if (wzorzecRuchu != null) 'wzorzec_ruchu': wzorzecRuchu,
      if (seriexPowtorzenia != null) 'seriex_powtorzenia': seriexPowtorzenia,
      if (tempo != null) 'tempo': tempo,
      if (kluczoweWskazowki != null) 'kluczowe_wskazowki': kluczoweWskazowki,
      if (czesteBledy != null) 'czeste_bledy': czesteBledy,
      if (progresja != null) 'progresja': progresja,
      if (regresja != null) 'regresja': regresja,
      if (zrodlo != null) 'zrodlo': zrodlo,
      if (ulubione != null) 'ulubione': ulubione,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? nazwaPl,
    Value<String>? nazwaEn,
    Value<String>? partiaGlowna,
    Value<String>? partieWspierajace,
    Value<String>? sprzet,
    Value<String>? typ,
    Value<String>? poziom,
    Value<String>? wzorzecRuchu,
    Value<String>? seriexPowtorzenia,
    Value<String>? tempo,
    Value<String>? kluczoweWskazowki,
    Value<String>? czesteBledy,
    Value<String>? progresja,
    Value<String>? regresja,
    Value<String>? zrodlo,
    Value<bool>? ulubione,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      nazwaPl: nazwaPl ?? this.nazwaPl,
      nazwaEn: nazwaEn ?? this.nazwaEn,
      partiaGlowna: partiaGlowna ?? this.partiaGlowna,
      partieWspierajace: partieWspierajace ?? this.partieWspierajace,
      sprzet: sprzet ?? this.sprzet,
      typ: typ ?? this.typ,
      poziom: poziom ?? this.poziom,
      wzorzecRuchu: wzorzecRuchu ?? this.wzorzecRuchu,
      seriexPowtorzenia: seriexPowtorzenia ?? this.seriexPowtorzenia,
      tempo: tempo ?? this.tempo,
      kluczoweWskazowki: kluczoweWskazowki ?? this.kluczoweWskazowki,
      czesteBledy: czesteBledy ?? this.czesteBledy,
      progresja: progresja ?? this.progresja,
      regresja: regresja ?? this.regresja,
      zrodlo: zrodlo ?? this.zrodlo,
      ulubione: ulubione ?? this.ulubione,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nazwaPl.present) {
      map['nazwa_pl'] = Variable<String>(nazwaPl.value);
    }
    if (nazwaEn.present) {
      map['nazwa_en'] = Variable<String>(nazwaEn.value);
    }
    if (partiaGlowna.present) {
      map['partia_glowna'] = Variable<String>(partiaGlowna.value);
    }
    if (partieWspierajace.present) {
      map['partie_wspierajace'] = Variable<String>(partieWspierajace.value);
    }
    if (sprzet.present) {
      map['sprzet'] = Variable<String>(sprzet.value);
    }
    if (typ.present) {
      map['typ'] = Variable<String>(typ.value);
    }
    if (poziom.present) {
      map['poziom'] = Variable<String>(poziom.value);
    }
    if (wzorzecRuchu.present) {
      map['wzorzec_ruchu'] = Variable<String>(wzorzecRuchu.value);
    }
    if (seriexPowtorzenia.present) {
      map['seriex_powtorzenia'] = Variable<String>(seriexPowtorzenia.value);
    }
    if (tempo.present) {
      map['tempo'] = Variable<String>(tempo.value);
    }
    if (kluczoweWskazowki.present) {
      map['kluczowe_wskazowki'] = Variable<String>(kluczoweWskazowki.value);
    }
    if (czesteBledy.present) {
      map['czeste_bledy'] = Variable<String>(czesteBledy.value);
    }
    if (progresja.present) {
      map['progresja'] = Variable<String>(progresja.value);
    }
    if (regresja.present) {
      map['regresja'] = Variable<String>(regresja.value);
    }
    if (zrodlo.present) {
      map['zrodlo'] = Variable<String>(zrodlo.value);
    }
    if (ulubione.present) {
      map['ulubione'] = Variable<bool>(ulubione.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('nazwaPl: $nazwaPl, ')
          ..write('nazwaEn: $nazwaEn, ')
          ..write('partiaGlowna: $partiaGlowna, ')
          ..write('partieWspierajace: $partieWspierajace, ')
          ..write('sprzet: $sprzet, ')
          ..write('typ: $typ, ')
          ..write('poziom: $poziom, ')
          ..write('wzorzecRuchu: $wzorzecRuchu, ')
          ..write('seriexPowtorzenia: $seriexPowtorzenia, ')
          ..write('tempo: $tempo, ')
          ..write('kluczoweWskazowki: $kluczoweWskazowki, ')
          ..write('czesteBledy: $czesteBledy, ')
          ..write('progresja: $progresja, ')
          ..write('regresja: $regresja, ')
          ..write('zrodlo: $zrodlo, ')
          ..write('ulubione: $ulubione, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dataStartMeta = const VerificationMeta(
    'dataStart',
  );
  @override
  late final GeneratedColumn<DateTime> dataStart = GeneratedColumn<DateTime>(
    'data_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataKoniecMeta = const VerificationMeta(
    'dataKoniec',
  );
  @override
  late final GeneratedColumn<DateTime> dataKoniec = GeneratedColumn<DateTime>(
    'data_koniec',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _czasTrwaniaSekundMeta = const VerificationMeta(
    'czasTrwaniaSekund',
  );
  @override
  late final GeneratedColumn<int> czasTrwaniaSekund = GeneratedColumn<int>(
    'czas_trwania_sekund',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notatkaMeta = const VerificationMeta(
    'notatka',
  );
  @override
  late final GeneratedColumn<String> notatka = GeneratedColumn<String>(
    'notatka',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dataStart,
    dataKoniec,
    czasTrwaniaSekund,
    notatka,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data_start')) {
      context.handle(
        _dataStartMeta,
        dataStart.isAcceptableOrUnknown(data['data_start']!, _dataStartMeta),
      );
    } else if (isInserting) {
      context.missing(_dataStartMeta);
    }
    if (data.containsKey('data_koniec')) {
      context.handle(
        _dataKoniecMeta,
        dataKoniec.isAcceptableOrUnknown(data['data_koniec']!, _dataKoniecMeta),
      );
    }
    if (data.containsKey('czas_trwania_sekund')) {
      context.handle(
        _czasTrwaniaSekundMeta,
        czasTrwaniaSekund.isAcceptableOrUnknown(
          data['czas_trwania_sekund']!,
          _czasTrwaniaSekundMeta,
        ),
      );
    }
    if (data.containsKey('notatka')) {
      context.handle(
        _notatkaMeta,
        notatka.isAcceptableOrUnknown(data['notatka']!, _notatkaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dataStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_start'],
      )!,
      dataKoniec: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_koniec'],
      ),
      czasTrwaniaSekund: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}czas_trwania_sekund'],
      )!,
      notatka: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notatka'],
      ),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final DateTime dataStart;
  final DateTime? dataKoniec;
  final int czasTrwaniaSekund;
  final String? notatka;
  const WorkoutSession({
    required this.id,
    required this.dataStart,
    this.dataKoniec,
    required this.czasTrwaniaSekund,
    this.notatka,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data_start'] = Variable<DateTime>(dataStart);
    if (!nullToAbsent || dataKoniec != null) {
      map['data_koniec'] = Variable<DateTime>(dataKoniec);
    }
    map['czas_trwania_sekund'] = Variable<int>(czasTrwaniaSekund);
    if (!nullToAbsent || notatka != null) {
      map['notatka'] = Variable<String>(notatka);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      dataStart: Value(dataStart),
      dataKoniec: dataKoniec == null && nullToAbsent
          ? const Value.absent()
          : Value(dataKoniec),
      czasTrwaniaSekund: Value(czasTrwaniaSekund),
      notatka: notatka == null && nullToAbsent
          ? const Value.absent()
          : Value(notatka),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      dataStart: serializer.fromJson<DateTime>(json['dataStart']),
      dataKoniec: serializer.fromJson<DateTime?>(json['dataKoniec']),
      czasTrwaniaSekund: serializer.fromJson<int>(json['czasTrwaniaSekund']),
      notatka: serializer.fromJson<String?>(json['notatka']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dataStart': serializer.toJson<DateTime>(dataStart),
      'dataKoniec': serializer.toJson<DateTime?>(dataKoniec),
      'czasTrwaniaSekund': serializer.toJson<int>(czasTrwaniaSekund),
      'notatka': serializer.toJson<String?>(notatka),
    };
  }

  WorkoutSession copyWith({
    int? id,
    DateTime? dataStart,
    Value<DateTime?> dataKoniec = const Value.absent(),
    int? czasTrwaniaSekund,
    Value<String?> notatka = const Value.absent(),
  }) => WorkoutSession(
    id: id ?? this.id,
    dataStart: dataStart ?? this.dataStart,
    dataKoniec: dataKoniec.present ? dataKoniec.value : this.dataKoniec,
    czasTrwaniaSekund: czasTrwaniaSekund ?? this.czasTrwaniaSekund,
    notatka: notatka.present ? notatka.value : this.notatka,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      dataStart: data.dataStart.present ? data.dataStart.value : this.dataStart,
      dataKoniec: data.dataKoniec.present
          ? data.dataKoniec.value
          : this.dataKoniec,
      czasTrwaniaSekund: data.czasTrwaniaSekund.present
          ? data.czasTrwaniaSekund.value
          : this.czasTrwaniaSekund,
      notatka: data.notatka.present ? data.notatka.value : this.notatka,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('dataStart: $dataStart, ')
          ..write('dataKoniec: $dataKoniec, ')
          ..write('czasTrwaniaSekund: $czasTrwaniaSekund, ')
          ..write('notatka: $notatka')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dataStart, dataKoniec, czasTrwaniaSekund, notatka);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.dataStart == this.dataStart &&
          other.dataKoniec == this.dataKoniec &&
          other.czasTrwaniaSekund == this.czasTrwaniaSekund &&
          other.notatka == this.notatka);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<DateTime> dataStart;
  final Value<DateTime?> dataKoniec;
  final Value<int> czasTrwaniaSekund;
  final Value<String?> notatka;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.dataStart = const Value.absent(),
    this.dataKoniec = const Value.absent(),
    this.czasTrwaniaSekund = const Value.absent(),
    this.notatka = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime dataStart,
    this.dataKoniec = const Value.absent(),
    this.czasTrwaniaSekund = const Value.absent(),
    this.notatka = const Value.absent(),
  }) : dataStart = Value(dataStart);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<DateTime>? dataStart,
    Expression<DateTime>? dataKoniec,
    Expression<int>? czasTrwaniaSekund,
    Expression<String>? notatka,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dataStart != null) 'data_start': dataStart,
      if (dataKoniec != null) 'data_koniec': dataKoniec,
      if (czasTrwaniaSekund != null) 'czas_trwania_sekund': czasTrwaniaSekund,
      if (notatka != null) 'notatka': notatka,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? dataStart,
    Value<DateTime?>? dataKoniec,
    Value<int>? czasTrwaniaSekund,
    Value<String?>? notatka,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      dataStart: dataStart ?? this.dataStart,
      dataKoniec: dataKoniec ?? this.dataKoniec,
      czasTrwaniaSekund: czasTrwaniaSekund ?? this.czasTrwaniaSekund,
      notatka: notatka ?? this.notatka,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dataStart.present) {
      map['data_start'] = Variable<DateTime>(dataStart.value);
    }
    if (dataKoniec.present) {
      map['data_koniec'] = Variable<DateTime>(dataKoniec.value);
    }
    if (czasTrwaniaSekund.present) {
      map['czas_trwania_sekund'] = Variable<int>(czasTrwaniaSekund.value);
    }
    if (notatka.present) {
      map['notatka'] = Variable<String>(notatka.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('dataStart: $dataStart, ')
          ..write('dataKoniec: $dataKoniec, ')
          ..write('czasTrwaniaSekund: $czasTrwaniaSekund, ')
          ..write('notatka: $notatka')
          ..write(')'))
        .toString();
  }
}

class $SetsLogTable extends SetsLog with TableInfo<$SetsLogTable, SetsLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetsLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sesjaIdMeta = const VerificationMeta(
    'sesjaId',
  );
  @override
  late final GeneratedColumn<int> sesjaId = GeneratedColumn<int>(
    'sesja_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cwiczenieIdMeta = const VerificationMeta(
    'cwiczenieId',
  );
  @override
  late final GeneratedColumn<String> cwiczenieId = GeneratedColumn<String>(
    'cwiczenie_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nazwaCwiczeniaPlMeta = const VerificationMeta(
    'nazwaCwiczeniaPl',
  );
  @override
  late final GeneratedColumn<String> nazwaCwiczeniaPl = GeneratedColumn<String>(
    'nazwa_cwiczenia_pl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numerSeriiMeta = const VerificationMeta(
    'numerSerii',
  );
  @override
  late final GeneratedColumn<int> numerSerii = GeneratedColumn<int>(
    'numer_serii',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciezarKgMeta = const VerificationMeta(
    'ciezarKg',
  );
  @override
  late final GeneratedColumn<double> ciezarKg = GeneratedColumn<double>(
    'ciezar_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powtorzeniaMeta = const VerificationMeta(
    'powtorzenia',
  );
  @override
  late final GeneratedColumn<int> powtorzenia = GeneratedColumn<int>(
    'powtorzenia',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _czasSekundMeta = const VerificationMeta(
    'czasSekund',
  );
  @override
  late final GeneratedColumn<int> czasSekund = GeneratedColumn<int>(
    'czas_sekund',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sesjaId,
    cwiczenieId,
    nazwaCwiczeniaPl,
    numerSerii,
    ciezarKg,
    powtorzenia,
    czasSekund,
    rpe,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sets_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetsLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sesja_id')) {
      context.handle(
        _sesjaIdMeta,
        sesjaId.isAcceptableOrUnknown(data['sesja_id']!, _sesjaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sesjaIdMeta);
    }
    if (data.containsKey('cwiczenie_id')) {
      context.handle(
        _cwiczenieIdMeta,
        cwiczenieId.isAcceptableOrUnknown(
          data['cwiczenie_id']!,
          _cwiczenieIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cwiczenieIdMeta);
    }
    if (data.containsKey('nazwa_cwiczenia_pl')) {
      context.handle(
        _nazwaCwiczeniaPlMeta,
        nazwaCwiczeniaPl.isAcceptableOrUnknown(
          data['nazwa_cwiczenia_pl']!,
          _nazwaCwiczeniaPlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nazwaCwiczeniaPlMeta);
    }
    if (data.containsKey('numer_serii')) {
      context.handle(
        _numerSeriiMeta,
        numerSerii.isAcceptableOrUnknown(data['numer_serii']!, _numerSeriiMeta),
      );
    } else if (isInserting) {
      context.missing(_numerSeriiMeta);
    }
    if (data.containsKey('ciezar_kg')) {
      context.handle(
        _ciezarKgMeta,
        ciezarKg.isAcceptableOrUnknown(data['ciezar_kg']!, _ciezarKgMeta),
      );
    }
    if (data.containsKey('powtorzenia')) {
      context.handle(
        _powtorzeniaMeta,
        powtorzenia.isAcceptableOrUnknown(
          data['powtorzenia']!,
          _powtorzeniaMeta,
        ),
      );
    }
    if (data.containsKey('czas_sekund')) {
      context.handle(
        _czasSekundMeta,
        czasSekund.isAcceptableOrUnknown(data['czas_sekund']!, _czasSekundMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetsLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetsLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sesjaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sesja_id'],
      )!,
      cwiczenieId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cwiczenie_id'],
      )!,
      nazwaCwiczeniaPl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nazwa_cwiczenia_pl'],
      )!,
      numerSerii: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numer_serii'],
      )!,
      ciezarKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ciezar_kg'],
      ),
      powtorzenia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}powtorzenia'],
      ),
      czasSekund: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}czas_sekund'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $SetsLogTable createAlias(String alias) {
    return $SetsLogTable(attachedDatabase, alias);
  }
}

class SetsLogData extends DataClass implements Insertable<SetsLogData> {
  final int id;
  final int sesjaId;
  final String cwiczenieId;
  final String nazwaCwiczeniaPl;
  final int numerSerii;
  final double? ciezarKg;
  final int? powtorzenia;
  final int? czasSekund;
  final int? rpe;
  final DateTime timestamp;
  const SetsLogData({
    required this.id,
    required this.sesjaId,
    required this.cwiczenieId,
    required this.nazwaCwiczeniaPl,
    required this.numerSerii,
    this.ciezarKg,
    this.powtorzenia,
    this.czasSekund,
    this.rpe,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sesja_id'] = Variable<int>(sesjaId);
    map['cwiczenie_id'] = Variable<String>(cwiczenieId);
    map['nazwa_cwiczenia_pl'] = Variable<String>(nazwaCwiczeniaPl);
    map['numer_serii'] = Variable<int>(numerSerii);
    if (!nullToAbsent || ciezarKg != null) {
      map['ciezar_kg'] = Variable<double>(ciezarKg);
    }
    if (!nullToAbsent || powtorzenia != null) {
      map['powtorzenia'] = Variable<int>(powtorzenia);
    }
    if (!nullToAbsent || czasSekund != null) {
      map['czas_sekund'] = Variable<int>(czasSekund);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<int>(rpe);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  SetsLogCompanion toCompanion(bool nullToAbsent) {
    return SetsLogCompanion(
      id: Value(id),
      sesjaId: Value(sesjaId),
      cwiczenieId: Value(cwiczenieId),
      nazwaCwiczeniaPl: Value(nazwaCwiczeniaPl),
      numerSerii: Value(numerSerii),
      ciezarKg: ciezarKg == null && nullToAbsent
          ? const Value.absent()
          : Value(ciezarKg),
      powtorzenia: powtorzenia == null && nullToAbsent
          ? const Value.absent()
          : Value(powtorzenia),
      czasSekund: czasSekund == null && nullToAbsent
          ? const Value.absent()
          : Value(czasSekund),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      timestamp: Value(timestamp),
    );
  }

  factory SetsLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetsLogData(
      id: serializer.fromJson<int>(json['id']),
      sesjaId: serializer.fromJson<int>(json['sesjaId']),
      cwiczenieId: serializer.fromJson<String>(json['cwiczenieId']),
      nazwaCwiczeniaPl: serializer.fromJson<String>(json['nazwaCwiczeniaPl']),
      numerSerii: serializer.fromJson<int>(json['numerSerii']),
      ciezarKg: serializer.fromJson<double?>(json['ciezarKg']),
      powtorzenia: serializer.fromJson<int?>(json['powtorzenia']),
      czasSekund: serializer.fromJson<int?>(json['czasSekund']),
      rpe: serializer.fromJson<int?>(json['rpe']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sesjaId': serializer.toJson<int>(sesjaId),
      'cwiczenieId': serializer.toJson<String>(cwiczenieId),
      'nazwaCwiczeniaPl': serializer.toJson<String>(nazwaCwiczeniaPl),
      'numerSerii': serializer.toJson<int>(numerSerii),
      'ciezarKg': serializer.toJson<double?>(ciezarKg),
      'powtorzenia': serializer.toJson<int?>(powtorzenia),
      'czasSekund': serializer.toJson<int?>(czasSekund),
      'rpe': serializer.toJson<int?>(rpe),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  SetsLogData copyWith({
    int? id,
    int? sesjaId,
    String? cwiczenieId,
    String? nazwaCwiczeniaPl,
    int? numerSerii,
    Value<double?> ciezarKg = const Value.absent(),
    Value<int?> powtorzenia = const Value.absent(),
    Value<int?> czasSekund = const Value.absent(),
    Value<int?> rpe = const Value.absent(),
    DateTime? timestamp,
  }) => SetsLogData(
    id: id ?? this.id,
    sesjaId: sesjaId ?? this.sesjaId,
    cwiczenieId: cwiczenieId ?? this.cwiczenieId,
    nazwaCwiczeniaPl: nazwaCwiczeniaPl ?? this.nazwaCwiczeniaPl,
    numerSerii: numerSerii ?? this.numerSerii,
    ciezarKg: ciezarKg.present ? ciezarKg.value : this.ciezarKg,
    powtorzenia: powtorzenia.present ? powtorzenia.value : this.powtorzenia,
    czasSekund: czasSekund.present ? czasSekund.value : this.czasSekund,
    rpe: rpe.present ? rpe.value : this.rpe,
    timestamp: timestamp ?? this.timestamp,
  );
  SetsLogData copyWithCompanion(SetsLogCompanion data) {
    return SetsLogData(
      id: data.id.present ? data.id.value : this.id,
      sesjaId: data.sesjaId.present ? data.sesjaId.value : this.sesjaId,
      cwiczenieId: data.cwiczenieId.present
          ? data.cwiczenieId.value
          : this.cwiczenieId,
      nazwaCwiczeniaPl: data.nazwaCwiczeniaPl.present
          ? data.nazwaCwiczeniaPl.value
          : this.nazwaCwiczeniaPl,
      numerSerii: data.numerSerii.present
          ? data.numerSerii.value
          : this.numerSerii,
      ciezarKg: data.ciezarKg.present ? data.ciezarKg.value : this.ciezarKg,
      powtorzenia: data.powtorzenia.present
          ? data.powtorzenia.value
          : this.powtorzenia,
      czasSekund: data.czasSekund.present
          ? data.czasSekund.value
          : this.czasSekund,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetsLogData(')
          ..write('id: $id, ')
          ..write('sesjaId: $sesjaId, ')
          ..write('cwiczenieId: $cwiczenieId, ')
          ..write('nazwaCwiczeniaPl: $nazwaCwiczeniaPl, ')
          ..write('numerSerii: $numerSerii, ')
          ..write('ciezarKg: $ciezarKg, ')
          ..write('powtorzenia: $powtorzenia, ')
          ..write('czasSekund: $czasSekund, ')
          ..write('rpe: $rpe, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sesjaId,
    cwiczenieId,
    nazwaCwiczeniaPl,
    numerSerii,
    ciezarKg,
    powtorzenia,
    czasSekund,
    rpe,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetsLogData &&
          other.id == this.id &&
          other.sesjaId == this.sesjaId &&
          other.cwiczenieId == this.cwiczenieId &&
          other.nazwaCwiczeniaPl == this.nazwaCwiczeniaPl &&
          other.numerSerii == this.numerSerii &&
          other.ciezarKg == this.ciezarKg &&
          other.powtorzenia == this.powtorzenia &&
          other.czasSekund == this.czasSekund &&
          other.rpe == this.rpe &&
          other.timestamp == this.timestamp);
}

class SetsLogCompanion extends UpdateCompanion<SetsLogData> {
  final Value<int> id;
  final Value<int> sesjaId;
  final Value<String> cwiczenieId;
  final Value<String> nazwaCwiczeniaPl;
  final Value<int> numerSerii;
  final Value<double?> ciezarKg;
  final Value<int?> powtorzenia;
  final Value<int?> czasSekund;
  final Value<int?> rpe;
  final Value<DateTime> timestamp;
  const SetsLogCompanion({
    this.id = const Value.absent(),
    this.sesjaId = const Value.absent(),
    this.cwiczenieId = const Value.absent(),
    this.nazwaCwiczeniaPl = const Value.absent(),
    this.numerSerii = const Value.absent(),
    this.ciezarKg = const Value.absent(),
    this.powtorzenia = const Value.absent(),
    this.czasSekund = const Value.absent(),
    this.rpe = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SetsLogCompanion.insert({
    this.id = const Value.absent(),
    required int sesjaId,
    required String cwiczenieId,
    required String nazwaCwiczeniaPl,
    required int numerSerii,
    this.ciezarKg = const Value.absent(),
    this.powtorzenia = const Value.absent(),
    this.czasSekund = const Value.absent(),
    this.rpe = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : sesjaId = Value(sesjaId),
       cwiczenieId = Value(cwiczenieId),
       nazwaCwiczeniaPl = Value(nazwaCwiczeniaPl),
       numerSerii = Value(numerSerii);
  static Insertable<SetsLogData> custom({
    Expression<int>? id,
    Expression<int>? sesjaId,
    Expression<String>? cwiczenieId,
    Expression<String>? nazwaCwiczeniaPl,
    Expression<int>? numerSerii,
    Expression<double>? ciezarKg,
    Expression<int>? powtorzenia,
    Expression<int>? czasSekund,
    Expression<int>? rpe,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sesjaId != null) 'sesja_id': sesjaId,
      if (cwiczenieId != null) 'cwiczenie_id': cwiczenieId,
      if (nazwaCwiczeniaPl != null) 'nazwa_cwiczenia_pl': nazwaCwiczeniaPl,
      if (numerSerii != null) 'numer_serii': numerSerii,
      if (ciezarKg != null) 'ciezar_kg': ciezarKg,
      if (powtorzenia != null) 'powtorzenia': powtorzenia,
      if (czasSekund != null) 'czas_sekund': czasSekund,
      if (rpe != null) 'rpe': rpe,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SetsLogCompanion copyWith({
    Value<int>? id,
    Value<int>? sesjaId,
    Value<String>? cwiczenieId,
    Value<String>? nazwaCwiczeniaPl,
    Value<int>? numerSerii,
    Value<double?>? ciezarKg,
    Value<int?>? powtorzenia,
    Value<int?>? czasSekund,
    Value<int?>? rpe,
    Value<DateTime>? timestamp,
  }) {
    return SetsLogCompanion(
      id: id ?? this.id,
      sesjaId: sesjaId ?? this.sesjaId,
      cwiczenieId: cwiczenieId ?? this.cwiczenieId,
      nazwaCwiczeniaPl: nazwaCwiczeniaPl ?? this.nazwaCwiczeniaPl,
      numerSerii: numerSerii ?? this.numerSerii,
      ciezarKg: ciezarKg ?? this.ciezarKg,
      powtorzenia: powtorzenia ?? this.powtorzenia,
      czasSekund: czasSekund ?? this.czasSekund,
      rpe: rpe ?? this.rpe,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sesjaId.present) {
      map['sesja_id'] = Variable<int>(sesjaId.value);
    }
    if (cwiczenieId.present) {
      map['cwiczenie_id'] = Variable<String>(cwiczenieId.value);
    }
    if (nazwaCwiczeniaPl.present) {
      map['nazwa_cwiczenia_pl'] = Variable<String>(nazwaCwiczeniaPl.value);
    }
    if (numerSerii.present) {
      map['numer_serii'] = Variable<int>(numerSerii.value);
    }
    if (ciezarKg.present) {
      map['ciezar_kg'] = Variable<double>(ciezarKg.value);
    }
    if (powtorzenia.present) {
      map['powtorzenia'] = Variable<int>(powtorzenia.value);
    }
    if (czasSekund.present) {
      map['czas_sekund'] = Variable<int>(czasSekund.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetsLogCompanion(')
          ..write('id: $id, ')
          ..write('sesjaId: $sesjaId, ')
          ..write('cwiczenieId: $cwiczenieId, ')
          ..write('nazwaCwiczeniaPl: $nazwaCwiczeniaPl, ')
          ..write('numerSerii: $numerSerii, ')
          ..write('ciezarKg: $ciezarKg, ')
          ..write('powtorzenia: $powtorzenia, ')
          ..write('czasSekund: $czasSekund, ')
          ..write('rpe: $rpe, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $MoodEntriesTable extends MoodEntries
    with TableInfo<$MoodEntriesTable, MoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _snGodzinyMeta = const VerificationMeta(
    'snGodziny',
  );
  @override
  late final GeneratedColumn<double> snGodziny = GeneratedColumn<double>(
    'sn_godziny',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energiaMeta = const VerificationMeta(
    'energia',
  );
  @override
  late final GeneratedColumn<int> energia = GeneratedColumn<int>(
    'energia',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nastrojMeta = const VerificationMeta(
    'nastroj',
  );
  @override
  late final GeneratedColumn<int> nastroj = GeneratedColumn<int>(
    'nastroj',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apetytMeta = const VerificationMeta('apetyt');
  @override
  late final GeneratedColumn<int> apetyt = GeneratedColumn<int>(
    'apetyt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alkoholMeta = const VerificationMeta(
    'alkohol',
  );
  @override
  late final GeneratedColumn<bool> alkohol = GeneratedColumn<bool>(
    'alkohol',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alkohol" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _alkoholJednostkiMeta = const VerificationMeta(
    'alkoholJednostki',
  );
  @override
  late final GeneratedColumn<int> alkoholJednostki = GeneratedColumn<int>(
    'alkohol_jednostki',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    data,
    snGodziny,
    energia,
    nastroj,
    apetyt,
    alkohol,
    alkoholJednostki,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('sn_godziny')) {
      context.handle(
        _snGodzinyMeta,
        snGodziny.isAcceptableOrUnknown(data['sn_godziny']!, _snGodzinyMeta),
      );
    } else if (isInserting) {
      context.missing(_snGodzinyMeta);
    }
    if (data.containsKey('energia')) {
      context.handle(
        _energiaMeta,
        energia.isAcceptableOrUnknown(data['energia']!, _energiaMeta),
      );
    } else if (isInserting) {
      context.missing(_energiaMeta);
    }
    if (data.containsKey('nastroj')) {
      context.handle(
        _nastrojMeta,
        nastroj.isAcceptableOrUnknown(data['nastroj']!, _nastrojMeta),
      );
    } else if (isInserting) {
      context.missing(_nastrojMeta);
    }
    if (data.containsKey('apetyt')) {
      context.handle(
        _apetytMeta,
        apetyt.isAcceptableOrUnknown(data['apetyt']!, _apetytMeta),
      );
    } else if (isInserting) {
      context.missing(_apetytMeta);
    }
    if (data.containsKey('alkohol')) {
      context.handle(
        _alkoholMeta,
        alkohol.isAcceptableOrUnknown(data['alkohol']!, _alkoholMeta),
      );
    }
    if (data.containsKey('alkohol_jednostki')) {
      context.handle(
        _alkoholJednostkiMeta,
        alkoholJednostki.isAcceptableOrUnknown(
          data['alkohol_jednostki']!,
          _alkoholJednostkiMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      snGodziny: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sn_godziny'],
      )!,
      energia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energia'],
      )!,
      nastroj: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nastroj'],
      )!,
      apetyt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}apetyt'],
      )!,
      alkohol: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alkohol'],
      )!,
      alkoholJednostki: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alkohol_jednostki'],
      )!,
    );
  }

  @override
  $MoodEntriesTable createAlias(String alias) {
    return $MoodEntriesTable(attachedDatabase, alias);
  }
}

class MoodEntry extends DataClass implements Insertable<MoodEntry> {
  final int id;
  final DateTime data;
  final double snGodziny;
  final int energia;
  final int nastroj;
  final int apetyt;
  final bool alkohol;
  final int alkoholJednostki;
  const MoodEntry({
    required this.id,
    required this.data,
    required this.snGodziny,
    required this.energia,
    required this.nastroj,
    required this.apetyt,
    required this.alkohol,
    required this.alkoholJednostki,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data'] = Variable<DateTime>(data);
    map['sn_godziny'] = Variable<double>(snGodziny);
    map['energia'] = Variable<int>(energia);
    map['nastroj'] = Variable<int>(nastroj);
    map['apetyt'] = Variable<int>(apetyt);
    map['alkohol'] = Variable<bool>(alkohol);
    map['alkohol_jednostki'] = Variable<int>(alkoholJednostki);
    return map;
  }

  MoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoodEntriesCompanion(
      id: Value(id),
      data: Value(data),
      snGodziny: Value(snGodziny),
      energia: Value(energia),
      nastroj: Value(nastroj),
      apetyt: Value(apetyt),
      alkohol: Value(alkohol),
      alkoholJednostki: Value(alkoholJednostki),
    );
  }

  factory MoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntry(
      id: serializer.fromJson<int>(json['id']),
      data: serializer.fromJson<DateTime>(json['data']),
      snGodziny: serializer.fromJson<double>(json['snGodziny']),
      energia: serializer.fromJson<int>(json['energia']),
      nastroj: serializer.fromJson<int>(json['nastroj']),
      apetyt: serializer.fromJson<int>(json['apetyt']),
      alkohol: serializer.fromJson<bool>(json['alkohol']),
      alkoholJednostki: serializer.fromJson<int>(json['alkoholJednostki']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'data': serializer.toJson<DateTime>(data),
      'snGodziny': serializer.toJson<double>(snGodziny),
      'energia': serializer.toJson<int>(energia),
      'nastroj': serializer.toJson<int>(nastroj),
      'apetyt': serializer.toJson<int>(apetyt),
      'alkohol': serializer.toJson<bool>(alkohol),
      'alkoholJednostki': serializer.toJson<int>(alkoholJednostki),
    };
  }

  MoodEntry copyWith({
    int? id,
    DateTime? data,
    double? snGodziny,
    int? energia,
    int? nastroj,
    int? apetyt,
    bool? alkohol,
    int? alkoholJednostki,
  }) => MoodEntry(
    id: id ?? this.id,
    data: data ?? this.data,
    snGodziny: snGodziny ?? this.snGodziny,
    energia: energia ?? this.energia,
    nastroj: nastroj ?? this.nastroj,
    apetyt: apetyt ?? this.apetyt,
    alkohol: alkohol ?? this.alkohol,
    alkoholJednostki: alkoholJednostki ?? this.alkoholJednostki,
  );
  MoodEntry copyWithCompanion(MoodEntriesCompanion data) {
    return MoodEntry(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      snGodziny: data.snGodziny.present ? data.snGodziny.value : this.snGodziny,
      energia: data.energia.present ? data.energia.value : this.energia,
      nastroj: data.nastroj.present ? data.nastroj.value : this.nastroj,
      apetyt: data.apetyt.present ? data.apetyt.value : this.apetyt,
      alkohol: data.alkohol.present ? data.alkohol.value : this.alkohol,
      alkoholJednostki: data.alkoholJednostki.present
          ? data.alkoholJednostki.value
          : this.alkoholJednostki,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntry(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('snGodziny: $snGodziny, ')
          ..write('energia: $energia, ')
          ..write('nastroj: $nastroj, ')
          ..write('apetyt: $apetyt, ')
          ..write('alkohol: $alkohol, ')
          ..write('alkoholJednostki: $alkoholJednostki')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    data,
    snGodziny,
    energia,
    nastroj,
    apetyt,
    alkohol,
    alkoholJednostki,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntry &&
          other.id == this.id &&
          other.data == this.data &&
          other.snGodziny == this.snGodziny &&
          other.energia == this.energia &&
          other.nastroj == this.nastroj &&
          other.apetyt == this.apetyt &&
          other.alkohol == this.alkohol &&
          other.alkoholJednostki == this.alkoholJednostki);
}

class MoodEntriesCompanion extends UpdateCompanion<MoodEntry> {
  final Value<int> id;
  final Value<DateTime> data;
  final Value<double> snGodziny;
  final Value<int> energia;
  final Value<int> nastroj;
  final Value<int> apetyt;
  final Value<bool> alkohol;
  final Value<int> alkoholJednostki;
  const MoodEntriesCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.snGodziny = const Value.absent(),
    this.energia = const Value.absent(),
    this.nastroj = const Value.absent(),
    this.apetyt = const Value.absent(),
    this.alkohol = const Value.absent(),
    this.alkoholJednostki = const Value.absent(),
  });
  MoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    required double snGodziny,
    required int energia,
    required int nastroj,
    required int apetyt,
    this.alkohol = const Value.absent(),
    this.alkoholJednostki = const Value.absent(),
  }) : snGodziny = Value(snGodziny),
       energia = Value(energia),
       nastroj = Value(nastroj),
       apetyt = Value(apetyt);
  static Insertable<MoodEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? data,
    Expression<double>? snGodziny,
    Expression<int>? energia,
    Expression<int>? nastroj,
    Expression<int>? apetyt,
    Expression<bool>? alkohol,
    Expression<int>? alkoholJednostki,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (snGodziny != null) 'sn_godziny': snGodziny,
      if (energia != null) 'energia': energia,
      if (nastroj != null) 'nastroj': nastroj,
      if (apetyt != null) 'apetyt': apetyt,
      if (alkohol != null) 'alkohol': alkohol,
      if (alkoholJednostki != null) 'alkohol_jednostki': alkoholJednostki,
    });
  }

  MoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? data,
    Value<double>? snGodziny,
    Value<int>? energia,
    Value<int>? nastroj,
    Value<int>? apetyt,
    Value<bool>? alkohol,
    Value<int>? alkoholJednostki,
  }) {
    return MoodEntriesCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      snGodziny: snGodziny ?? this.snGodziny,
      energia: energia ?? this.energia,
      nastroj: nastroj ?? this.nastroj,
      apetyt: apetyt ?? this.apetyt,
      alkohol: alkohol ?? this.alkohol,
      alkoholJednostki: alkoholJednostki ?? this.alkoholJednostki,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (snGodziny.present) {
      map['sn_godziny'] = Variable<double>(snGodziny.value);
    }
    if (energia.present) {
      map['energia'] = Variable<int>(energia.value);
    }
    if (nastroj.present) {
      map['nastroj'] = Variable<int>(nastroj.value);
    }
    if (apetyt.present) {
      map['apetyt'] = Variable<int>(apetyt.value);
    }
    if (alkohol.present) {
      map['alkohol'] = Variable<bool>(alkohol.value);
    }
    if (alkoholJednostki.present) {
      map['alkohol_jednostki'] = Variable<int>(alkoholJednostki.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('snGodziny: $snGodziny, ')
          ..write('energia: $energia, ')
          ..write('nastroj: $nastroj, ')
          ..write('apetyt: $apetyt, ')
          ..write('alkohol: $alkohol, ')
          ..write('alkoholJednostki: $alkoholJednostki')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _wagaKgMeta = const VerificationMeta('wagaKg');
  @override
  late final GeneratedColumn<double> wagaKg = GeneratedColumn<double>(
    'waga_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _obwodKlatkiMeta = const VerificationMeta(
    'obwodKlatki',
  );
  @override
  late final GeneratedColumn<double> obwodKlatki = GeneratedColumn<double>(
    'obwod_klatki',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodTaliiMeta = const VerificationMeta(
    'obwodTalii',
  );
  @override
  late final GeneratedColumn<double> obwodTalii = GeneratedColumn<double>(
    'obwod_talii',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodBioderMeta = const VerificationMeta(
    'obwodBioder',
  );
  @override
  late final GeneratedColumn<double> obwodBioder = GeneratedColumn<double>(
    'obwod_bioder',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodBicepsuPMeta = const VerificationMeta(
    'obwodBicepsuP',
  );
  @override
  late final GeneratedColumn<double> obwodBicepsuP = GeneratedColumn<double>(
    'obwod_bicepsu_p',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodBicepsuLMeta = const VerificationMeta(
    'obwodBicepsuL',
  );
  @override
  late final GeneratedColumn<double> obwodBicepsuL = GeneratedColumn<double>(
    'obwod_bicepsu_l',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodUdaPMeta = const VerificationMeta(
    'obwodUdaP',
  );
  @override
  late final GeneratedColumn<double> obwodUdaP = GeneratedColumn<double>(
    'obwod_uda_p',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodUdaLMeta = const VerificationMeta(
    'obwodUdaL',
  );
  @override
  late final GeneratedColumn<double> obwodUdaL = GeneratedColumn<double>(
    'obwod_uda_l',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodLydkiPMeta = const VerificationMeta(
    'obwodLydkiP',
  );
  @override
  late final GeneratedColumn<double> obwodLydkiP = GeneratedColumn<double>(
    'obwod_lydki_p',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obwodLydkiLMeta = const VerificationMeta(
    'obwodLydkiL',
  );
  @override
  late final GeneratedColumn<double> obwodLydkiL = GeneratedColumn<double>(
    'obwod_lydki_l',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _procentTluszczuMeta = const VerificationMeta(
    'procentTluszczu',
  );
  @override
  late final GeneratedColumn<double> procentTluszczu = GeneratedColumn<double>(
    'procent_tluszczu',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tetnoSpoczynkoweMeta = const VerificationMeta(
    'tetnoSpoczynkowe',
  );
  @override
  late final GeneratedColumn<int> tetnoSpoczynkowe = GeneratedColumn<int>(
    'tetno_spoczynkowe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cisnienieMeta = const VerificationMeta(
    'cisnienie',
  );
  @override
  late final GeneratedColumn<String> cisnienie = GeneratedColumn<String>(
    'cisnienie',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notatkaMeta = const VerificationMeta(
    'notatka',
  );
  @override
  late final GeneratedColumn<String> notatka = GeneratedColumn<String>(
    'notatka',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    data,
    wagaKg,
    obwodKlatki,
    obwodTalii,
    obwodBioder,
    obwodBicepsuP,
    obwodBicepsuL,
    obwodUdaP,
    obwodUdaL,
    obwodLydkiP,
    obwodLydkiL,
    procentTluszczu,
    tetnoSpoczynkowe,
    cisnienie,
    notatka,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Measurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('waga_kg')) {
      context.handle(
        _wagaKgMeta,
        wagaKg.isAcceptableOrUnknown(data['waga_kg']!, _wagaKgMeta),
      );
    } else if (isInserting) {
      context.missing(_wagaKgMeta);
    }
    if (data.containsKey('obwod_klatki')) {
      context.handle(
        _obwodKlatkiMeta,
        obwodKlatki.isAcceptableOrUnknown(
          data['obwod_klatki']!,
          _obwodKlatkiMeta,
        ),
      );
    }
    if (data.containsKey('obwod_talii')) {
      context.handle(
        _obwodTaliiMeta,
        obwodTalii.isAcceptableOrUnknown(data['obwod_talii']!, _obwodTaliiMeta),
      );
    }
    if (data.containsKey('obwod_bioder')) {
      context.handle(
        _obwodBioderMeta,
        obwodBioder.isAcceptableOrUnknown(
          data['obwod_bioder']!,
          _obwodBioderMeta,
        ),
      );
    }
    if (data.containsKey('obwod_bicepsu_p')) {
      context.handle(
        _obwodBicepsuPMeta,
        obwodBicepsuP.isAcceptableOrUnknown(
          data['obwod_bicepsu_p']!,
          _obwodBicepsuPMeta,
        ),
      );
    }
    if (data.containsKey('obwod_bicepsu_l')) {
      context.handle(
        _obwodBicepsuLMeta,
        obwodBicepsuL.isAcceptableOrUnknown(
          data['obwod_bicepsu_l']!,
          _obwodBicepsuLMeta,
        ),
      );
    }
    if (data.containsKey('obwod_uda_p')) {
      context.handle(
        _obwodUdaPMeta,
        obwodUdaP.isAcceptableOrUnknown(data['obwod_uda_p']!, _obwodUdaPMeta),
      );
    }
    if (data.containsKey('obwod_uda_l')) {
      context.handle(
        _obwodUdaLMeta,
        obwodUdaL.isAcceptableOrUnknown(data['obwod_uda_l']!, _obwodUdaLMeta),
      );
    }
    if (data.containsKey('obwod_lydki_p')) {
      context.handle(
        _obwodLydkiPMeta,
        obwodLydkiP.isAcceptableOrUnknown(
          data['obwod_lydki_p']!,
          _obwodLydkiPMeta,
        ),
      );
    }
    if (data.containsKey('obwod_lydki_l')) {
      context.handle(
        _obwodLydkiLMeta,
        obwodLydkiL.isAcceptableOrUnknown(
          data['obwod_lydki_l']!,
          _obwodLydkiLMeta,
        ),
      );
    }
    if (data.containsKey('procent_tluszczu')) {
      context.handle(
        _procentTluszczuMeta,
        procentTluszczu.isAcceptableOrUnknown(
          data['procent_tluszczu']!,
          _procentTluszczuMeta,
        ),
      );
    }
    if (data.containsKey('tetno_spoczynkowe')) {
      context.handle(
        _tetnoSpoczynkoweMeta,
        tetnoSpoczynkowe.isAcceptableOrUnknown(
          data['tetno_spoczynkowe']!,
          _tetnoSpoczynkoweMeta,
        ),
      );
    }
    if (data.containsKey('cisnienie')) {
      context.handle(
        _cisnienieMeta,
        cisnienie.isAcceptableOrUnknown(data['cisnienie']!, _cisnienieMeta),
      );
    }
    if (data.containsKey('notatka')) {
      context.handle(
        _notatkaMeta,
        notatka.isAcceptableOrUnknown(data['notatka']!, _notatkaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      wagaKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waga_kg'],
      )!,
      obwodKlatki: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_klatki'],
      ),
      obwodTalii: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_talii'],
      ),
      obwodBioder: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_bioder'],
      ),
      obwodBicepsuP: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_bicepsu_p'],
      ),
      obwodBicepsuL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_bicepsu_l'],
      ),
      obwodUdaP: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_uda_p'],
      ),
      obwodUdaL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_uda_l'],
      ),
      obwodLydkiP: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_lydki_p'],
      ),
      obwodLydkiL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obwod_lydki_l'],
      ),
      procentTluszczu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}procent_tluszczu'],
      ),
      tetnoSpoczynkowe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tetno_spoczynkowe'],
      ),
      cisnienie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cisnienie'],
      ),
      notatka: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notatka'],
      ),
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int id;
  final DateTime data;
  final double wagaKg;
  final double? obwodKlatki;
  final double? obwodTalii;
  final double? obwodBioder;
  final double? obwodBicepsuP;
  final double? obwodBicepsuL;
  final double? obwodUdaP;
  final double? obwodUdaL;
  final double? obwodLydkiP;
  final double? obwodLydkiL;
  final double? procentTluszczu;
  final int? tetnoSpoczynkowe;
  final String? cisnienie;
  final String? notatka;
  const Measurement({
    required this.id,
    required this.data,
    required this.wagaKg,
    this.obwodKlatki,
    this.obwodTalii,
    this.obwodBioder,
    this.obwodBicepsuP,
    this.obwodBicepsuL,
    this.obwodUdaP,
    this.obwodUdaL,
    this.obwodLydkiP,
    this.obwodLydkiL,
    this.procentTluszczu,
    this.tetnoSpoczynkowe,
    this.cisnienie,
    this.notatka,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data'] = Variable<DateTime>(data);
    map['waga_kg'] = Variable<double>(wagaKg);
    if (!nullToAbsent || obwodKlatki != null) {
      map['obwod_klatki'] = Variable<double>(obwodKlatki);
    }
    if (!nullToAbsent || obwodTalii != null) {
      map['obwod_talii'] = Variable<double>(obwodTalii);
    }
    if (!nullToAbsent || obwodBioder != null) {
      map['obwod_bioder'] = Variable<double>(obwodBioder);
    }
    if (!nullToAbsent || obwodBicepsuP != null) {
      map['obwod_bicepsu_p'] = Variable<double>(obwodBicepsuP);
    }
    if (!nullToAbsent || obwodBicepsuL != null) {
      map['obwod_bicepsu_l'] = Variable<double>(obwodBicepsuL);
    }
    if (!nullToAbsent || obwodUdaP != null) {
      map['obwod_uda_p'] = Variable<double>(obwodUdaP);
    }
    if (!nullToAbsent || obwodUdaL != null) {
      map['obwod_uda_l'] = Variable<double>(obwodUdaL);
    }
    if (!nullToAbsent || obwodLydkiP != null) {
      map['obwod_lydki_p'] = Variable<double>(obwodLydkiP);
    }
    if (!nullToAbsent || obwodLydkiL != null) {
      map['obwod_lydki_l'] = Variable<double>(obwodLydkiL);
    }
    if (!nullToAbsent || procentTluszczu != null) {
      map['procent_tluszczu'] = Variable<double>(procentTluszczu);
    }
    if (!nullToAbsent || tetnoSpoczynkowe != null) {
      map['tetno_spoczynkowe'] = Variable<int>(tetnoSpoczynkowe);
    }
    if (!nullToAbsent || cisnienie != null) {
      map['cisnienie'] = Variable<String>(cisnienie);
    }
    if (!nullToAbsent || notatka != null) {
      map['notatka'] = Variable<String>(notatka);
    }
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      data: Value(data),
      wagaKg: Value(wagaKg),
      obwodKlatki: obwodKlatki == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodKlatki),
      obwodTalii: obwodTalii == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodTalii),
      obwodBioder: obwodBioder == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodBioder),
      obwodBicepsuP: obwodBicepsuP == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodBicepsuP),
      obwodBicepsuL: obwodBicepsuL == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodBicepsuL),
      obwodUdaP: obwodUdaP == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodUdaP),
      obwodUdaL: obwodUdaL == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodUdaL),
      obwodLydkiP: obwodLydkiP == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodLydkiP),
      obwodLydkiL: obwodLydkiL == null && nullToAbsent
          ? const Value.absent()
          : Value(obwodLydkiL),
      procentTluszczu: procentTluszczu == null && nullToAbsent
          ? const Value.absent()
          : Value(procentTluszczu),
      tetnoSpoczynkowe: tetnoSpoczynkowe == null && nullToAbsent
          ? const Value.absent()
          : Value(tetnoSpoczynkowe),
      cisnienie: cisnienie == null && nullToAbsent
          ? const Value.absent()
          : Value(cisnienie),
      notatka: notatka == null && nullToAbsent
          ? const Value.absent()
          : Value(notatka),
    );
  }

  factory Measurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<int>(json['id']),
      data: serializer.fromJson<DateTime>(json['data']),
      wagaKg: serializer.fromJson<double>(json['wagaKg']),
      obwodKlatki: serializer.fromJson<double?>(json['obwodKlatki']),
      obwodTalii: serializer.fromJson<double?>(json['obwodTalii']),
      obwodBioder: serializer.fromJson<double?>(json['obwodBioder']),
      obwodBicepsuP: serializer.fromJson<double?>(json['obwodBicepsuP']),
      obwodBicepsuL: serializer.fromJson<double?>(json['obwodBicepsuL']),
      obwodUdaP: serializer.fromJson<double?>(json['obwodUdaP']),
      obwodUdaL: serializer.fromJson<double?>(json['obwodUdaL']),
      obwodLydkiP: serializer.fromJson<double?>(json['obwodLydkiP']),
      obwodLydkiL: serializer.fromJson<double?>(json['obwodLydkiL']),
      procentTluszczu: serializer.fromJson<double?>(json['procentTluszczu']),
      tetnoSpoczynkowe: serializer.fromJson<int?>(json['tetnoSpoczynkowe']),
      cisnienie: serializer.fromJson<String?>(json['cisnienie']),
      notatka: serializer.fromJson<String?>(json['notatka']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'data': serializer.toJson<DateTime>(data),
      'wagaKg': serializer.toJson<double>(wagaKg),
      'obwodKlatki': serializer.toJson<double?>(obwodKlatki),
      'obwodTalii': serializer.toJson<double?>(obwodTalii),
      'obwodBioder': serializer.toJson<double?>(obwodBioder),
      'obwodBicepsuP': serializer.toJson<double?>(obwodBicepsuP),
      'obwodBicepsuL': serializer.toJson<double?>(obwodBicepsuL),
      'obwodUdaP': serializer.toJson<double?>(obwodUdaP),
      'obwodUdaL': serializer.toJson<double?>(obwodUdaL),
      'obwodLydkiP': serializer.toJson<double?>(obwodLydkiP),
      'obwodLydkiL': serializer.toJson<double?>(obwodLydkiL),
      'procentTluszczu': serializer.toJson<double?>(procentTluszczu),
      'tetnoSpoczynkowe': serializer.toJson<int?>(tetnoSpoczynkowe),
      'cisnienie': serializer.toJson<String?>(cisnienie),
      'notatka': serializer.toJson<String?>(notatka),
    };
  }

  Measurement copyWith({
    int? id,
    DateTime? data,
    double? wagaKg,
    Value<double?> obwodKlatki = const Value.absent(),
    Value<double?> obwodTalii = const Value.absent(),
    Value<double?> obwodBioder = const Value.absent(),
    Value<double?> obwodBicepsuP = const Value.absent(),
    Value<double?> obwodBicepsuL = const Value.absent(),
    Value<double?> obwodUdaP = const Value.absent(),
    Value<double?> obwodUdaL = const Value.absent(),
    Value<double?> obwodLydkiP = const Value.absent(),
    Value<double?> obwodLydkiL = const Value.absent(),
    Value<double?> procentTluszczu = const Value.absent(),
    Value<int?> tetnoSpoczynkowe = const Value.absent(),
    Value<String?> cisnienie = const Value.absent(),
    Value<String?> notatka = const Value.absent(),
  }) => Measurement(
    id: id ?? this.id,
    data: data ?? this.data,
    wagaKg: wagaKg ?? this.wagaKg,
    obwodKlatki: obwodKlatki.present ? obwodKlatki.value : this.obwodKlatki,
    obwodTalii: obwodTalii.present ? obwodTalii.value : this.obwodTalii,
    obwodBioder: obwodBioder.present ? obwodBioder.value : this.obwodBioder,
    obwodBicepsuP: obwodBicepsuP.present
        ? obwodBicepsuP.value
        : this.obwodBicepsuP,
    obwodBicepsuL: obwodBicepsuL.present
        ? obwodBicepsuL.value
        : this.obwodBicepsuL,
    obwodUdaP: obwodUdaP.present ? obwodUdaP.value : this.obwodUdaP,
    obwodUdaL: obwodUdaL.present ? obwodUdaL.value : this.obwodUdaL,
    obwodLydkiP: obwodLydkiP.present ? obwodLydkiP.value : this.obwodLydkiP,
    obwodLydkiL: obwodLydkiL.present ? obwodLydkiL.value : this.obwodLydkiL,
    procentTluszczu: procentTluszczu.present
        ? procentTluszczu.value
        : this.procentTluszczu,
    tetnoSpoczynkowe: tetnoSpoczynkowe.present
        ? tetnoSpoczynkowe.value
        : this.tetnoSpoczynkowe,
    cisnienie: cisnienie.present ? cisnienie.value : this.cisnienie,
    notatka: notatka.present ? notatka.value : this.notatka,
  );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      wagaKg: data.wagaKg.present ? data.wagaKg.value : this.wagaKg,
      obwodKlatki: data.obwodKlatki.present
          ? data.obwodKlatki.value
          : this.obwodKlatki,
      obwodTalii: data.obwodTalii.present
          ? data.obwodTalii.value
          : this.obwodTalii,
      obwodBioder: data.obwodBioder.present
          ? data.obwodBioder.value
          : this.obwodBioder,
      obwodBicepsuP: data.obwodBicepsuP.present
          ? data.obwodBicepsuP.value
          : this.obwodBicepsuP,
      obwodBicepsuL: data.obwodBicepsuL.present
          ? data.obwodBicepsuL.value
          : this.obwodBicepsuL,
      obwodUdaP: data.obwodUdaP.present ? data.obwodUdaP.value : this.obwodUdaP,
      obwodUdaL: data.obwodUdaL.present ? data.obwodUdaL.value : this.obwodUdaL,
      obwodLydkiP: data.obwodLydkiP.present
          ? data.obwodLydkiP.value
          : this.obwodLydkiP,
      obwodLydkiL: data.obwodLydkiL.present
          ? data.obwodLydkiL.value
          : this.obwodLydkiL,
      procentTluszczu: data.procentTluszczu.present
          ? data.procentTluszczu.value
          : this.procentTluszczu,
      tetnoSpoczynkowe: data.tetnoSpoczynkowe.present
          ? data.tetnoSpoczynkowe.value
          : this.tetnoSpoczynkowe,
      cisnienie: data.cisnienie.present ? data.cisnienie.value : this.cisnienie,
      notatka: data.notatka.present ? data.notatka.value : this.notatka,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('wagaKg: $wagaKg, ')
          ..write('obwodKlatki: $obwodKlatki, ')
          ..write('obwodTalii: $obwodTalii, ')
          ..write('obwodBioder: $obwodBioder, ')
          ..write('obwodBicepsuP: $obwodBicepsuP, ')
          ..write('obwodBicepsuL: $obwodBicepsuL, ')
          ..write('obwodUdaP: $obwodUdaP, ')
          ..write('obwodUdaL: $obwodUdaL, ')
          ..write('obwodLydkiP: $obwodLydkiP, ')
          ..write('obwodLydkiL: $obwodLydkiL, ')
          ..write('procentTluszczu: $procentTluszczu, ')
          ..write('tetnoSpoczynkowe: $tetnoSpoczynkowe, ')
          ..write('cisnienie: $cisnienie, ')
          ..write('notatka: $notatka')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    data,
    wagaKg,
    obwodKlatki,
    obwodTalii,
    obwodBioder,
    obwodBicepsuP,
    obwodBicepsuL,
    obwodUdaP,
    obwodUdaL,
    obwodLydkiP,
    obwodLydkiL,
    procentTluszczu,
    tetnoSpoczynkowe,
    cisnienie,
    notatka,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.data == this.data &&
          other.wagaKg == this.wagaKg &&
          other.obwodKlatki == this.obwodKlatki &&
          other.obwodTalii == this.obwodTalii &&
          other.obwodBioder == this.obwodBioder &&
          other.obwodBicepsuP == this.obwodBicepsuP &&
          other.obwodBicepsuL == this.obwodBicepsuL &&
          other.obwodUdaP == this.obwodUdaP &&
          other.obwodUdaL == this.obwodUdaL &&
          other.obwodLydkiP == this.obwodLydkiP &&
          other.obwodLydkiL == this.obwodLydkiL &&
          other.procentTluszczu == this.procentTluszczu &&
          other.tetnoSpoczynkowe == this.tetnoSpoczynkowe &&
          other.cisnienie == this.cisnienie &&
          other.notatka == this.notatka);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> id;
  final Value<DateTime> data;
  final Value<double> wagaKg;
  final Value<double?> obwodKlatki;
  final Value<double?> obwodTalii;
  final Value<double?> obwodBioder;
  final Value<double?> obwodBicepsuP;
  final Value<double?> obwodBicepsuL;
  final Value<double?> obwodUdaP;
  final Value<double?> obwodUdaL;
  final Value<double?> obwodLydkiP;
  final Value<double?> obwodLydkiL;
  final Value<double?> procentTluszczu;
  final Value<int?> tetnoSpoczynkowe;
  final Value<String?> cisnienie;
  final Value<String?> notatka;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.wagaKg = const Value.absent(),
    this.obwodKlatki = const Value.absent(),
    this.obwodTalii = const Value.absent(),
    this.obwodBioder = const Value.absent(),
    this.obwodBicepsuP = const Value.absent(),
    this.obwodBicepsuL = const Value.absent(),
    this.obwodUdaP = const Value.absent(),
    this.obwodUdaL = const Value.absent(),
    this.obwodLydkiP = const Value.absent(),
    this.obwodLydkiL = const Value.absent(),
    this.procentTluszczu = const Value.absent(),
    this.tetnoSpoczynkowe = const Value.absent(),
    this.cisnienie = const Value.absent(),
    this.notatka = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    required double wagaKg,
    this.obwodKlatki = const Value.absent(),
    this.obwodTalii = const Value.absent(),
    this.obwodBioder = const Value.absent(),
    this.obwodBicepsuP = const Value.absent(),
    this.obwodBicepsuL = const Value.absent(),
    this.obwodUdaP = const Value.absent(),
    this.obwodUdaL = const Value.absent(),
    this.obwodLydkiP = const Value.absent(),
    this.obwodLydkiL = const Value.absent(),
    this.procentTluszczu = const Value.absent(),
    this.tetnoSpoczynkowe = const Value.absent(),
    this.cisnienie = const Value.absent(),
    this.notatka = const Value.absent(),
  }) : wagaKg = Value(wagaKg);
  static Insertable<Measurement> custom({
    Expression<int>? id,
    Expression<DateTime>? data,
    Expression<double>? wagaKg,
    Expression<double>? obwodKlatki,
    Expression<double>? obwodTalii,
    Expression<double>? obwodBioder,
    Expression<double>? obwodBicepsuP,
    Expression<double>? obwodBicepsuL,
    Expression<double>? obwodUdaP,
    Expression<double>? obwodUdaL,
    Expression<double>? obwodLydkiP,
    Expression<double>? obwodLydkiL,
    Expression<double>? procentTluszczu,
    Expression<int>? tetnoSpoczynkowe,
    Expression<String>? cisnienie,
    Expression<String>? notatka,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (wagaKg != null) 'waga_kg': wagaKg,
      if (obwodKlatki != null) 'obwod_klatki': obwodKlatki,
      if (obwodTalii != null) 'obwod_talii': obwodTalii,
      if (obwodBioder != null) 'obwod_bioder': obwodBioder,
      if (obwodBicepsuP != null) 'obwod_bicepsu_p': obwodBicepsuP,
      if (obwodBicepsuL != null) 'obwod_bicepsu_l': obwodBicepsuL,
      if (obwodUdaP != null) 'obwod_uda_p': obwodUdaP,
      if (obwodUdaL != null) 'obwod_uda_l': obwodUdaL,
      if (obwodLydkiP != null) 'obwod_lydki_p': obwodLydkiP,
      if (obwodLydkiL != null) 'obwod_lydki_l': obwodLydkiL,
      if (procentTluszczu != null) 'procent_tluszczu': procentTluszczu,
      if (tetnoSpoczynkowe != null) 'tetno_spoczynkowe': tetnoSpoczynkowe,
      if (cisnienie != null) 'cisnienie': cisnienie,
      if (notatka != null) 'notatka': notatka,
    });
  }

  MeasurementsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? data,
    Value<double>? wagaKg,
    Value<double?>? obwodKlatki,
    Value<double?>? obwodTalii,
    Value<double?>? obwodBioder,
    Value<double?>? obwodBicepsuP,
    Value<double?>? obwodBicepsuL,
    Value<double?>? obwodUdaP,
    Value<double?>? obwodUdaL,
    Value<double?>? obwodLydkiP,
    Value<double?>? obwodLydkiL,
    Value<double?>? procentTluszczu,
    Value<int?>? tetnoSpoczynkowe,
    Value<String?>? cisnienie,
    Value<String?>? notatka,
  }) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      wagaKg: wagaKg ?? this.wagaKg,
      obwodKlatki: obwodKlatki ?? this.obwodKlatki,
      obwodTalii: obwodTalii ?? this.obwodTalii,
      obwodBioder: obwodBioder ?? this.obwodBioder,
      obwodBicepsuP: obwodBicepsuP ?? this.obwodBicepsuP,
      obwodBicepsuL: obwodBicepsuL ?? this.obwodBicepsuL,
      obwodUdaP: obwodUdaP ?? this.obwodUdaP,
      obwodUdaL: obwodUdaL ?? this.obwodUdaL,
      obwodLydkiP: obwodLydkiP ?? this.obwodLydkiP,
      obwodLydkiL: obwodLydkiL ?? this.obwodLydkiL,
      procentTluszczu: procentTluszczu ?? this.procentTluszczu,
      tetnoSpoczynkowe: tetnoSpoczynkowe ?? this.tetnoSpoczynkowe,
      cisnienie: cisnienie ?? this.cisnienie,
      notatka: notatka ?? this.notatka,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (wagaKg.present) {
      map['waga_kg'] = Variable<double>(wagaKg.value);
    }
    if (obwodKlatki.present) {
      map['obwod_klatki'] = Variable<double>(obwodKlatki.value);
    }
    if (obwodTalii.present) {
      map['obwod_talii'] = Variable<double>(obwodTalii.value);
    }
    if (obwodBioder.present) {
      map['obwod_bioder'] = Variable<double>(obwodBioder.value);
    }
    if (obwodBicepsuP.present) {
      map['obwod_bicepsu_p'] = Variable<double>(obwodBicepsuP.value);
    }
    if (obwodBicepsuL.present) {
      map['obwod_bicepsu_l'] = Variable<double>(obwodBicepsuL.value);
    }
    if (obwodUdaP.present) {
      map['obwod_uda_p'] = Variable<double>(obwodUdaP.value);
    }
    if (obwodUdaL.present) {
      map['obwod_uda_l'] = Variable<double>(obwodUdaL.value);
    }
    if (obwodLydkiP.present) {
      map['obwod_lydki_p'] = Variable<double>(obwodLydkiP.value);
    }
    if (obwodLydkiL.present) {
      map['obwod_lydki_l'] = Variable<double>(obwodLydkiL.value);
    }
    if (procentTluszczu.present) {
      map['procent_tluszczu'] = Variable<double>(procentTluszczu.value);
    }
    if (tetnoSpoczynkowe.present) {
      map['tetno_spoczynkowe'] = Variable<int>(tetnoSpoczynkowe.value);
    }
    if (cisnienie.present) {
      map['cisnienie'] = Variable<String>(cisnienie.value);
    }
    if (notatka.present) {
      map['notatka'] = Variable<String>(notatka.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('wagaKg: $wagaKg, ')
          ..write('obwodKlatki: $obwodKlatki, ')
          ..write('obwodTalii: $obwodTalii, ')
          ..write('obwodBioder: $obwodBioder, ')
          ..write('obwodBicepsuP: $obwodBicepsuP, ')
          ..write('obwodBicepsuL: $obwodBicepsuL, ')
          ..write('obwodUdaP: $obwodUdaP, ')
          ..write('obwodUdaL: $obwodUdaL, ')
          ..write('obwodLydkiP: $obwodLydkiP, ')
          ..write('obwodLydkiL: $obwodLydkiL, ')
          ..write('procentTluszczu: $procentTluszczu, ')
          ..write('tetnoSpoczynkowe: $tetnoSpoczynkowe, ')
          ..write('cisnienie: $cisnienie, ')
          ..write('notatka: $notatka')
          ..write(')'))
        .toString();
  }
}

class $FitnessTestResultsTable extends FitnessTestResults
    with TableInfo<$FitnessTestResultsTable, FitnessTestResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FitnessTestResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typMeta = const VerificationMeta('typ');
  @override
  late final GeneratedColumn<String> typ = GeneratedColumn<String>(
    'typ',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _wynikMeta = const VerificationMeta('wynik');
  @override
  late final GeneratedColumn<double> wynik = GeneratedColumn<double>(
    'wynik',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, typ, data, wynik, score];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fitness_test_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<FitnessTestResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('typ')) {
      context.handle(
        _typMeta,
        typ.isAcceptableOrUnknown(data['typ']!, _typMeta),
      );
    } else if (isInserting) {
      context.missing(_typMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('wynik')) {
      context.handle(
        _wynikMeta,
        wynik.isAcceptableOrUnknown(data['wynik']!, _wynikMeta),
      );
    } else if (isInserting) {
      context.missing(_wynikMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FitnessTestResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FitnessTestResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      typ: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}typ'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      wynik: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wynik'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $FitnessTestResultsTable createAlias(String alias) {
    return $FitnessTestResultsTable(attachedDatabase, alias);
  }
}

class FitnessTestResult extends DataClass
    implements Insertable<FitnessTestResult> {
  final int id;
  final String typ;
  final DateTime data;
  final double wynik;
  final int score;
  const FitnessTestResult({
    required this.id,
    required this.typ,
    required this.data,
    required this.wynik,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['typ'] = Variable<String>(typ);
    map['data'] = Variable<DateTime>(data);
    map['wynik'] = Variable<double>(wynik);
    map['score'] = Variable<int>(score);
    return map;
  }

  FitnessTestResultsCompanion toCompanion(bool nullToAbsent) {
    return FitnessTestResultsCompanion(
      id: Value(id),
      typ: Value(typ),
      data: Value(data),
      wynik: Value(wynik),
      score: Value(score),
    );
  }

  factory FitnessTestResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FitnessTestResult(
      id: serializer.fromJson<int>(json['id']),
      typ: serializer.fromJson<String>(json['typ']),
      data: serializer.fromJson<DateTime>(json['data']),
      wynik: serializer.fromJson<double>(json['wynik']),
      score: serializer.fromJson<int>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'typ': serializer.toJson<String>(typ),
      'data': serializer.toJson<DateTime>(data),
      'wynik': serializer.toJson<double>(wynik),
      'score': serializer.toJson<int>(score),
    };
  }

  FitnessTestResult copyWith({
    int? id,
    String? typ,
    DateTime? data,
    double? wynik,
    int? score,
  }) => FitnessTestResult(
    id: id ?? this.id,
    typ: typ ?? this.typ,
    data: data ?? this.data,
    wynik: wynik ?? this.wynik,
    score: score ?? this.score,
  );
  FitnessTestResult copyWithCompanion(FitnessTestResultsCompanion data) {
    return FitnessTestResult(
      id: data.id.present ? data.id.value : this.id,
      typ: data.typ.present ? data.typ.value : this.typ,
      data: data.data.present ? data.data.value : this.data,
      wynik: data.wynik.present ? data.wynik.value : this.wynik,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FitnessTestResult(')
          ..write('id: $id, ')
          ..write('typ: $typ, ')
          ..write('data: $data, ')
          ..write('wynik: $wynik, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, typ, data, wynik, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FitnessTestResult &&
          other.id == this.id &&
          other.typ == this.typ &&
          other.data == this.data &&
          other.wynik == this.wynik &&
          other.score == this.score);
}

class FitnessTestResultsCompanion extends UpdateCompanion<FitnessTestResult> {
  final Value<int> id;
  final Value<String> typ;
  final Value<DateTime> data;
  final Value<double> wynik;
  final Value<int> score;
  const FitnessTestResultsCompanion({
    this.id = const Value.absent(),
    this.typ = const Value.absent(),
    this.data = const Value.absent(),
    this.wynik = const Value.absent(),
    this.score = const Value.absent(),
  });
  FitnessTestResultsCompanion.insert({
    this.id = const Value.absent(),
    required String typ,
    this.data = const Value.absent(),
    required double wynik,
    this.score = const Value.absent(),
  }) : typ = Value(typ),
       wynik = Value(wynik);
  static Insertable<FitnessTestResult> custom({
    Expression<int>? id,
    Expression<String>? typ,
    Expression<DateTime>? data,
    Expression<double>? wynik,
    Expression<int>? score,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (typ != null) 'typ': typ,
      if (data != null) 'data': data,
      if (wynik != null) 'wynik': wynik,
      if (score != null) 'score': score,
    });
  }

  FitnessTestResultsCompanion copyWith({
    Value<int>? id,
    Value<String>? typ,
    Value<DateTime>? data,
    Value<double>? wynik,
    Value<int>? score,
  }) {
    return FitnessTestResultsCompanion(
      id: id ?? this.id,
      typ: typ ?? this.typ,
      data: data ?? this.data,
      wynik: wynik ?? this.wynik,
      score: score ?? this.score,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (typ.present) {
      map['typ'] = Variable<String>(typ.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (wynik.present) {
      map['wynik'] = Variable<double>(wynik.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FitnessTestResultsCompanion(')
          ..write('id: $id, ')
          ..write('typ: $typ, ')
          ..write('data: $data, ')
          ..write('wynik: $wynik, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }
}

class $PersonalRecordsTable extends PersonalRecords
    with TableInfo<$PersonalRecordsTable, PersonalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cwiczenieIdMeta = const VerificationMeta(
    'cwiczenieId',
  );
  @override
  late final GeneratedColumn<String> cwiczenieId = GeneratedColumn<String>(
    'cwiczenie_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nazwaCwiczeniaPlMeta = const VerificationMeta(
    'nazwaCwiczeniaPl',
  );
  @override
  late final GeneratedColumn<String> nazwaCwiczeniaPl = GeneratedColumn<String>(
    'nazwa_cwiczenia_pl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciezarKgMeta = const VerificationMeta(
    'ciezarKg',
  );
  @override
  late final GeneratedColumn<double> ciezarKg = GeneratedColumn<double>(
    'ciezar_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _powtorzeniaMeta = const VerificationMeta(
    'powtorzenia',
  );
  @override
  late final GeneratedColumn<int> powtorzenia = GeneratedColumn<int>(
    'powtorzenia',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _szacowane1RmMeta = const VerificationMeta(
    'szacowane1Rm',
  );
  @override
  late final GeneratedColumn<double> szacowane1Rm = GeneratedColumn<double>(
    'szacowane1_rm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cwiczenieId,
    nazwaCwiczeniaPl,
    ciezarKg,
    powtorzenia,
    data,
    szacowane1Rm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cwiczenie_id')) {
      context.handle(
        _cwiczenieIdMeta,
        cwiczenieId.isAcceptableOrUnknown(
          data['cwiczenie_id']!,
          _cwiczenieIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cwiczenieIdMeta);
    }
    if (data.containsKey('nazwa_cwiczenia_pl')) {
      context.handle(
        _nazwaCwiczeniaPlMeta,
        nazwaCwiczeniaPl.isAcceptableOrUnknown(
          data['nazwa_cwiczenia_pl']!,
          _nazwaCwiczeniaPlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nazwaCwiczeniaPlMeta);
    }
    if (data.containsKey('ciezar_kg')) {
      context.handle(
        _ciezarKgMeta,
        ciezarKg.isAcceptableOrUnknown(data['ciezar_kg']!, _ciezarKgMeta),
      );
    } else if (isInserting) {
      context.missing(_ciezarKgMeta);
    }
    if (data.containsKey('powtorzenia')) {
      context.handle(
        _powtorzeniaMeta,
        powtorzenia.isAcceptableOrUnknown(
          data['powtorzenia']!,
          _powtorzeniaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_powtorzeniaMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('szacowane1_rm')) {
      context.handle(
        _szacowane1RmMeta,
        szacowane1Rm.isAcceptableOrUnknown(
          data['szacowane1_rm']!,
          _szacowane1RmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_szacowane1RmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cwiczenieId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cwiczenie_id'],
      )!,
      nazwaCwiczeniaPl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nazwa_cwiczenia_pl'],
      )!,
      ciezarKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ciezar_kg'],
      )!,
      powtorzenia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}powtorzenia'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      szacowane1Rm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}szacowane1_rm'],
      )!,
    );
  }

  @override
  $PersonalRecordsTable createAlias(String alias) {
    return $PersonalRecordsTable(attachedDatabase, alias);
  }
}

class PersonalRecord extends DataClass implements Insertable<PersonalRecord> {
  final int id;
  final String cwiczenieId;
  final String nazwaCwiczeniaPl;
  final double ciezarKg;
  final int powtorzenia;
  final DateTime data;
  final double szacowane1Rm;
  const PersonalRecord({
    required this.id,
    required this.cwiczenieId,
    required this.nazwaCwiczeniaPl,
    required this.ciezarKg,
    required this.powtorzenia,
    required this.data,
    required this.szacowane1Rm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cwiczenie_id'] = Variable<String>(cwiczenieId);
    map['nazwa_cwiczenia_pl'] = Variable<String>(nazwaCwiczeniaPl);
    map['ciezar_kg'] = Variable<double>(ciezarKg);
    map['powtorzenia'] = Variable<int>(powtorzenia);
    map['data'] = Variable<DateTime>(data);
    map['szacowane1_rm'] = Variable<double>(szacowane1Rm);
    return map;
  }

  PersonalRecordsCompanion toCompanion(bool nullToAbsent) {
    return PersonalRecordsCompanion(
      id: Value(id),
      cwiczenieId: Value(cwiczenieId),
      nazwaCwiczeniaPl: Value(nazwaCwiczeniaPl),
      ciezarKg: Value(ciezarKg),
      powtorzenia: Value(powtorzenia),
      data: Value(data),
      szacowane1Rm: Value(szacowane1Rm),
    );
  }

  factory PersonalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalRecord(
      id: serializer.fromJson<int>(json['id']),
      cwiczenieId: serializer.fromJson<String>(json['cwiczenieId']),
      nazwaCwiczeniaPl: serializer.fromJson<String>(json['nazwaCwiczeniaPl']),
      ciezarKg: serializer.fromJson<double>(json['ciezarKg']),
      powtorzenia: serializer.fromJson<int>(json['powtorzenia']),
      data: serializer.fromJson<DateTime>(json['data']),
      szacowane1Rm: serializer.fromJson<double>(json['szacowane1Rm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cwiczenieId': serializer.toJson<String>(cwiczenieId),
      'nazwaCwiczeniaPl': serializer.toJson<String>(nazwaCwiczeniaPl),
      'ciezarKg': serializer.toJson<double>(ciezarKg),
      'powtorzenia': serializer.toJson<int>(powtorzenia),
      'data': serializer.toJson<DateTime>(data),
      'szacowane1Rm': serializer.toJson<double>(szacowane1Rm),
    };
  }

  PersonalRecord copyWith({
    int? id,
    String? cwiczenieId,
    String? nazwaCwiczeniaPl,
    double? ciezarKg,
    int? powtorzenia,
    DateTime? data,
    double? szacowane1Rm,
  }) => PersonalRecord(
    id: id ?? this.id,
    cwiczenieId: cwiczenieId ?? this.cwiczenieId,
    nazwaCwiczeniaPl: nazwaCwiczeniaPl ?? this.nazwaCwiczeniaPl,
    ciezarKg: ciezarKg ?? this.ciezarKg,
    powtorzenia: powtorzenia ?? this.powtorzenia,
    data: data ?? this.data,
    szacowane1Rm: szacowane1Rm ?? this.szacowane1Rm,
  );
  PersonalRecord copyWithCompanion(PersonalRecordsCompanion data) {
    return PersonalRecord(
      id: data.id.present ? data.id.value : this.id,
      cwiczenieId: data.cwiczenieId.present
          ? data.cwiczenieId.value
          : this.cwiczenieId,
      nazwaCwiczeniaPl: data.nazwaCwiczeniaPl.present
          ? data.nazwaCwiczeniaPl.value
          : this.nazwaCwiczeniaPl,
      ciezarKg: data.ciezarKg.present ? data.ciezarKg.value : this.ciezarKg,
      powtorzenia: data.powtorzenia.present
          ? data.powtorzenia.value
          : this.powtorzenia,
      data: data.data.present ? data.data.value : this.data,
      szacowane1Rm: data.szacowane1Rm.present
          ? data.szacowane1Rm.value
          : this.szacowane1Rm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecord(')
          ..write('id: $id, ')
          ..write('cwiczenieId: $cwiczenieId, ')
          ..write('nazwaCwiczeniaPl: $nazwaCwiczeniaPl, ')
          ..write('ciezarKg: $ciezarKg, ')
          ..write('powtorzenia: $powtorzenia, ')
          ..write('data: $data, ')
          ..write('szacowane1Rm: $szacowane1Rm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cwiczenieId,
    nazwaCwiczeniaPl,
    ciezarKg,
    powtorzenia,
    data,
    szacowane1Rm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalRecord &&
          other.id == this.id &&
          other.cwiczenieId == this.cwiczenieId &&
          other.nazwaCwiczeniaPl == this.nazwaCwiczeniaPl &&
          other.ciezarKg == this.ciezarKg &&
          other.powtorzenia == this.powtorzenia &&
          other.data == this.data &&
          other.szacowane1Rm == this.szacowane1Rm);
}

class PersonalRecordsCompanion extends UpdateCompanion<PersonalRecord> {
  final Value<int> id;
  final Value<String> cwiczenieId;
  final Value<String> nazwaCwiczeniaPl;
  final Value<double> ciezarKg;
  final Value<int> powtorzenia;
  final Value<DateTime> data;
  final Value<double> szacowane1Rm;
  const PersonalRecordsCompanion({
    this.id = const Value.absent(),
    this.cwiczenieId = const Value.absent(),
    this.nazwaCwiczeniaPl = const Value.absent(),
    this.ciezarKg = const Value.absent(),
    this.powtorzenia = const Value.absent(),
    this.data = const Value.absent(),
    this.szacowane1Rm = const Value.absent(),
  });
  PersonalRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String cwiczenieId,
    required String nazwaCwiczeniaPl,
    required double ciezarKg,
    required int powtorzenia,
    this.data = const Value.absent(),
    required double szacowane1Rm,
  }) : cwiczenieId = Value(cwiczenieId),
       nazwaCwiczeniaPl = Value(nazwaCwiczeniaPl),
       ciezarKg = Value(ciezarKg),
       powtorzenia = Value(powtorzenia),
       szacowane1Rm = Value(szacowane1Rm);
  static Insertable<PersonalRecord> custom({
    Expression<int>? id,
    Expression<String>? cwiczenieId,
    Expression<String>? nazwaCwiczeniaPl,
    Expression<double>? ciezarKg,
    Expression<int>? powtorzenia,
    Expression<DateTime>? data,
    Expression<double>? szacowane1Rm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cwiczenieId != null) 'cwiczenie_id': cwiczenieId,
      if (nazwaCwiczeniaPl != null) 'nazwa_cwiczenia_pl': nazwaCwiczeniaPl,
      if (ciezarKg != null) 'ciezar_kg': ciezarKg,
      if (powtorzenia != null) 'powtorzenia': powtorzenia,
      if (data != null) 'data': data,
      if (szacowane1Rm != null) 'szacowane1_rm': szacowane1Rm,
    });
  }

  PersonalRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? cwiczenieId,
    Value<String>? nazwaCwiczeniaPl,
    Value<double>? ciezarKg,
    Value<int>? powtorzenia,
    Value<DateTime>? data,
    Value<double>? szacowane1Rm,
  }) {
    return PersonalRecordsCompanion(
      id: id ?? this.id,
      cwiczenieId: cwiczenieId ?? this.cwiczenieId,
      nazwaCwiczeniaPl: nazwaCwiczeniaPl ?? this.nazwaCwiczeniaPl,
      ciezarKg: ciezarKg ?? this.ciezarKg,
      powtorzenia: powtorzenia ?? this.powtorzenia,
      data: data ?? this.data,
      szacowane1Rm: szacowane1Rm ?? this.szacowane1Rm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cwiczenieId.present) {
      map['cwiczenie_id'] = Variable<String>(cwiczenieId.value);
    }
    if (nazwaCwiczeniaPl.present) {
      map['nazwa_cwiczenia_pl'] = Variable<String>(nazwaCwiczeniaPl.value);
    }
    if (ciezarKg.present) {
      map['ciezar_kg'] = Variable<double>(ciezarKg.value);
    }
    if (powtorzenia.present) {
      map['powtorzenia'] = Variable<int>(powtorzenia.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (szacowane1Rm.present) {
      map['szacowane1_rm'] = Variable<double>(szacowane1Rm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('cwiczenieId: $cwiczenieId, ')
          ..write('nazwaCwiczeniaPl: $nazwaCwiczeniaPl, ')
          ..write('ciezarKg: $ciezarKg, ')
          ..write('powtorzenia: $powtorzenia, ')
          ..write('data: $data, ')
          ..write('szacowane1Rm: $szacowane1Rm')
          ..write(')'))
        .toString();
  }
}

class $WorkoutPlansTable extends WorkoutPlans
    with TableInfo<$WorkoutPlansTable, WorkoutPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nazwaMeta = const VerificationMeta('nazwa');
  @override
  late final GeneratedColumn<String> nazwa = GeneratedColumn<String>(
    'nazwa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cwiczeniaIdsMeta = const VerificationMeta(
    'cwiczeniaIds',
  );
  @override
  late final GeneratedColumn<String> cwiczeniaIds = GeneratedColumn<String>(
    'cwiczenia_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _celMeta = const VerificationMeta('cel');
  @override
  late final GeneratedColumn<String> cel = GeneratedColumn<String>(
    'cel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataUtworzeniaMeta = const VerificationMeta(
    'dataUtworzenia',
  );
  @override
  late final GeneratedColumn<DateTime> dataUtworzenia =
      GeneratedColumn<DateTime>(
        'data_utworzenia',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nazwa,
    cwiczeniaIds,
    cel,
    dataUtworzenia,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nazwa')) {
      context.handle(
        _nazwaMeta,
        nazwa.isAcceptableOrUnknown(data['nazwa']!, _nazwaMeta),
      );
    } else if (isInserting) {
      context.missing(_nazwaMeta);
    }
    if (data.containsKey('cwiczenia_ids')) {
      context.handle(
        _cwiczeniaIdsMeta,
        cwiczeniaIds.isAcceptableOrUnknown(
          data['cwiczenia_ids']!,
          _cwiczeniaIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cwiczeniaIdsMeta);
    }
    if (data.containsKey('cel')) {
      context.handle(
        _celMeta,
        cel.isAcceptableOrUnknown(data['cel']!, _celMeta),
      );
    } else if (isInserting) {
      context.missing(_celMeta);
    }
    if (data.containsKey('data_utworzenia')) {
      context.handle(
        _dataUtworzeniaMeta,
        dataUtworzenia.isAcceptableOrUnknown(
          data['data_utworzenia']!,
          _dataUtworzeniaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nazwa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nazwa'],
      )!,
      cwiczeniaIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cwiczenia_ids'],
      )!,
      cel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cel'],
      )!,
      dataUtworzenia: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_utworzenia'],
      )!,
    );
  }

  @override
  $WorkoutPlansTable createAlias(String alias) {
    return $WorkoutPlansTable(attachedDatabase, alias);
  }
}

class WorkoutPlan extends DataClass implements Insertable<WorkoutPlan> {
  final int id;
  final String nazwa;
  final String cwiczeniaIds;
  final String cel;
  final DateTime dataUtworzenia;
  const WorkoutPlan({
    required this.id,
    required this.nazwa,
    required this.cwiczeniaIds,
    required this.cel,
    required this.dataUtworzenia,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nazwa'] = Variable<String>(nazwa);
    map['cwiczenia_ids'] = Variable<String>(cwiczeniaIds);
    map['cel'] = Variable<String>(cel);
    map['data_utworzenia'] = Variable<DateTime>(dataUtworzenia);
    return map;
  }

  WorkoutPlansCompanion toCompanion(bool nullToAbsent) {
    return WorkoutPlansCompanion(
      id: Value(id),
      nazwa: Value(nazwa),
      cwiczeniaIds: Value(cwiczeniaIds),
      cel: Value(cel),
      dataUtworzenia: Value(dataUtworzenia),
    );
  }

  factory WorkoutPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutPlan(
      id: serializer.fromJson<int>(json['id']),
      nazwa: serializer.fromJson<String>(json['nazwa']),
      cwiczeniaIds: serializer.fromJson<String>(json['cwiczeniaIds']),
      cel: serializer.fromJson<String>(json['cel']),
      dataUtworzenia: serializer.fromJson<DateTime>(json['dataUtworzenia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nazwa': serializer.toJson<String>(nazwa),
      'cwiczeniaIds': serializer.toJson<String>(cwiczeniaIds),
      'cel': serializer.toJson<String>(cel),
      'dataUtworzenia': serializer.toJson<DateTime>(dataUtworzenia),
    };
  }

  WorkoutPlan copyWith({
    int? id,
    String? nazwa,
    String? cwiczeniaIds,
    String? cel,
    DateTime? dataUtworzenia,
  }) => WorkoutPlan(
    id: id ?? this.id,
    nazwa: nazwa ?? this.nazwa,
    cwiczeniaIds: cwiczeniaIds ?? this.cwiczeniaIds,
    cel: cel ?? this.cel,
    dataUtworzenia: dataUtworzenia ?? this.dataUtworzenia,
  );
  WorkoutPlan copyWithCompanion(WorkoutPlansCompanion data) {
    return WorkoutPlan(
      id: data.id.present ? data.id.value : this.id,
      nazwa: data.nazwa.present ? data.nazwa.value : this.nazwa,
      cwiczeniaIds: data.cwiczeniaIds.present
          ? data.cwiczeniaIds.value
          : this.cwiczeniaIds,
      cel: data.cel.present ? data.cel.value : this.cel,
      dataUtworzenia: data.dataUtworzenia.present
          ? data.dataUtworzenia.value
          : this.dataUtworzenia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlan(')
          ..write('id: $id, ')
          ..write('nazwa: $nazwa, ')
          ..write('cwiczeniaIds: $cwiczeniaIds, ')
          ..write('cel: $cel, ')
          ..write('dataUtworzenia: $dataUtworzenia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nazwa, cwiczeniaIds, cel, dataUtworzenia);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutPlan &&
          other.id == this.id &&
          other.nazwa == this.nazwa &&
          other.cwiczeniaIds == this.cwiczeniaIds &&
          other.cel == this.cel &&
          other.dataUtworzenia == this.dataUtworzenia);
}

class WorkoutPlansCompanion extends UpdateCompanion<WorkoutPlan> {
  final Value<int> id;
  final Value<String> nazwa;
  final Value<String> cwiczeniaIds;
  final Value<String> cel;
  final Value<DateTime> dataUtworzenia;
  const WorkoutPlansCompanion({
    this.id = const Value.absent(),
    this.nazwa = const Value.absent(),
    this.cwiczeniaIds = const Value.absent(),
    this.cel = const Value.absent(),
    this.dataUtworzenia = const Value.absent(),
  });
  WorkoutPlansCompanion.insert({
    this.id = const Value.absent(),
    required String nazwa,
    required String cwiczeniaIds,
    required String cel,
    this.dataUtworzenia = const Value.absent(),
  }) : nazwa = Value(nazwa),
       cwiczeniaIds = Value(cwiczeniaIds),
       cel = Value(cel);
  static Insertable<WorkoutPlan> custom({
    Expression<int>? id,
    Expression<String>? nazwa,
    Expression<String>? cwiczeniaIds,
    Expression<String>? cel,
    Expression<DateTime>? dataUtworzenia,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nazwa != null) 'nazwa': nazwa,
      if (cwiczeniaIds != null) 'cwiczenia_ids': cwiczeniaIds,
      if (cel != null) 'cel': cel,
      if (dataUtworzenia != null) 'data_utworzenia': dataUtworzenia,
    });
  }

  WorkoutPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? nazwa,
    Value<String>? cwiczeniaIds,
    Value<String>? cel,
    Value<DateTime>? dataUtworzenia,
  }) {
    return WorkoutPlansCompanion(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      cwiczeniaIds: cwiczeniaIds ?? this.cwiczeniaIds,
      cel: cel ?? this.cel,
      dataUtworzenia: dataUtworzenia ?? this.dataUtworzenia,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nazwa.present) {
      map['nazwa'] = Variable<String>(nazwa.value);
    }
    if (cwiczeniaIds.present) {
      map['cwiczenia_ids'] = Variable<String>(cwiczeniaIds.value);
    }
    if (cel.present) {
      map['cel'] = Variable<String>(cel.value);
    }
    if (dataUtworzenia.present) {
      map['data_utworzenia'] = Variable<DateTime>(dataUtworzenia.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlansCompanion(')
          ..write('id: $id, ')
          ..write('nazwa: $nazwa, ')
          ..write('cwiczeniaIds: $cwiczeniaIds, ')
          ..write('cel: $cel, ')
          ..write('dataUtworzenia: $dataUtworzenia')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $SetsLogTable setsLog = $SetsLogTable(this);
  late final $MoodEntriesTable moodEntries = $MoodEntriesTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $FitnessTestResultsTable fitnessTestResults =
      $FitnessTestResultsTable(this);
  late final $PersonalRecordsTable personalRecords = $PersonalRecordsTable(
    this,
  );
  late final $WorkoutPlansTable workoutPlans = $WorkoutPlansTable(this);
  late final UserProfileDao userProfileDao = UserProfileDao(
    this as AppDatabase,
  );
  late final ExercisesDao exercisesDao = ExercisesDao(this as AppDatabase);
  late final WorkoutDao workoutDao = WorkoutDao(this as AppDatabase);
  late final MoodDao moodDao = MoodDao(this as AppDatabase);
  late final MeasurementsDao measurementsDao = MeasurementsDao(
    this as AppDatabase,
  );
  late final TestsDao testsDao = TestsDao(this as AppDatabase);
  late final PrsDao prsDao = PrsDao(this as AppDatabase);
  late final PlansDao plansDao = PlansDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfiles,
    exercises,
    workoutSessions,
    setsLog,
    moodEntries,
    measurements,
    fitnessTestResults,
    personalRecords,
    workoutPlans,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sets_log', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String> imie,
      required int wiek,
      required double wzrostCm,
      required double wagaKg,
      required String cel,
      required String dostepnySprzet,
      Value<bool> onboardingZakonczony,
      Value<DateTime> dataUtworzenia,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String> imie,
      Value<int> wiek,
      Value<double> wzrostCm,
      Value<double> wagaKg,
      Value<String> cel,
      Value<String> dostepnySprzet,
      Value<bool> onboardingZakonczony,
      Value<DateTime> dataUtworzenia,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imie => $composableBuilder(
    column: $table.imie,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wiek => $composableBuilder(
    column: $table.wiek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wzrostCm => $composableBuilder(
    column: $table.wzrostCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wagaKg => $composableBuilder(
    column: $table.wagaKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cel => $composableBuilder(
    column: $table.cel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dostepnySprzet => $composableBuilder(
    column: $table.dostepnySprzet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingZakonczony => $composableBuilder(
    column: $table.onboardingZakonczony,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataUtworzenia => $composableBuilder(
    column: $table.dataUtworzenia,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imie => $composableBuilder(
    column: $table.imie,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wiek => $composableBuilder(
    column: $table.wiek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wzrostCm => $composableBuilder(
    column: $table.wzrostCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wagaKg => $composableBuilder(
    column: $table.wagaKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cel => $composableBuilder(
    column: $table.cel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dostepnySprzet => $composableBuilder(
    column: $table.dostepnySprzet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingZakonczony => $composableBuilder(
    column: $table.onboardingZakonczony,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataUtworzenia => $composableBuilder(
    column: $table.dataUtworzenia,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imie =>
      $composableBuilder(column: $table.imie, builder: (column) => column);

  GeneratedColumn<int> get wiek =>
      $composableBuilder(column: $table.wiek, builder: (column) => column);

  GeneratedColumn<double> get wzrostCm =>
      $composableBuilder(column: $table.wzrostCm, builder: (column) => column);

  GeneratedColumn<double> get wagaKg =>
      $composableBuilder(column: $table.wagaKg, builder: (column) => column);

  GeneratedColumn<String> get cel =>
      $composableBuilder(column: $table.cel, builder: (column) => column);

  GeneratedColumn<String> get dostepnySprzet => $composableBuilder(
    column: $table.dostepnySprzet,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingZakonczony => $composableBuilder(
    column: $table.onboardingZakonczony,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataUtworzenia => $composableBuilder(
    column: $table.dataUtworzenia,
    builder: (column) => column,
  );
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> imie = const Value.absent(),
                Value<int> wiek = const Value.absent(),
                Value<double> wzrostCm = const Value.absent(),
                Value<double> wagaKg = const Value.absent(),
                Value<String> cel = const Value.absent(),
                Value<String> dostepnySprzet = const Value.absent(),
                Value<bool> onboardingZakonczony = const Value.absent(),
                Value<DateTime> dataUtworzenia = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                imie: imie,
                wiek: wiek,
                wzrostCm: wzrostCm,
                wagaKg: wagaKg,
                cel: cel,
                dostepnySprzet: dostepnySprzet,
                onboardingZakonczony: onboardingZakonczony,
                dataUtworzenia: dataUtworzenia,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> imie = const Value.absent(),
                required int wiek,
                required double wzrostCm,
                required double wagaKg,
                required String cel,
                required String dostepnySprzet,
                Value<bool> onboardingZakonczony = const Value.absent(),
                Value<DateTime> dataUtworzenia = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                imie: imie,
                wiek: wiek,
                wzrostCm: wzrostCm,
                wagaKg: wagaKg,
                cel: cel,
                dostepnySprzet: dostepnySprzet,
                onboardingZakonczony: onboardingZakonczony,
                dataUtworzenia: dataUtworzenia,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      required String id,
      required String nazwaPl,
      required String nazwaEn,
      required String partiaGlowna,
      required String partieWspierajace,
      required String sprzet,
      required String typ,
      required String poziom,
      required String wzorzecRuchu,
      required String seriexPowtorzenia,
      required String tempo,
      required String kluczoweWskazowki,
      required String czesteBledy,
      required String progresja,
      required String regresja,
      required String zrodlo,
      Value<bool> ulubione,
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> nazwaPl,
      Value<String> nazwaEn,
      Value<String> partiaGlowna,
      Value<String> partieWspierajace,
      Value<String> sprzet,
      Value<String> typ,
      Value<String> poziom,
      Value<String> wzorzecRuchu,
      Value<String> seriexPowtorzenia,
      Value<String> tempo,
      Value<String> kluczoweWskazowki,
      Value<String> czesteBledy,
      Value<String> progresja,
      Value<String> regresja,
      Value<String> zrodlo,
      Value<bool> ulubione,
      Value<int> rowid,
    });

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nazwaPl => $composableBuilder(
    column: $table.nazwaPl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nazwaEn => $composableBuilder(
    column: $table.nazwaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partiaGlowna => $composableBuilder(
    column: $table.partiaGlowna,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partieWspierajace => $composableBuilder(
    column: $table.partieWspierajace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sprzet => $composableBuilder(
    column: $table.sprzet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typ => $composableBuilder(
    column: $table.typ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poziom => $composableBuilder(
    column: $table.poziom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wzorzecRuchu => $composableBuilder(
    column: $table.wzorzecRuchu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriexPowtorzenia => $composableBuilder(
    column: $table.seriexPowtorzenia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kluczoweWskazowki => $composableBuilder(
    column: $table.kluczoweWskazowki,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get czesteBledy => $composableBuilder(
    column: $table.czesteBledy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progresja => $composableBuilder(
    column: $table.progresja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regresja => $composableBuilder(
    column: $table.regresja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zrodlo => $composableBuilder(
    column: $table.zrodlo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ulubione => $composableBuilder(
    column: $table.ulubione,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nazwaPl => $composableBuilder(
    column: $table.nazwaPl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nazwaEn => $composableBuilder(
    column: $table.nazwaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partiaGlowna => $composableBuilder(
    column: $table.partiaGlowna,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partieWspierajace => $composableBuilder(
    column: $table.partieWspierajace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sprzet => $composableBuilder(
    column: $table.sprzet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typ => $composableBuilder(
    column: $table.typ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poziom => $composableBuilder(
    column: $table.poziom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wzorzecRuchu => $composableBuilder(
    column: $table.wzorzecRuchu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriexPowtorzenia => $composableBuilder(
    column: $table.seriexPowtorzenia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kluczoweWskazowki => $composableBuilder(
    column: $table.kluczoweWskazowki,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get czesteBledy => $composableBuilder(
    column: $table.czesteBledy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progresja => $composableBuilder(
    column: $table.progresja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regresja => $composableBuilder(
    column: $table.regresja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zrodlo => $composableBuilder(
    column: $table.zrodlo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ulubione => $composableBuilder(
    column: $table.ulubione,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nazwaPl =>
      $composableBuilder(column: $table.nazwaPl, builder: (column) => column);

  GeneratedColumn<String> get nazwaEn =>
      $composableBuilder(column: $table.nazwaEn, builder: (column) => column);

  GeneratedColumn<String> get partiaGlowna => $composableBuilder(
    column: $table.partiaGlowna,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partieWspierajace => $composableBuilder(
    column: $table.partieWspierajace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sprzet =>
      $composableBuilder(column: $table.sprzet, builder: (column) => column);

  GeneratedColumn<String> get typ =>
      $composableBuilder(column: $table.typ, builder: (column) => column);

  GeneratedColumn<String> get poziom =>
      $composableBuilder(column: $table.poziom, builder: (column) => column);

  GeneratedColumn<String> get wzorzecRuchu => $composableBuilder(
    column: $table.wzorzecRuchu,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriexPowtorzenia => $composableBuilder(
    column: $table.seriexPowtorzenia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tempo =>
      $composableBuilder(column: $table.tempo, builder: (column) => column);

  GeneratedColumn<String> get kluczoweWskazowki => $composableBuilder(
    column: $table.kluczoweWskazowki,
    builder: (column) => column,
  );

  GeneratedColumn<String> get czesteBledy => $composableBuilder(
    column: $table.czesteBledy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get progresja =>
      $composableBuilder(column: $table.progresja, builder: (column) => column);

  GeneratedColumn<String> get regresja =>
      $composableBuilder(column: $table.regresja, builder: (column) => column);

  GeneratedColumn<String> get zrodlo =>
      $composableBuilder(column: $table.zrodlo, builder: (column) => column);

  GeneratedColumn<bool> get ulubione =>
      $composableBuilder(column: $table.ulubione, builder: (column) => column);
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nazwaPl = const Value.absent(),
                Value<String> nazwaEn = const Value.absent(),
                Value<String> partiaGlowna = const Value.absent(),
                Value<String> partieWspierajace = const Value.absent(),
                Value<String> sprzet = const Value.absent(),
                Value<String> typ = const Value.absent(),
                Value<String> poziom = const Value.absent(),
                Value<String> wzorzecRuchu = const Value.absent(),
                Value<String> seriexPowtorzenia = const Value.absent(),
                Value<String> tempo = const Value.absent(),
                Value<String> kluczoweWskazowki = const Value.absent(),
                Value<String> czesteBledy = const Value.absent(),
                Value<String> progresja = const Value.absent(),
                Value<String> regresja = const Value.absent(),
                Value<String> zrodlo = const Value.absent(),
                Value<bool> ulubione = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                nazwaPl: nazwaPl,
                nazwaEn: nazwaEn,
                partiaGlowna: partiaGlowna,
                partieWspierajace: partieWspierajace,
                sprzet: sprzet,
                typ: typ,
                poziom: poziom,
                wzorzecRuchu: wzorzecRuchu,
                seriexPowtorzenia: seriexPowtorzenia,
                tempo: tempo,
                kluczoweWskazowki: kluczoweWskazowki,
                czesteBledy: czesteBledy,
                progresja: progresja,
                regresja: regresja,
                zrodlo: zrodlo,
                ulubione: ulubione,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nazwaPl,
                required String nazwaEn,
                required String partiaGlowna,
                required String partieWspierajace,
                required String sprzet,
                required String typ,
                required String poziom,
                required String wzorzecRuchu,
                required String seriexPowtorzenia,
                required String tempo,
                required String kluczoweWskazowki,
                required String czesteBledy,
                required String progresja,
                required String regresja,
                required String zrodlo,
                Value<bool> ulubione = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                nazwaPl: nazwaPl,
                nazwaEn: nazwaEn,
                partiaGlowna: partiaGlowna,
                partieWspierajace: partieWspierajace,
                sprzet: sprzet,
                typ: typ,
                poziom: poziom,
                wzorzecRuchu: wzorzecRuchu,
                seriexPowtorzenia: seriexPowtorzenia,
                tempo: tempo,
                kluczoweWskazowki: kluczoweWskazowki,
                czesteBledy: czesteBledy,
                progresja: progresja,
                regresja: regresja,
                zrodlo: zrodlo,
                ulubione: ulubione,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      required DateTime dataStart,
      Value<DateTime?> dataKoniec,
      Value<int> czasTrwaniaSekund,
      Value<String?> notatka,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<DateTime> dataStart,
      Value<DateTime?> dataKoniec,
      Value<int> czasTrwaniaSekund,
      Value<String?> notatka,
    });

final class $$WorkoutSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SetsLogTable, List<SetsLogData>>
  _setsLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setsLog,
    aliasName: $_aliasNameGenerator(db.workoutSessions.id, db.setsLog.sesjaId),
  );

  $$SetsLogTableProcessedTableManager get setsLogRefs {
    final manager = $$SetsLogTableTableManager(
      $_db,
      $_db.setsLog,
    ).filter((f) => f.sesjaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setsLogRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataStart => $composableBuilder(
    column: $table.dataStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataKoniec => $composableBuilder(
    column: $table.dataKoniec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get czasTrwaniaSekund => $composableBuilder(
    column: $table.czasTrwaniaSekund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notatka => $composableBuilder(
    column: $table.notatka,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setsLogRefs(
    Expression<bool> Function($$SetsLogTableFilterComposer f) f,
  ) {
    final $$SetsLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setsLog,
      getReferencedColumn: (t) => t.sesjaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetsLogTableFilterComposer(
            $db: $db,
            $table: $db.setsLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataStart => $composableBuilder(
    column: $table.dataStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataKoniec => $composableBuilder(
    column: $table.dataKoniec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get czasTrwaniaSekund => $composableBuilder(
    column: $table.czasTrwaniaSekund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notatka => $composableBuilder(
    column: $table.notatka,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dataStart =>
      $composableBuilder(column: $table.dataStart, builder: (column) => column);

  GeneratedColumn<DateTime> get dataKoniec => $composableBuilder(
    column: $table.dataKoniec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get czasTrwaniaSekund => $composableBuilder(
    column: $table.czasTrwaniaSekund,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notatka =>
      $composableBuilder(column: $table.notatka, builder: (column) => column);

  Expression<T> setsLogRefs<T extends Object>(
    Expression<T> Function($$SetsLogTableAnnotationComposer a) f,
  ) {
    final $$SetsLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setsLog,
      getReferencedColumn: (t) => t.sesjaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetsLogTableAnnotationComposer(
            $db: $db,
            $table: $db.setsLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSession, $$WorkoutSessionsTableReferences),
          WorkoutSession,
          PrefetchHooks Function({bool setsLogRefs})
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> dataStart = const Value.absent(),
                Value<DateTime?> dataKoniec = const Value.absent(),
                Value<int> czasTrwaniaSekund = const Value.absent(),
                Value<String?> notatka = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                dataStart: dataStart,
                dataKoniec: dataKoniec,
                czasTrwaniaSekund: czasTrwaniaSekund,
                notatka: notatka,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime dataStart,
                Value<DateTime?> dataKoniec = const Value.absent(),
                Value<int> czasTrwaniaSekund = const Value.absent(),
                Value<String?> notatka = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                dataStart: dataStart,
                dataKoniec: dataKoniec,
                czasTrwaniaSekund: czasTrwaniaSekund,
                notatka: notatka,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setsLogRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (setsLogRefs) db.setsLog],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setsLogRefs)
                    await $_getPrefetchedData<
                      WorkoutSession,
                      $WorkoutSessionsTable,
                      SetsLogData
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutSessionsTableReferences
                          ._setsLogRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).setsLogRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sesjaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSession, $$WorkoutSessionsTableReferences),
      WorkoutSession,
      PrefetchHooks Function({bool setsLogRefs})
    >;
typedef $$SetsLogTableCreateCompanionBuilder =
    SetsLogCompanion Function({
      Value<int> id,
      required int sesjaId,
      required String cwiczenieId,
      required String nazwaCwiczeniaPl,
      required int numerSerii,
      Value<double?> ciezarKg,
      Value<int?> powtorzenia,
      Value<int?> czasSekund,
      Value<int?> rpe,
      Value<DateTime> timestamp,
    });
typedef $$SetsLogTableUpdateCompanionBuilder =
    SetsLogCompanion Function({
      Value<int> id,
      Value<int> sesjaId,
      Value<String> cwiczenieId,
      Value<String> nazwaCwiczeniaPl,
      Value<int> numerSerii,
      Value<double?> ciezarKg,
      Value<int?> powtorzenia,
      Value<int?> czasSekund,
      Value<int?> rpe,
      Value<DateTime> timestamp,
    });

final class $$SetsLogTableReferences
    extends BaseReferences<_$AppDatabase, $SetsLogTable, SetsLogData> {
  $$SetsLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sesjaIdTable(_$AppDatabase db) =>
      db.workoutSessions.createAlias(
        $_aliasNameGenerator(db.setsLog.sesjaId, db.workoutSessions.id),
      );

  $$WorkoutSessionsTableProcessedTableManager get sesjaId {
    final $_column = $_itemColumn<int>('sesja_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sesjaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetsLogTableFilterComposer
    extends Composer<_$AppDatabase, $SetsLogTable> {
  $$SetsLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cwiczenieId => $composableBuilder(
    column: $table.cwiczenieId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nazwaCwiczeniaPl => $composableBuilder(
    column: $table.nazwaCwiczeniaPl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numerSerii => $composableBuilder(
    column: $table.numerSerii,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ciezarKg => $composableBuilder(
    column: $table.ciezarKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get powtorzenia => $composableBuilder(
    column: $table.powtorzenia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get czasSekund => $composableBuilder(
    column: $table.czasSekund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutSessionsTableFilterComposer get sesjaId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sesjaId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetsLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SetsLogTable> {
  $$SetsLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cwiczenieId => $composableBuilder(
    column: $table.cwiczenieId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nazwaCwiczeniaPl => $composableBuilder(
    column: $table.nazwaCwiczeniaPl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numerSerii => $composableBuilder(
    column: $table.numerSerii,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ciezarKg => $composableBuilder(
    column: $table.ciezarKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get powtorzenia => $composableBuilder(
    column: $table.powtorzenia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get czasSekund => $composableBuilder(
    column: $table.czasSekund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sesjaId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sesjaId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetsLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetsLogTable> {
  $$SetsLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cwiczenieId => $composableBuilder(
    column: $table.cwiczenieId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nazwaCwiczeniaPl => $composableBuilder(
    column: $table.nazwaCwiczeniaPl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numerSerii => $composableBuilder(
    column: $table.numerSerii,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ciezarKg =>
      $composableBuilder(column: $table.ciezarKg, builder: (column) => column);

  GeneratedColumn<int> get powtorzenia => $composableBuilder(
    column: $table.powtorzenia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get czasSekund => $composableBuilder(
    column: $table.czasSekund,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sesjaId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sesjaId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetsLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetsLogTable,
          SetsLogData,
          $$SetsLogTableFilterComposer,
          $$SetsLogTableOrderingComposer,
          $$SetsLogTableAnnotationComposer,
          $$SetsLogTableCreateCompanionBuilder,
          $$SetsLogTableUpdateCompanionBuilder,
          (SetsLogData, $$SetsLogTableReferences),
          SetsLogData,
          PrefetchHooks Function({bool sesjaId})
        > {
  $$SetsLogTableTableManager(_$AppDatabase db, $SetsLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetsLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetsLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetsLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sesjaId = const Value.absent(),
                Value<String> cwiczenieId = const Value.absent(),
                Value<String> nazwaCwiczeniaPl = const Value.absent(),
                Value<int> numerSerii = const Value.absent(),
                Value<double?> ciezarKg = const Value.absent(),
                Value<int?> powtorzenia = const Value.absent(),
                Value<int?> czasSekund = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => SetsLogCompanion(
                id: id,
                sesjaId: sesjaId,
                cwiczenieId: cwiczenieId,
                nazwaCwiczeniaPl: nazwaCwiczeniaPl,
                numerSerii: numerSerii,
                ciezarKg: ciezarKg,
                powtorzenia: powtorzenia,
                czasSekund: czasSekund,
                rpe: rpe,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sesjaId,
                required String cwiczenieId,
                required String nazwaCwiczeniaPl,
                required int numerSerii,
                Value<double?> ciezarKg = const Value.absent(),
                Value<int?> powtorzenia = const Value.absent(),
                Value<int?> czasSekund = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => SetsLogCompanion.insert(
                id: id,
                sesjaId: sesjaId,
                cwiczenieId: cwiczenieId,
                nazwaCwiczeniaPl: nazwaCwiczeniaPl,
                numerSerii: numerSerii,
                ciezarKg: ciezarKg,
                powtorzenia: powtorzenia,
                czasSekund: czasSekund,
                rpe: rpe,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetsLogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sesjaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sesjaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sesjaId,
                                referencedTable: $$SetsLogTableReferences
                                    ._sesjaIdTable(db),
                                referencedColumn: $$SetsLogTableReferences
                                    ._sesjaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SetsLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetsLogTable,
      SetsLogData,
      $$SetsLogTableFilterComposer,
      $$SetsLogTableOrderingComposer,
      $$SetsLogTableAnnotationComposer,
      $$SetsLogTableCreateCompanionBuilder,
      $$SetsLogTableUpdateCompanionBuilder,
      (SetsLogData, $$SetsLogTableReferences),
      SetsLogData,
      PrefetchHooks Function({bool sesjaId})
    >;
typedef $$MoodEntriesTableCreateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> data,
      required double snGodziny,
      required int energia,
      required int nastroj,
      required int apetyt,
      Value<bool> alkohol,
      Value<int> alkoholJednostki,
    });
typedef $$MoodEntriesTableUpdateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> data,
      Value<double> snGodziny,
      Value<int> energia,
      Value<int> nastroj,
      Value<int> apetyt,
      Value<bool> alkohol,
      Value<int> alkoholJednostki,
    });

class $$MoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get snGodziny => $composableBuilder(
    column: $table.snGodziny,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energia => $composableBuilder(
    column: $table.energia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nastroj => $composableBuilder(
    column: $table.nastroj,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get apetyt => $composableBuilder(
    column: $table.apetyt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alkohol => $composableBuilder(
    column: $table.alkohol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get alkoholJednostki => $composableBuilder(
    column: $table.alkoholJednostki,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get snGodziny => $composableBuilder(
    column: $table.snGodziny,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energia => $composableBuilder(
    column: $table.energia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nastroj => $composableBuilder(
    column: $table.nastroj,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get apetyt => $composableBuilder(
    column: $table.apetyt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alkohol => $composableBuilder(
    column: $table.alkohol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get alkoholJednostki => $composableBuilder(
    column: $table.alkoholJednostki,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get snGodziny =>
      $composableBuilder(column: $table.snGodziny, builder: (column) => column);

  GeneratedColumn<int> get energia =>
      $composableBuilder(column: $table.energia, builder: (column) => column);

  GeneratedColumn<int> get nastroj =>
      $composableBuilder(column: $table.nastroj, builder: (column) => column);

  GeneratedColumn<int> get apetyt =>
      $composableBuilder(column: $table.apetyt, builder: (column) => column);

  GeneratedColumn<bool> get alkohol =>
      $composableBuilder(column: $table.alkohol, builder: (column) => column);

  GeneratedColumn<int> get alkoholJednostki => $composableBuilder(
    column: $table.alkoholJednostki,
    builder: (column) => column,
  );
}

class $$MoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoodEntriesTable,
          MoodEntry,
          $$MoodEntriesTableFilterComposer,
          $$MoodEntriesTableOrderingComposer,
          $$MoodEntriesTableAnnotationComposer,
          $$MoodEntriesTableCreateCompanionBuilder,
          $$MoodEntriesTableUpdateCompanionBuilder,
          (
            MoodEntry,
            BaseReferences<_$AppDatabase, $MoodEntriesTable, MoodEntry>,
          ),
          MoodEntry,
          PrefetchHooks Function()
        > {
  $$MoodEntriesTableTableManager(_$AppDatabase db, $MoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<double> snGodziny = const Value.absent(),
                Value<int> energia = const Value.absent(),
                Value<int> nastroj = const Value.absent(),
                Value<int> apetyt = const Value.absent(),
                Value<bool> alkohol = const Value.absent(),
                Value<int> alkoholJednostki = const Value.absent(),
              }) => MoodEntriesCompanion(
                id: id,
                data: data,
                snGodziny: snGodziny,
                energia: energia,
                nastroj: nastroj,
                apetyt: apetyt,
                alkohol: alkohol,
                alkoholJednostki: alkoholJednostki,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                required double snGodziny,
                required int energia,
                required int nastroj,
                required int apetyt,
                Value<bool> alkohol = const Value.absent(),
                Value<int> alkoholJednostki = const Value.absent(),
              }) => MoodEntriesCompanion.insert(
                id: id,
                data: data,
                snGodziny: snGodziny,
                energia: energia,
                nastroj: nastroj,
                apetyt: apetyt,
                alkohol: alkohol,
                alkoholJednostki: alkoholJednostki,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoodEntriesTable,
      MoodEntry,
      $$MoodEntriesTableFilterComposer,
      $$MoodEntriesTableOrderingComposer,
      $$MoodEntriesTableAnnotationComposer,
      $$MoodEntriesTableCreateCompanionBuilder,
      $$MoodEntriesTableUpdateCompanionBuilder,
      (MoodEntry, BaseReferences<_$AppDatabase, $MoodEntriesTable, MoodEntry>),
      MoodEntry,
      PrefetchHooks Function()
    >;
typedef $$MeasurementsTableCreateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<int> id,
      Value<DateTime> data,
      required double wagaKg,
      Value<double?> obwodKlatki,
      Value<double?> obwodTalii,
      Value<double?> obwodBioder,
      Value<double?> obwodBicepsuP,
      Value<double?> obwodBicepsuL,
      Value<double?> obwodUdaP,
      Value<double?> obwodUdaL,
      Value<double?> obwodLydkiP,
      Value<double?> obwodLydkiL,
      Value<double?> procentTluszczu,
      Value<int?> tetnoSpoczynkowe,
      Value<String?> cisnienie,
      Value<String?> notatka,
    });
typedef $$MeasurementsTableUpdateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<int> id,
      Value<DateTime> data,
      Value<double> wagaKg,
      Value<double?> obwodKlatki,
      Value<double?> obwodTalii,
      Value<double?> obwodBioder,
      Value<double?> obwodBicepsuP,
      Value<double?> obwodBicepsuL,
      Value<double?> obwodUdaP,
      Value<double?> obwodUdaL,
      Value<double?> obwodLydkiP,
      Value<double?> obwodLydkiL,
      Value<double?> procentTluszczu,
      Value<int?> tetnoSpoczynkowe,
      Value<String?> cisnienie,
      Value<String?> notatka,
    });

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wagaKg => $composableBuilder(
    column: $table.wagaKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodKlatki => $composableBuilder(
    column: $table.obwodKlatki,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodTalii => $composableBuilder(
    column: $table.obwodTalii,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodBioder => $composableBuilder(
    column: $table.obwodBioder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodBicepsuP => $composableBuilder(
    column: $table.obwodBicepsuP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodBicepsuL => $composableBuilder(
    column: $table.obwodBicepsuL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodUdaP => $composableBuilder(
    column: $table.obwodUdaP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodUdaL => $composableBuilder(
    column: $table.obwodUdaL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodLydkiP => $composableBuilder(
    column: $table.obwodLydkiP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obwodLydkiL => $composableBuilder(
    column: $table.obwodLydkiL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get procentTluszczu => $composableBuilder(
    column: $table.procentTluszczu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tetnoSpoczynkowe => $composableBuilder(
    column: $table.tetnoSpoczynkowe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cisnienie => $composableBuilder(
    column: $table.cisnienie,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notatka => $composableBuilder(
    column: $table.notatka,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wagaKg => $composableBuilder(
    column: $table.wagaKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodKlatki => $composableBuilder(
    column: $table.obwodKlatki,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodTalii => $composableBuilder(
    column: $table.obwodTalii,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodBioder => $composableBuilder(
    column: $table.obwodBioder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodBicepsuP => $composableBuilder(
    column: $table.obwodBicepsuP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodBicepsuL => $composableBuilder(
    column: $table.obwodBicepsuL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodUdaP => $composableBuilder(
    column: $table.obwodUdaP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodUdaL => $composableBuilder(
    column: $table.obwodUdaL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodLydkiP => $composableBuilder(
    column: $table.obwodLydkiP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obwodLydkiL => $composableBuilder(
    column: $table.obwodLydkiL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get procentTluszczu => $composableBuilder(
    column: $table.procentTluszczu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tetnoSpoczynkowe => $composableBuilder(
    column: $table.tetnoSpoczynkowe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cisnienie => $composableBuilder(
    column: $table.cisnienie,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notatka => $composableBuilder(
    column: $table.notatka,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get wagaKg =>
      $composableBuilder(column: $table.wagaKg, builder: (column) => column);

  GeneratedColumn<double> get obwodKlatki => $composableBuilder(
    column: $table.obwodKlatki,
    builder: (column) => column,
  );

  GeneratedColumn<double> get obwodTalii => $composableBuilder(
    column: $table.obwodTalii,
    builder: (column) => column,
  );

  GeneratedColumn<double> get obwodBioder => $composableBuilder(
    column: $table.obwodBioder,
    builder: (column) => column,
  );

  GeneratedColumn<double> get obwodBicepsuP => $composableBuilder(
    column: $table.obwodBicepsuP,
    builder: (column) => column,
  );

  GeneratedColumn<double> get obwodBicepsuL => $composableBuilder(
    column: $table.obwodBicepsuL,
    builder: (column) => column,
  );

  GeneratedColumn<double> get obwodUdaP =>
      $composableBuilder(column: $table.obwodUdaP, builder: (column) => column);

  GeneratedColumn<double> get obwodUdaL =>
      $composableBuilder(column: $table.obwodUdaL, builder: (column) => column);

  GeneratedColumn<double> get obwodLydkiP => $composableBuilder(
    column: $table.obwodLydkiP,
    builder: (column) => column,
  );

  GeneratedColumn<double> get obwodLydkiL => $composableBuilder(
    column: $table.obwodLydkiL,
    builder: (column) => column,
  );

  GeneratedColumn<double> get procentTluszczu => $composableBuilder(
    column: $table.procentTluszczu,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tetnoSpoczynkowe => $composableBuilder(
    column: $table.tetnoSpoczynkowe,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cisnienie =>
      $composableBuilder(column: $table.cisnienie, builder: (column) => column);

  GeneratedColumn<String> get notatka =>
      $composableBuilder(column: $table.notatka, builder: (column) => column);
}

class $$MeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurementsTable,
          Measurement,
          $$MeasurementsTableFilterComposer,
          $$MeasurementsTableOrderingComposer,
          $$MeasurementsTableAnnotationComposer,
          $$MeasurementsTableCreateCompanionBuilder,
          $$MeasurementsTableUpdateCompanionBuilder,
          (
            Measurement,
            BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>,
          ),
          Measurement,
          PrefetchHooks Function()
        > {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<double> wagaKg = const Value.absent(),
                Value<double?> obwodKlatki = const Value.absent(),
                Value<double?> obwodTalii = const Value.absent(),
                Value<double?> obwodBioder = const Value.absent(),
                Value<double?> obwodBicepsuP = const Value.absent(),
                Value<double?> obwodBicepsuL = const Value.absent(),
                Value<double?> obwodUdaP = const Value.absent(),
                Value<double?> obwodUdaL = const Value.absent(),
                Value<double?> obwodLydkiP = const Value.absent(),
                Value<double?> obwodLydkiL = const Value.absent(),
                Value<double?> procentTluszczu = const Value.absent(),
                Value<int?> tetnoSpoczynkowe = const Value.absent(),
                Value<String?> cisnienie = const Value.absent(),
                Value<String?> notatka = const Value.absent(),
              }) => MeasurementsCompanion(
                id: id,
                data: data,
                wagaKg: wagaKg,
                obwodKlatki: obwodKlatki,
                obwodTalii: obwodTalii,
                obwodBioder: obwodBioder,
                obwodBicepsuP: obwodBicepsuP,
                obwodBicepsuL: obwodBicepsuL,
                obwodUdaP: obwodUdaP,
                obwodUdaL: obwodUdaL,
                obwodLydkiP: obwodLydkiP,
                obwodLydkiL: obwodLydkiL,
                procentTluszczu: procentTluszczu,
                tetnoSpoczynkowe: tetnoSpoczynkowe,
                cisnienie: cisnienie,
                notatka: notatka,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                required double wagaKg,
                Value<double?> obwodKlatki = const Value.absent(),
                Value<double?> obwodTalii = const Value.absent(),
                Value<double?> obwodBioder = const Value.absent(),
                Value<double?> obwodBicepsuP = const Value.absent(),
                Value<double?> obwodBicepsuL = const Value.absent(),
                Value<double?> obwodUdaP = const Value.absent(),
                Value<double?> obwodUdaL = const Value.absent(),
                Value<double?> obwodLydkiP = const Value.absent(),
                Value<double?> obwodLydkiL = const Value.absent(),
                Value<double?> procentTluszczu = const Value.absent(),
                Value<int?> tetnoSpoczynkowe = const Value.absent(),
                Value<String?> cisnienie = const Value.absent(),
                Value<String?> notatka = const Value.absent(),
              }) => MeasurementsCompanion.insert(
                id: id,
                data: data,
                wagaKg: wagaKg,
                obwodKlatki: obwodKlatki,
                obwodTalii: obwodTalii,
                obwodBioder: obwodBioder,
                obwodBicepsuP: obwodBicepsuP,
                obwodBicepsuL: obwodBicepsuL,
                obwodUdaP: obwodUdaP,
                obwodUdaL: obwodUdaL,
                obwodLydkiP: obwodLydkiP,
                obwodLydkiL: obwodLydkiL,
                procentTluszczu: procentTluszczu,
                tetnoSpoczynkowe: tetnoSpoczynkowe,
                cisnienie: cisnienie,
                notatka: notatka,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurementsTable,
      Measurement,
      $$MeasurementsTableFilterComposer,
      $$MeasurementsTableOrderingComposer,
      $$MeasurementsTableAnnotationComposer,
      $$MeasurementsTableCreateCompanionBuilder,
      $$MeasurementsTableUpdateCompanionBuilder,
      (
        Measurement,
        BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>,
      ),
      Measurement,
      PrefetchHooks Function()
    >;
typedef $$FitnessTestResultsTableCreateCompanionBuilder =
    FitnessTestResultsCompanion Function({
      Value<int> id,
      required String typ,
      Value<DateTime> data,
      required double wynik,
      Value<int> score,
    });
typedef $$FitnessTestResultsTableUpdateCompanionBuilder =
    FitnessTestResultsCompanion Function({
      Value<int> id,
      Value<String> typ,
      Value<DateTime> data,
      Value<double> wynik,
      Value<int> score,
    });

class $$FitnessTestResultsTableFilterComposer
    extends Composer<_$AppDatabase, $FitnessTestResultsTable> {
  $$FitnessTestResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typ => $composableBuilder(
    column: $table.typ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wynik => $composableBuilder(
    column: $table.wynik,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FitnessTestResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $FitnessTestResultsTable> {
  $$FitnessTestResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typ => $composableBuilder(
    column: $table.typ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wynik => $composableBuilder(
    column: $table.wynik,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FitnessTestResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FitnessTestResultsTable> {
  $$FitnessTestResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get typ =>
      $composableBuilder(column: $table.typ, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get wynik =>
      $composableBuilder(column: $table.wynik, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$FitnessTestResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FitnessTestResultsTable,
          FitnessTestResult,
          $$FitnessTestResultsTableFilterComposer,
          $$FitnessTestResultsTableOrderingComposer,
          $$FitnessTestResultsTableAnnotationComposer,
          $$FitnessTestResultsTableCreateCompanionBuilder,
          $$FitnessTestResultsTableUpdateCompanionBuilder,
          (
            FitnessTestResult,
            BaseReferences<
              _$AppDatabase,
              $FitnessTestResultsTable,
              FitnessTestResult
            >,
          ),
          FitnessTestResult,
          PrefetchHooks Function()
        > {
  $$FitnessTestResultsTableTableManager(
    _$AppDatabase db,
    $FitnessTestResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FitnessTestResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FitnessTestResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FitnessTestResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> typ = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<double> wynik = const Value.absent(),
                Value<int> score = const Value.absent(),
              }) => FitnessTestResultsCompanion(
                id: id,
                typ: typ,
                data: data,
                wynik: wynik,
                score: score,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String typ,
                Value<DateTime> data = const Value.absent(),
                required double wynik,
                Value<int> score = const Value.absent(),
              }) => FitnessTestResultsCompanion.insert(
                id: id,
                typ: typ,
                data: data,
                wynik: wynik,
                score: score,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FitnessTestResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FitnessTestResultsTable,
      FitnessTestResult,
      $$FitnessTestResultsTableFilterComposer,
      $$FitnessTestResultsTableOrderingComposer,
      $$FitnessTestResultsTableAnnotationComposer,
      $$FitnessTestResultsTableCreateCompanionBuilder,
      $$FitnessTestResultsTableUpdateCompanionBuilder,
      (
        FitnessTestResult,
        BaseReferences<
          _$AppDatabase,
          $FitnessTestResultsTable,
          FitnessTestResult
        >,
      ),
      FitnessTestResult,
      PrefetchHooks Function()
    >;
typedef $$PersonalRecordsTableCreateCompanionBuilder =
    PersonalRecordsCompanion Function({
      Value<int> id,
      required String cwiczenieId,
      required String nazwaCwiczeniaPl,
      required double ciezarKg,
      required int powtorzenia,
      Value<DateTime> data,
      required double szacowane1Rm,
    });
typedef $$PersonalRecordsTableUpdateCompanionBuilder =
    PersonalRecordsCompanion Function({
      Value<int> id,
      Value<String> cwiczenieId,
      Value<String> nazwaCwiczeniaPl,
      Value<double> ciezarKg,
      Value<int> powtorzenia,
      Value<DateTime> data,
      Value<double> szacowane1Rm,
    });

class $$PersonalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cwiczenieId => $composableBuilder(
    column: $table.cwiczenieId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nazwaCwiczeniaPl => $composableBuilder(
    column: $table.nazwaCwiczeniaPl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ciezarKg => $composableBuilder(
    column: $table.ciezarKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get powtorzenia => $composableBuilder(
    column: $table.powtorzenia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get szacowane1Rm => $composableBuilder(
    column: $table.szacowane1Rm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cwiczenieId => $composableBuilder(
    column: $table.cwiczenieId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nazwaCwiczeniaPl => $composableBuilder(
    column: $table.nazwaCwiczeniaPl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ciezarKg => $composableBuilder(
    column: $table.ciezarKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get powtorzenia => $composableBuilder(
    column: $table.powtorzenia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get szacowane1Rm => $composableBuilder(
    column: $table.szacowane1Rm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cwiczenieId => $composableBuilder(
    column: $table.cwiczenieId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nazwaCwiczeniaPl => $composableBuilder(
    column: $table.nazwaCwiczeniaPl,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ciezarKg =>
      $composableBuilder(column: $table.ciezarKg, builder: (column) => column);

  GeneratedColumn<int> get powtorzenia => $composableBuilder(
    column: $table.powtorzenia,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get szacowane1Rm => $composableBuilder(
    column: $table.szacowane1Rm,
    builder: (column) => column,
  );
}

class $$PersonalRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalRecordsTable,
          PersonalRecord,
          $$PersonalRecordsTableFilterComposer,
          $$PersonalRecordsTableOrderingComposer,
          $$PersonalRecordsTableAnnotationComposer,
          $$PersonalRecordsTableCreateCompanionBuilder,
          $$PersonalRecordsTableUpdateCompanionBuilder,
          (
            PersonalRecord,
            BaseReferences<
              _$AppDatabase,
              $PersonalRecordsTable,
              PersonalRecord
            >,
          ),
          PersonalRecord,
          PrefetchHooks Function()
        > {
  $$PersonalRecordsTableTableManager(
    _$AppDatabase db,
    $PersonalRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cwiczenieId = const Value.absent(),
                Value<String> nazwaCwiczeniaPl = const Value.absent(),
                Value<double> ciezarKg = const Value.absent(),
                Value<int> powtorzenia = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<double> szacowane1Rm = const Value.absent(),
              }) => PersonalRecordsCompanion(
                id: id,
                cwiczenieId: cwiczenieId,
                nazwaCwiczeniaPl: nazwaCwiczeniaPl,
                ciezarKg: ciezarKg,
                powtorzenia: powtorzenia,
                data: data,
                szacowane1Rm: szacowane1Rm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cwiczenieId,
                required String nazwaCwiczeniaPl,
                required double ciezarKg,
                required int powtorzenia,
                Value<DateTime> data = const Value.absent(),
                required double szacowane1Rm,
              }) => PersonalRecordsCompanion.insert(
                id: id,
                cwiczenieId: cwiczenieId,
                nazwaCwiczeniaPl: nazwaCwiczeniaPl,
                ciezarKg: ciezarKg,
                powtorzenia: powtorzenia,
                data: data,
                szacowane1Rm: szacowane1Rm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonalRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalRecordsTable,
      PersonalRecord,
      $$PersonalRecordsTableFilterComposer,
      $$PersonalRecordsTableOrderingComposer,
      $$PersonalRecordsTableAnnotationComposer,
      $$PersonalRecordsTableCreateCompanionBuilder,
      $$PersonalRecordsTableUpdateCompanionBuilder,
      (
        PersonalRecord,
        BaseReferences<_$AppDatabase, $PersonalRecordsTable, PersonalRecord>,
      ),
      PersonalRecord,
      PrefetchHooks Function()
    >;
typedef $$WorkoutPlansTableCreateCompanionBuilder =
    WorkoutPlansCompanion Function({
      Value<int> id,
      required String nazwa,
      required String cwiczeniaIds,
      required String cel,
      Value<DateTime> dataUtworzenia,
    });
typedef $$WorkoutPlansTableUpdateCompanionBuilder =
    WorkoutPlansCompanion Function({
      Value<int> id,
      Value<String> nazwa,
      Value<String> cwiczeniaIds,
      Value<String> cel,
      Value<DateTime> dataUtworzenia,
    });

class $$WorkoutPlansTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutPlansTable> {
  $$WorkoutPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nazwa => $composableBuilder(
    column: $table.nazwa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cwiczeniaIds => $composableBuilder(
    column: $table.cwiczeniaIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cel => $composableBuilder(
    column: $table.cel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataUtworzenia => $composableBuilder(
    column: $table.dataUtworzenia,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutPlansTable> {
  $$WorkoutPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nazwa => $composableBuilder(
    column: $table.nazwa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cwiczeniaIds => $composableBuilder(
    column: $table.cwiczeniaIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cel => $composableBuilder(
    column: $table.cel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataUtworzenia => $composableBuilder(
    column: $table.dataUtworzenia,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutPlansTable> {
  $$WorkoutPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nazwa =>
      $composableBuilder(column: $table.nazwa, builder: (column) => column);

  GeneratedColumn<String> get cwiczeniaIds => $composableBuilder(
    column: $table.cwiczeniaIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cel =>
      $composableBuilder(column: $table.cel, builder: (column) => column);

  GeneratedColumn<DateTime> get dataUtworzenia => $composableBuilder(
    column: $table.dataUtworzenia,
    builder: (column) => column,
  );
}

class $$WorkoutPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutPlansTable,
          WorkoutPlan,
          $$WorkoutPlansTableFilterComposer,
          $$WorkoutPlansTableOrderingComposer,
          $$WorkoutPlansTableAnnotationComposer,
          $$WorkoutPlansTableCreateCompanionBuilder,
          $$WorkoutPlansTableUpdateCompanionBuilder,
          (
            WorkoutPlan,
            BaseReferences<_$AppDatabase, $WorkoutPlansTable, WorkoutPlan>,
          ),
          WorkoutPlan,
          PrefetchHooks Function()
        > {
  $$WorkoutPlansTableTableManager(_$AppDatabase db, $WorkoutPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nazwa = const Value.absent(),
                Value<String> cwiczeniaIds = const Value.absent(),
                Value<String> cel = const Value.absent(),
                Value<DateTime> dataUtworzenia = const Value.absent(),
              }) => WorkoutPlansCompanion(
                id: id,
                nazwa: nazwa,
                cwiczeniaIds: cwiczeniaIds,
                cel: cel,
                dataUtworzenia: dataUtworzenia,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nazwa,
                required String cwiczeniaIds,
                required String cel,
                Value<DateTime> dataUtworzenia = const Value.absent(),
              }) => WorkoutPlansCompanion.insert(
                id: id,
                nazwa: nazwa,
                cwiczeniaIds: cwiczeniaIds,
                cel: cel,
                dataUtworzenia: dataUtworzenia,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutPlansTable,
      WorkoutPlan,
      $$WorkoutPlansTableFilterComposer,
      $$WorkoutPlansTableOrderingComposer,
      $$WorkoutPlansTableAnnotationComposer,
      $$WorkoutPlansTableCreateCompanionBuilder,
      $$WorkoutPlansTableUpdateCompanionBuilder,
      (
        WorkoutPlan,
        BaseReferences<_$AppDatabase, $WorkoutPlansTable, WorkoutPlan>,
      ),
      WorkoutPlan,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$SetsLogTableTableManager get setsLog =>
      $$SetsLogTableTableManager(_db, _db.setsLog);
  $$MoodEntriesTableTableManager get moodEntries =>
      $$MoodEntriesTableTableManager(_db, _db.moodEntries);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$FitnessTestResultsTableTableManager get fitnessTestResults =>
      $$FitnessTestResultsTableTableManager(_db, _db.fitnessTestResults);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(_db, _db.personalRecords);
  $$WorkoutPlansTableTableManager get workoutPlans =>
      $$WorkoutPlansTableTableManager(_db, _db.workoutPlans);
}
