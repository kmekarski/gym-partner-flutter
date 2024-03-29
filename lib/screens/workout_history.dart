import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_partner/models/plan_tag.dart';
import 'package:gym_partner/models/workout_in_history.dart';
import 'package:gym_partner/providers/user_provider.dart';
import 'package:gym_partner/services/history_service.dart';
import 'package:gym_partner/utils/time_format.dart';
import 'package:gym_partner/widgets/badges/custom_filter_chip.dart';
import 'package:gym_partner/widgets/chart/chart.dart';
import 'package:gym_partner/widgets/workout_in_history_row.dart';

final historyService = HistoryService();

const Map<ChartTime, String> chartTimeStrings = {
  ChartTime.lastWeek: 'Last week',
  ChartTime.thisMonth: 'This month',
  ChartTime.allTime: 'All time',
};

const Map<ChartDataType, String> chartDataTypeStrings = {
  ChartDataType.exercises: 'Exercises',
  ChartDataType.sets: 'Sets',
  ChartDataType.time: 'Time',
};

class ChartBarData {
  const ChartBarData({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;
}

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  ChartDataType _selectedChartDataType = ChartDataType.exercises;
  ChartTime _selectedChartTime = ChartTime.lastWeek;

  late Map<ChartDataType, int> weekTotalStatsData;
  late Map<ChartDataType, int> monthTotalStatsData;
  late Map<ChartDataType, int> allTimeTotalStatsData;

  late Map<String, Map<ChartDataType, int>> weekChartData;
  late Map<String, Map<ChartDataType, int>> monthChartData;
  late Map<String, Map<ChartDataType, int>> allTimeChartData;

  @override
  void initState() {
    _getDataFromService();
    super.initState();
  }

  void _getDataFromService() {
    final workoutsHistory = ref.read(userProvider).workoutsHistory;
    weekChartData = historyService.calculateHistoryChartData(
        workoutsHistory, ChartTime.lastWeek);
    monthChartData = historyService.calculateHistoryChartData(
        workoutsHistory, ChartTime.thisMonth);
    allTimeChartData = historyService.calculateHistoryChartData(
        workoutsHistory, ChartTime.allTime);

    weekTotalStatsData =
        historyService.calculateTotalStats(workoutsHistory, ChartTime.lastWeek);
    monthTotalStatsData = historyService.calculateTotalStats(
        workoutsHistory, ChartTime.thisMonth);
    allTimeTotalStatsData =
        historyService.calculateTotalStats(workoutsHistory, ChartTime.allTime);
  }

  Map<ChartDataType, int> get totalStatsData {
    if (_selectedChartTime == ChartTime.lastWeek) {
      return weekTotalStatsData;
    }
    if (_selectedChartTime == ChartTime.thisMonth) {
      return monthTotalStatsData;
    } else {
      return allTimeTotalStatsData;
    }
  }

  Map<String, Map<ChartDataType, int>> get chartData {
    if (_selectedChartTime == ChartTime.lastWeek) {
      return weekChartData;
    }
    if (_selectedChartTime == ChartTime.thisMonth) {
      return monthChartData;
    } else {
      return allTimeChartData;
    }
  }

  // final List<WorkoutInHistory> workoutsHistory = [
  //   for (var i = 0; i < 30; i++)
  //     WorkoutInHistory(
  //       id: '$i',
  //       planName: 'some plan',
  //       tags: [
  //         PlanTag.cardio,
  //         PlanTag.strength,
  //       ],
  //       dayIndex: 0,
  //       numOfSets: Random().nextInt(10) + 20,
  //       numOfExercises: Random().nextInt(10),
  //       timeInSeconds: Random().nextInt(4000) + 10000,
  //       timestamp:
  //           Timestamp.fromDate(DateTime.now().subtract(Duration(days: i))),
  //     ),
  // ];

  void _selectChartDataType(ChartDataType chartDataType) {
    setState(() {
      _selectedChartDataType = chartDataType;
    });
  }

  void _selectChartTime(ChartTime chartTime) {
    setState(() {
      _selectedChartTime = chartTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutsHistory = ref.watch(userProvider).workoutsHistory;
    var filteredWorkoutsHistory = workoutsHistory
        .where((workoutInHistory) => chartTimeConditions[_selectedChartTime]!(
            workoutInHistory.timestamp.toDate()))
        .toList();

    var mappedChartData = chartData.entries
        .map((e) => ChartBarData(
            value: e.value[_selectedChartDataType] ?? 0, label: e.key))
        .toList();

    var totalStatsRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          totalStat('Total exercises',
              totalStatsData[ChartDataType.exercises].toString()),
          totalStat(
              'Total sets', totalStatsData[ChartDataType.sets].toString()),
          totalStat('Total time',
              timeFormat(totalStatsData[ChartDataType.time] ?? 0)),
        ],
      ),
    );

    var workoutsList = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredWorkoutsHistory.length,
      itemBuilder: (context, index) =>
          WorkoutInHistoryRow(workoutInHistory: filteredWorkoutsHistory[index]),
    );
    var chartDataTypePicker = SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final chartDataType in ChartDataType.values)
            CustomFilterChip(
              text: chartDataTypeStrings[chartDataType] ?? '',
              onTap: () => _selectChartDataType(chartDataType),
              isSelected: _selectedChartDataType == chartDataType,
              hasTick: true,
            ),
        ],
      ),
    );
    var chartTimePicker = SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final chartTime in ChartTime.values)
            CustomFilterChip(
              text: chartTimeStrings[chartTime] ?? '',
              onTap: () => _selectChartTime(chartTime),
              isSelected: _selectedChartTime == chartTime,
              hasTick: true,
            ),
        ],
      ),
    );
    var chart = Chart(
      data: mappedChartData,
      height: 240,
      barWidth: 56,
      chartDataType: _selectedChartDataType,
    );
    var listTitle = Text(
      'Finished workouts',
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('My workout history'),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              totalStatsRow,
              const Divider(),
              chart,
              const SizedBox(height: 12),
              chartDataTypePicker,
              const SizedBox(height: 16),
              chartTimePicker,
              const SizedBox(height: 32),
              listTitle,
              const SizedBox(height: 16),
              workoutsList,
            ],
          )),
    );
  }

  Widget totalStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
