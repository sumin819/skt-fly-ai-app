import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front/screens/historys/notification_screen.dart';
import 'package:front/theme/colors.dart';

class AnalysisChart extends StatelessWidget {
  final String selectedPeriod;
  final List<BarChartGroupData> barData;
  final List<String> weekLabels;
  final List<NotificationItem> yearlyLogs;

  const AnalysisChart({
    Key? key,
    required this.selectedPeriod,
    required this.barData,
    required this.weekLabels,
    required this.yearlyLogs,
  }) : super(key: key);

  double _getYAxisInterval() {
    if (barData.isEmpty) {
      return 1;
    }

    double maxY = barData
        .map((data) => data.barRods.map((rod) => rod.toY).reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);

    double interval = (maxY / 15).ceilToDouble();
    return interval > 0 ? interval : 1;
  }

  double _getMaxYValue() {
    if (barData.isEmpty) {
      return 1;
    }
    return barData
        .map((data) => data.barRods.map((rod) => rod.toY).reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
  }

  // 일간 라벨링
  Widget _getDailyLabel(double value) {
    if (value.toInt() >= 0 && value.toInt() < 24) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          '${value.toInt()}시',
          style: const TextStyle(
            color: blackMyStyle1,
            fontFamily: 'PretendardSemiBold',
            fontSize: 12,
            letterSpacing: -1.0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return const Text('');
    }
  }

  Widget _getMonthlyLabel(double value) {
    if (value.toInt() >= 0 && value.toInt() < weekLabels.length) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          weekLabels[value.toInt()], // 주간 라벨 사용
          style: const TextStyle(
            color: blackMyStyle1,
            fontFamily: 'PretendardSemiBold',
            fontSize: 12,
            letterSpacing: -1.0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return const Text('');
    }
  }

  // 연간 라벨링
  Widget _getYearlyLabel(double value) {
    if (value.toInt() >= 0 && value.toInt() < yearlyLogs.length) {
      final DateTime logTime = yearlyLogs[value.toInt()].time;
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          '${logTime.month}월',
          style: const TextStyle(
            color: blackMyStyle1,
            fontFamily: 'PretendardSemiBold',
            fontSize: 12,
            letterSpacing: -1.0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barData,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 1,
          horizontalInterval: _getYAxisInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: greyMyStyle.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: greyMyStyle.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                switch (selectedPeriod) {
                  case '일간':
                    return _getDailyLabel(value);
                  case '월간':
                    return _getMonthlyLabel(value);
                  case '연간':
                    return _getYearlyLabel(value);
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // 오른쪽 제목 숨김
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // 상단 제목 숨김
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(
              color: Colors.black,
              width: 2,
            ),
            bottom: BorderSide(
              color: Colors.black,
              width: 2,
            ),
          ),
        ),
        maxY: _getMaxYValue() * 1.2, // maxY 값을 추가하여 상단 여백 확보
      ),
    );
  }
}
