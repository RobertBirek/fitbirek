import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/progress/trends/data/training_trend_repository.dart';

void main() {
  test('completed nondeleted history, exact nullable scope, snapshots, SELECT only',() async {
    final db=AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    for(var i=1;i<=5;i++) {
      final id=await db.workoutDao.createSession(WorkoutSessionsCompanion.insert(
        dataStart:DateTime.utc(2026,10,i),dataKoniec:Value(i==3?null:DateTime.utc(2026,10,i,1)),
        czasTrwaniaSekund:const Value(9999),deletedAtUtc:Value(i==4?DateTime.utc(2026):null)));
      for(final side in <String?>[null,'both','left','right']) {
        for(final variant in <String?>[null,'deleted-uuid','other']) {
          await db.workoutDao.addSet(SetsLogCompanion.insert(sesjaId:id,cwiczenieId:'ex',
            nazwaCwiczeniaPl:'Snapshot',numerSerii:1,side:Value(side),variantId:Value(variant),
            variantLabel:Value(variant==null?null:'Dawny wariant'),czasSekund:const Value(30),
            deletedAtUtc:Value(i==5?DateTime.utc(2026):null)));
        }
      }
    }
    final repo=TrainingTrendRepository(db);
    final all=await repo.readHistory();
    expect(all.length,24);
    for(final side in <String?>[null,'both','left','right']) {
      for(final variant in <String?>[null,'deleted-uuid','other']) {
        final rows=await repo.readHistory(scope:(exerciseId:'ex',side:side,variantId:variant));
        expect(rows.length,2);
        expect(rows.map((r)=>r.sessionId),[1,2]);
        expect(rows.every((r)=>r.seconds==30 && r.scope.side==side && r.scope.variantId==variant),isTrue);
        if(variant!=null) expect(rows.first.variantLabel,'Dawny wariant');
      }
    }
    expect(await repo.readHistory(scope:(exerciseId:'other',side:null,variantId:null)),isEmpty);
    expect(await db.select(db.syncOutbox).get(),isEmpty);
    expect(await db.select(db.personalRecords).get(),isEmpty);
    expect((await db.select(db.setsLog).get()).length,60);
  });
}
