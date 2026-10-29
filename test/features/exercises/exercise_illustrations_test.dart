import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/presentation/exercise_illustrations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedIllustrationIds = {
    'cw001',
    'cw002',
    'cw003',
    'cw004',
    'cw005',
    'cw006',
    'cw007',
    'cw008',
    'cw009',
    'cw010',
    'cw011',
    'cw012',
    'cw013',
    'cw014',
    'cw015',
    'cw016',
    'cw017',
    'cw018',
    'cw019',
    'cw020',
    'cw021',
    'cw022',
    'cw023',
    'cw024',
    'cw025',
    'cw026',
    'cw027',
    'cw028',
    'cw029',
    'cw030',
    'cw031',
    'cw032',
    'cw033',
    'cw034',
    'cw035',
    'cw036',
    'cw037',
    'cw038',
    'cw039',
    'cw040',
    'cw041',
    'cw042',
    'cw043',
    'cw044',
    'cw045',
    'cw046',
    'cw047',
    'cw048',
    'cw049',
    'cw050',
    'cw051',
    'cw052',
    'cw053',
    'cw054',
    'cw055',
    'cw056',
    'cw057',
    'cw058',
    'cw059',
    'cw060',
    'cw061',
    'cw062',
    'cw063',
    'cw064',
    'cw065',
    'cw066',
    'cw067',
    'cw068',
    'cw069',
    'cw070',
    'cw071',
    'cw072',
    'cw073',
    'cw074',
    'cw075',
    'cw076',
    'cw077',
    'cw078',
    'cw079',
    'cw080',
    'cw081',
    'cw082',
    'cw083',
    'cw084',
    'cw085',
    'cw086',
    'cw087',
    'cw088',
    'cw089',
    'cw090',
    'cw091',
    'cw092',
    'cw093',
    'cw094',
    'cw095',
    'cw096',
    'cw097',
    'cw098',
    'cw099',
    'cw100',
    'cw101',
    'cw102',
    'cw103',
    'cw104',
    'cw105',
    'cw106',
    'cw107',
    'cw108',
    'cw109',
    'cw110',
    'cw111',
    'cw112',
    'cw113',
    'cw114',
    'cw115',
    'cw116',
    'cw117',
    'cw118',
    'cw119',
    'cw120',
    'cw121',
    'cw122',
    'cw123',
    'cw124',
    'cw125',
    'cw126',
    'cw127',
    'cw128',
    'cw129',
    'cw130',
    'cw131',
    'cw132',
    'cw133',
    'cw134',
    'cw135',
    'cw136',
    'cw137',
    'cw138',
    'cw139',
    'cw140',
    'cw141',
    'cw142',
    'cw143',
    'cw144',
    'cw145',
    'cw146',
    'cw147',
    'cw148',
    'cw149',
    'cw150',
    'cw151',
    'cw152',
    'cw153',
    'cw154',
    'cw155',
    'cw156',
    'cw157',
    'cw158',
    'cw159',
    'cw160',
    'cw161',
    'cw162',
    'cw163',
    'cw164',
    'cw165',
    'cw166',
    'cw167',
    'cw168',
    'cw169',
    'cw170',
    'cw171',
    'cw172',
    'cw173',
    'cw174',
    'cw175',
    'cw176',
    'cw177',
    'cw178',
    'cw179',
    'cw180',
    'cw181',
    'cw182',
    'cw183',
    'cw184',
    'cw185',
    'cw186',
    'cw187',
    'cw188',
    'cw189',
    'cw190',
    'cw191',
    'cw192',
    'cw193',
    'cw194',
    'cw195',
    'cw196',
    'cw197',
    'cw198',
    'cw199',
    'cw200',
    'cw201',
    'cw202',
    'cw203',
    'cw204',
    'cw205',
    'cw206',
    'cw207',
    'cw208',
    'cw209',
    'cw210',
    'cw211',
    'cw212',
    'cw213',
    'cw214',
    'cw215',
    'cw216',
    'cw217',
    'cw218',
    'cw219',
    'cw220',
    'cw221',
    'cw222',
    'cw223',
    'cw224',
    'cw225',
    'cw226',
    'cw227',
    'cw228',
    'cw229',
    'cw230',
    'cw231',
    'cw232',
    'cw233',
    'cw234',
    'cw235',
    'cw236',
    'cw237',
    'cw238',
    'cw239',
    'cw240',
    'cw241',
    'cw242',
    'cw243',
    'cw244',
    'cw245',
    'cw246',
    'cw247',
    'cw248',
    'cw249',
    'cw250',
    'cw251',
    'cw252',
    'cw253',
    'cw254',
    'cw255',
    'cw256',
    'cw257',
    'cw258',
    'cw259',
    'cw260',
    'cw261',
    'cw262',
    'cw263',
    'cw264',
    'cw265',
    'cw266',
    'cw267',
    'cw268',
    'cw269',
    'cw270',
    'cw271',
    'cw272',
    'cw273',
    'cw274',
    'cw275',
    'cw276',
    'cw277',
    'cw278',
    'cw279',
    'cw280',
    'cw281',
    'cw282',
    'cw283',
    'cw284',
    'cw285',
    'cw286',
    'cw287',
    'cw288',
    'cw289',
    'cw290',
    'cw291',
    'cw292',
    'cw293',
    'cw294',
    'cw295',
    'cw296',
    'cw297',
    'cw298',
    'cw299',
    'cw300',
    'cw301',
    'cw302',
    'cw303',
    'cw304',
    'cw305',
    'cw306',
    'cw307',
    'cw308',
    'cw309',
    'cw310',
    'cw311',
    'cw312',
    'cw313',
    'cw314',
    'cw315',
    'cw316',
    'cw317',
    'cw318',
    'cw319',
    'cw320',
    'cw321',
    'cw322',
    'cw323',
    'cw324',
    'cw325',
    'cw326',
    'cw327',
    'cw328',
    'cw329',
    'cw330',
    'cw331',
    'cw332',
    'cw333',
    'cw334',
    'cw335',
    'cw336',
    'cw337',
    'cw338',
    'cw339',
    'cw340',
    'cw341',
    'cw342',
    'cw343',
    'cw344',
    'cw345',
    'cw346',
    'cw347',
    'cw348',
    'cw349',
    'cw350',
    'cw351',
    'cw352',
    'cw353',
    'cw354',
    'cw355',
    'cw356',
    'cw357',
    'cw358',
    'cw359',
    'cw360',
    'cw361',
    'cw362',
    'cw363',
    'cw364',
    'cw365',
    'cw366',
    'cw367',
    'cw368',
    'cw369',
    'cw370',
    'cw371',
    'cw372',
    'cw373',
    'cw374',
    'cw375',
    'cw376',
    'cw377',
    'cw378',
    'cw379',
    'cw380',
    'cw381',
    'cw382',
    'cw383',
    'cw384',
    'cw385',
    'cw386',
    'cw387',
    'cw388',
    'cw389',
    'cw390',
    'cw391',
    'cw392',
    'cw393',
    'cw394',
    'cw395',
    'cw396',
    'cw397',
    'cw398',
    'cw399',
    'cw400',
    'cw401',
    'cw402',
    'cw403',
    'cw404',
    'cw405',
    'cw406',
    'cw407',
    'cw408',
    'cw409',
    'cw410',
    'cw411',
    'cw412',
    'cw413',
    'cw414',
    'cw415',
    'cw416',
    'cw417',
    'cw418',
    'cw419',
    'cw420',
    'cw421',
    'cw422',
    'cw423',
    'cw424',
    'cw425',
    'cw426',
    'cw427',
    'cw428',
    'cw429',
    'cw430',
    'cw431',
  };

  test(
    '431 catalog exercises have exactly 431 illustrations and no pending',
    () {
      expect(expectedIllustrationIds, hasLength(431));
      expect(awaitingIllustrationExerciseIds, isEmpty);
      expect(illustratedExerciseIds, expectedIllustrationIds);

      final catalog =
          jsonDecode(File('assets/data/exercises.json').readAsStringSync())
              as List;
      final catalogIds = catalog
          .map((exercise) => (exercise as Map<String, dynamic>)['id'] as String)
          .toSet();
      expect(catalog, hasLength(431));
      expect(catalogIds, expectedIllustrationIds);

      for (final id in illustratedExerciseIds) {
        expect(
          exerciseIllustrationAsset(id),
          'assets/exercises/$id.webp',
          reason: id,
        );
      }
    },
  );

  test('every illustration file is registered', () {
    final files = Directory('assets/exercises')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.webp'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();

    expect(files, expectedIllustrationIds.map((id) => '$id.webp').toSet());
  });

  test('asset manifest includes every expected catalog illustration', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final illustrationAssets = manifest
        .listAssets()
        .where((path) => path.startsWith('assets/exercises/'))
        .where((path) => path.endsWith('.webp'))
        .toSet();

    expect(
      illustrationAssets,
      expectedIllustrationIds.map((id) => 'assets/exercises/$id.webp').toSet(),
    );
  });

  test('maps 90/90 hip stretch to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw256'), 'assets/exercises/cw256.webp');
  });

  test('maps cw251 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw251'), 'assets/exercises/cw251.webp');
  });

  test('maps cw252 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw252'), 'assets/exercises/cw252.webp');
  });

  test('maps cw253 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw253'), 'assets/exercises/cw253.webp');
  });

  test('returns no illustration for unknown exercise IDs', () {
    for (final id in ['cw432', 'cw000', '', 'custom-exercise']) {
      expect(exerciseIllustrationAsset(id), isNull, reason: id);
    }
  });

  test('maps cw265 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw265'), 'assets/exercises/cw265.webp');
  });

  test('maps cw261 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw261'), 'assets/exercises/cw261.webp');
  });

  test('maps cw262 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw262'), 'assets/exercises/cw262.webp');
  });

  test('maps cw257 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw257'), 'assets/exercises/cw257.webp');
  });

  test('maps cw264 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw264'), 'assets/exercises/cw264.webp');
  });

  test('maps cw278 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw278'), 'assets/exercises/cw278.webp');
  });

  test('loads and decodes every illustration as 512x512', () async {
    for (final id in expectedIllustrationIds) {
      final data = await rootBundle.load('assets/exercises/$id.webp');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      addTearDown(codec.dispose);
      final frame = await codec.getNextFrame();
      addTearDown(frame.image.dispose);

      expect(frame.image.width, 512, reason: id);
      expect(frame.image.height, 512, reason: id);
    }
  });
}
