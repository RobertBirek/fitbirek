import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../domain/training_trend.dart';
import '../providers/training_trend_providers.dart';

class TrainingTrendsPage extends ConsumerStatefulWidget {
  const TrainingTrendsPage({super.key});
  @override
  ConsumerState<TrainingTrendsPage> createState()=>_TrainingTrendsPageState();
}

class _TrainingTrendsPageState extends ConsumerState<TrainingTrendsPage> {
  String? exercise;
  String? side;
  String? variant;
  String sideLabel(String? value)=>switch(value) {
    'left'=>'Lewa', 'right'=>'Prawa', 'both'=>'Obie', _=>'Strona niezapisana (NULL)',
  };
  @override
  Widget build(BuildContext context) {
    final history=ref.watch(trainingTrendHistoryProvider);
    final metadata=ref.watch(exerciseCatalogMetadataProvider);
    Widget body;
    // Never render Riverpod's previous-account/previous-query cached value.
    if(history.isLoading) {
      body=const Center(child:CircularProgressIndicator());
    } else if(history.hasError) {
      body=const Center(child:Text('Nie udało się odczytać historii. Wróć i spróbuj ponownie.'));
    } else if(history.valueOrNull==null) {
      body=const Center(child:Text('Konto niedostępne lub zmienione. Otwórz trendy ponownie.'));
    } else {
      final rows=history.valueOrNull!;
      if(rows.isEmpty) {
        body=const Center(child:Text('Brak zakończonej historii'));
      } else {
        final exercises=rows.map((r)=>r.scope.exerciseId).toSet().toList()..sort();
        final selectedExercise=exercises.contains(exercise)?exercise!:exercises.first;
        final exerciseRows=rows.where((r)=>r.scope.exerciseId==selectedExercise).toList();
        final sides=exerciseRows.map((r)=>r.scope.side).toSet().toList()..sort((a,b)=>(a??'').compareTo(b??''));
        final selectedSide=sides.contains(side)?side:sides.first;
        final sideRows=exerciseRows.where((r)=>r.scope.side==selectedSide).toList();
        final variants=sideRows.map((r)=>r.scope.variantId).toSet().toList()..sort((a,b)=>(a??'').compareTo(b??''));
        final selectedVariant=variants.contains(variant)?variant:variants.first;
        String variantLabel(String? id) => id==null?'Wariant bazowy':
          '${sideRows.lastWhere((r)=>r.scope.variantId==id).variantLabel ?? 'Wariant historyczny'} • $id';
        final scope=(exerciseId:selectedExercise,side:selectedSide,variantId:selectedVariant);
        final tracking=metadata.isLoading || metadata.hasError ? 'unknown' :
          metadata.valueOrNull?.entryFor(selectedExercise)?.tracking ?? 'unknown';
        final report=buildTrainingTrend(scope,rows,tracking:tracking);
        body=ListView(padding:const EdgeInsets.all(16),children:[
          const Text('Tylko odczyt • zakończone, nieusunięte sesje. Bez zmian PR i celów.'),
          DropdownButtonFormField<String>(key:const Key('trend-exercise'),initialValue:selectedExercise,
            isExpanded:true,decoration:const InputDecoration(labelText:'Ćwiczenie'),
            items:[for(final id in exercises) DropdownMenuItem(value:id,child:Text('${rows.lastWhere((r)=>r.scope.exerciseId==id).exerciseName} • $id'))],
            onChanged:(value)=>setState(() {exercise=value;side=null;variant=null;})),
          DropdownButtonFormField<int>(key:ValueKey('trend-side-$selectedExercise'),initialValue:sides.indexOf(selectedSide),
            decoration:const InputDecoration(labelText:'Strona'),
            items:[for(var i=0;i<sides.length;i++) DropdownMenuItem(value:i,child:Text(sideLabel(sides[i])))],
            onChanged:(value)=>setState(() {side=sides[value!];variant=null;})),
          KeyedSubtree(key:ValueKey((selectedExercise,selectedSide)),child:DropdownButtonFormField<int>(key:const Key('trend-variant'),initialValue:variants.indexOf(selectedVariant),
            isExpanded:true,decoration:const InputDecoration(labelText:'Wariant z historii (nazwa ze snapshotu)'),
            items:[for(var i=0;i<variants.length;i++) DropdownMenuItem(value:i,child:Text(variantLabel(variants[i])))],
            onChanged:(value)=>setState(()=>variant=variants[value!]))),
          const SizedBox(height:16),
          const Text('Progi: 0–1 porównywalnych sesji — za mało danych; 2 — tylko porównanie; ≥3 — opis trendu. Każdy kontrakt liczony osobno.'),
          const Text('Powtórzenia: identyczny układ obciążeń i liczba serii; nie sumujemy różnych kg. RPE: maksimum, tylko przy identycznej zapisanej pracy. To porównanie zapisu, nie dowód identycznych przerw, tempa ani poprawy formy.'),
          if(report.observations.map((r)=>r.sessionId).toSet().length<2)
            const Text('Za mało danych: potrzeba co najmniej 2 porównywalnych sesji.'),
          if(report.series.isEmpty) const Text('Brak porównywalnej metryki — zobacz obserwacje i powody poniżej.'),
          for(final series in report.series) Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(series.metric,style:Theme.of(context).textTheme.titleMedium),
            Text(series.contract),
            Text(switch(series.status) {
              TrendStatus.tooLittleData=>'Za mało danych w tym kontrakcie. Inna liczba serii, ciężar lub praca to osobna grupa, nie porównanie.',
              TrendStatus.comparisonOnly=>'Tylko porównanie 2 sesji — jeszcze nie trend.',
              TrendStatus.comparableTrend=>'Trend opisowy ≥3 porównywalnych sesji (pierwsza → ostatnia).',
            }),
            if(series.change!=null) Text('Zmiana: ${series.change!>0?'+':''}${series.change} ${series.metric=='RPE'?'RPE':'powt.'}. ${series.metric=='RPE'?'Niższe RPE oznacza niższy zgłoszony wysiłek wyłącznie dla tej samej zapisanej pracy.':'Bez oceny zdrowia ani zalecenia progresji.'}'),
            for(final sample in series.samples) Text('${sample.date.toIso8601String().substring(0,10)} • sesja ${sample.sessionId}: ${sample.value}'),
          ]))),
          const SizedBox(height:12),
          Text('Obserwacje — zapisane serie',style:Theme.of(context).textTheme.titleMedium),
          const Text('Sekundy to wyłącznie zapisany czas pracy. Brak wartości ≠ zero. Dla czasu/rund brak pełnego protokołu oznacza nieporównywalność, nawet przy równych wynikach.'),
          for(final row in report.observations) ListTile(contentPadding:EdgeInsets.zero,
            title:Text('${row.endedAt.toIso8601String().substring(0,10)} • sesja ${row.sessionId}, seria ${row.setNumber}'),
            subtitle:Text('${tracking=='rounds'?'Rundy':'Powtórzenia'}: ${row.reps??'brak'} • kg: ${row.load??'brak'} • praca: ${row.seconds??'brak'} s • RPE: ${row.rpe??'brak'}')),
          for(final exclusion in report.exclusions) Text('Sesja ${exclusion.sessionId}: ${exclusion.reason}'),
        ]);
      }
    }
    return Scaffold(appBar:AppBar(title:const Text('Trendy treningowe')),body:SafeArea(child:body));
  }
}
