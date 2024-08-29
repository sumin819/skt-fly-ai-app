import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:front/route/server.dart';
import 'package:front/screens/historys/analysis_chart.dart';
import 'package:front/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:front/states/auth_provider.dart';

import 'notification_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Map<String, dynamic> cameraData = {};
  List<NotificationItem> dailyLogs = [];
  List<NotificationItem> monthlyLogs = [];
  List<String> weekLabels = [];
  List<NotificationItem> yearlyLogs = [];
  List<String> cameraKeys = [];
  String _selectedCamera = '종합';
  String _selectedPeriod = '일간';
  List<BarChartGroupData> barData = [];
  ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getAllHistSumRequest(context);
    getAllHistRequest(context);
  }

  // '종합' 데이터를 요청하는 함수
  void getAllHistSumRequest(BuildContext context) async {
    final url = Uri.parse('${main_server}/sensor/hist/all/sum');
    try {
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          // Clear previous logs
          dailyLogs.clear();
          monthlyLogs.clear();
          yearlyLogs.clear();

          // Process daily logs
          responseData['day'].forEach((date, count) {
            final parts = date.split('-');
            if (parts.length == 4) {
              try {
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final day = int.parse(parts[2]);
                final hour = int.parse(parts[3]);
                DateTime parsedDate = DateTime(year, month, day, hour);
                dailyLogs.add(NotificationItem(parsedDate, count));
              } catch (e) {
                print("Error parsing day data: $date, error: $e");
              }
            }
          });

          // Process monthly logs
          responseData['month'].forEach((date, count) {
            final parts = date.split('-');
            if (parts.length == 3) {
              try {
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final day = int.parse(parts[2]);
                DateTime parsedDate = DateTime(year, month, day);
                monthlyLogs.add(NotificationItem(parsedDate, count));
              } catch (e) {
                print("Error parsing month data: $date, error: $e");
              }
            }
          });

          // Process yearly logs
          final currentMonth = DateTime.now();
          for (int i = 0; i < 12; i++) {
            final monthToConsider =
            DateTime(currentMonth.year, currentMonth.month - i, 1);
            String formattedDate =
                "${monthToConsider.year}-${monthToConsider.month.toString().padLeft(2, '0')}";
            yearlyLogs.add(NotificationItem(monthToConsider, responseData['year'][formattedDate] ?? 0));
          }

          _updateChartData();
        });
      } else if (response.statusCode == 400) {
        print('엑세스 토큰이 유효하지 않거나 만료되었습니다. 로그아웃합니다.');
        await Provider.of<AuthProvider>(context, listen: false).logout();
        context.go('/login');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 모든 카메라 데이터를 요청하는 함수
  void getAllHistRequest(BuildContext context) async {
    final url = Uri.parse('${main_server}/sensor/hist/all');
    try {
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          cameraData = responseData;
          cameraKeys = responseData.keys.toList();
          // 기본적으로 첫 카메라 데이터를 설정함
          _selectedCamera = '종합'; // 초기 선택은 '종합'
        });
      } else if (response.statusCode == 400) {
        print('엑세스 토큰이 유효하지 않거나 만료되었습니다. 로그아웃합니다.');
        await Provider.of<AuthProvider>(context, listen: false).logout();
        context.go('/login');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 선택된 기간에 따라 차트 데이터를 업데이트
  void _updateChartData() {
    if (_selectedCamera == '종합') {
      _updateSumChartData();
      // getAllHistSumRequest(context);
    } else {
      _updateCameraChartData();
    }
  }

  void _updateSumChartData() {
    switch (_selectedPeriod) {
      case '일간':
        barData = _getDailyData();
        break;
      case '월간':
        barData = _getMonthlyData();
        break;
      case '연간':
        barData = _getYearlyData();
        break;
    }
  }

  void _updateCameraChartData() {
    if (_selectedCamera != '종합') {
      final cameraLogs = cameraData[_selectedCamera];
      final dayData = cameraLogs['day'] ?? {};
      final monthData = cameraLogs['month'] ?? {};
      final yearData = cameraLogs['year'] ?? {};

      dailyLogs.clear();
      monthlyLogs.clear();
      yearlyLogs.clear();

      dayData.forEach((date, count) {
        final parts = date.split('-');
        if (parts.length == 4) {
          try {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            final hour = int.parse(parts[3]);
            DateTime parsedDate = DateTime(year, month, day, hour);
            dailyLogs.add(NotificationItem(parsedDate, count));
          } catch (e) {
            print("Error parsing day data: $date, error: $e");
          }
        }
      });

      monthData.forEach((date, count) {
        final parts = date.split('-');
        if (parts.length == 3) {
          try {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            DateTime parsedDate = DateTime(year, month, day);
            monthlyLogs.add(NotificationItem(parsedDate, count));
          } catch (e) {
            print("Error parsing month data: $date, error: $e");
          }
        }
      });

      final currentMonth = DateTime.now();
      for (int i = 0; i < 12; i++) {
        final monthToConsider =
        DateTime(currentMonth.year, currentMonth.month - i, 1);
        String formattedDate =
            "${monthToConsider.year}-${monthToConsider.month.toString().padLeft(2, '0')}";
        yearlyLogs.add(NotificationItem(monthToConsider, yearData[formattedDate] ?? 0));
      }

      _updateSumChartData(); // 일간, 월간, 연간 차트 데이터 업데이트
    }
  }

  List<BarChartGroupData> _getDailyData() {
    List<int> hourlyCounts = List.filled(24, 0);

    dailyLogs.forEach((log) {
      hourlyCounts[log.time.hour] += log.count;
    });

    return List.generate(24, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hourlyCounts[index].toDouble(),
            color: Colors.black,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _getMonthlyData() {
    List<int> weeklyCounts = List.filled(5, 0);
    weekLabels.clear();

    for (int i = 0; i < monthlyLogs.length; i++) {
      DateTime logDate = monthlyLogs[i].time;

      DateTime weekStart = logDate.subtract(Duration(days: logDate.weekday - 1));
      DateTime weekEnd = weekStart.add(const Duration(days: 6));

      String weekLabel = "${weekStart.month}/${weekStart.day}~${weekEnd.month}/${weekEnd.day}";
      weekLabels.add(weekLabel);

      weeklyCounts[i] = monthlyLogs[i].count;
    }

    return List.generate(monthlyLogs.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyCounts[index].toDouble(),
            color: Colors.black,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _getYearlyData() {
    List<int> monthlyCounts = List.filled(12, 0);

    for (int i = 0; i < 12; i++) {
      final monthData = yearlyLogs[i];
      monthlyCounts[11 - i] = monthData.count;
    }

    return List.generate(12, (index) {
      return BarChartGroupData(
        x: index + 1,
        barRods: [
          BarChartRodData(
            toY: monthlyCounts[index].toDouble(),
            color: Colors.black,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }

  double _getChartWidth() {
    switch (_selectedPeriod) {
      case '일간':
        return 24 * 40.0;
      case '월간':
        return monthlyLogs.length * 80.0;
      case '연간':
        return 12 * 40.0;
      default:
        return MediaQuery.of(context).size.width;
    }
  }

  ElevatedButton _buildPeriodButton(String period) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
          _updateChartData();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedPeriod == period ? yelloMyStyle1 : blackMyStyle2,
        foregroundColor: _selectedPeriod == period ? blackMyStyle2 : whiteMyStyle1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 버튼의 radius 적용
        ),
      ),
      child: Text(period),
    );
  }

  Widget _buildTabButton(String tabName) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedCamera = tabName;
          _updateChartData();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedCamera == tabName
            ? yelloMyStyle1.withOpacity(0.9) // 선택된 버튼에 투명도 적용
            : blackMyStyle2.withOpacity(0.7), // 선택되지 않은 버튼에 투명도 적용
        foregroundColor: _selectedCamera == tabName
            ? blackMyStyle2.withOpacity(0.9)
            : whiteMyStyle1.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 버튼의 radius 적용
        ),
      ),
      child: Text(tabName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: yelloMyStyle2,
        appBar: AppBar(
          backgroundColor: yelloMyStyle2,
          title: const Text(
            "분석 리포트",
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'PretendardBold',
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTabButton('종합'),
                    const SizedBox(width: 8),
                    for (var key in cameraKeys) ...[
                      _buildTabButton(key),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  child: SizedBox(
                    width: _getChartWidth(),
                    height: 250,
                    child: AnalysisChart(
                      selectedPeriod: _selectedPeriod,
                      barData: barData,
                      weekLabels: weekLabels,
                      yearlyLogs: yearlyLogs,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodButton('일간'),
                  const SizedBox(width: 8),
                  _buildPeriodButton('월간'),
                  const SizedBox(width: 8),
                  _buildPeriodButton('연간'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: NotificationScreen(
                  selectedPeriod: _selectedPeriod,
                  dailyLogs: dailyLogs,
                  monthlyLogs: monthlyLogs,
                  yearlyLogs: yearlyLogs,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
