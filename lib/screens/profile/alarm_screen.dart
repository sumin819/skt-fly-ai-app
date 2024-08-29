import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front/route/server.dart';
import 'package:front/states/auth_provider.dart';
import 'package:front/theme/colors.dart';
import 'package:front/utils/handle_error.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AlarmScreen extends StatefulWidget {
  AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Map<String, dynamic>> alarmList = [];

  @override
  void initState() {
    super.initState();
    // Fetch data when the screen loads
    registerRequest(context);
  }

  void registerRequest(BuildContext context) async {
    final url = Uri.parse('${main_server}/user/log');

    final response = await http.post(
      url,
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization':
        'Bearer ${Provider.of<AuthProvider>(context, listen: false).accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      List<dynamic> logs = jsonData['log'];

      setState(() {
        alarmList = logs.map((log) {
          // Parse and format the date and time
          String rawDate = log['date'].toString();
          String formattedDate;
          String formattedTime;

          // Check if the date contains 'T'
          if (rawDate.contains('T')) {
            List<String> dateTimeSplit = rawDate.split('T');
            formattedDate = dateTimeSplit[0]; // Date part
            formattedTime = dateTimeSplit[1].split('.')[0]; // Time part
          } else {
            // If 'T' is not present, handle based on the new format
            List<String> dateTimeSplit = rawDate.split(' ');
            formattedDate = dateTimeSplit[0]; // Date part
            formattedTime = dateTimeSplit.length > 1 ? dateTimeSplit[1].split('.')[0] : ""; // Time part
          }

          return {
            'sn': log['sn'].toString(),
            'date': formattedDate,
            'time': formattedTime,
            'status': log['status'],
          };
        }).toList();
      });
    } else {
      handleErrors(context, response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: yelloMyStyle2,
        appBar: AppBar(
          backgroundColor: whiteMyStyle1,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                context.push('/alarmsetting');
              },
              icon: Icon(
                Icons.settings,
                color: yelloMyStyle1,
                size: 36,
              ),
            ),
          ],
          title: const Text(
            '알림',
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
        ),
        body: alarmList.isEmpty
            ? const NoAlarmWidget() // 알림이 없을 때
            : AlarmListWidget(
          alarmList: alarmList,
          onDelete: (index) {
            setState(() {
              alarmList.removeAt(index);
            });
          },
        ), // 알림이 있을 때 리스트 출력
      ),
    );
  }
}

// 알림이 없을 때 보여줄 위젯
class NoAlarmWidget extends StatelessWidget {
  const NoAlarmWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '알림이 없습니다.',
        style: TextStyle(
          fontSize: 20,
          color: Colors.black54,
        ),
      ),
    );
  }
}

// 알림 리스트를 보여줄 위젯
class AlarmListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alarmList;
  final Function(int) onDelete;

  const AlarmListWidget({
    super.key,
    required this.alarmList,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: alarmList.length,
      itemBuilder: (context, index) {
        final alarm = alarmList[index];
        return Card(
          color: whiteMyStyle1,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(
              Icons.notification_important,
              color: yelloMyStyle1,
              size: 36,
            ),
            title: Text(
              // "센서 번호: ${alarm['sn']}",
              "${getStatusDescription(alarm['status'])}",
              style: const TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              "센서 번호: ${alarm['sn']}\n${alarm['date']} ${alarm['time']}",
              style: const TextStyle(fontSize: 14, color: greyMyStyle),
            ),
            onTap: () {
              // 알림 항목 클릭 시 동작 정의
            },
          ),
        );
      },
    );
  }
}

String getStatusDescription(int status) {
  switch (status) {
    case 0:
      return '감지를 시작했습니다.';
    case 1:
      return '감지를 끝냈습니다.';
    case 2:
      return '음성이 감지됐습니다.';
    case 3:
      return '음성이 감지된 이후 영상이 감지되지 않았습니다';
    case 4:
      return '영상이 감지되었습니다.';
    case 5:
      return '영상이 감지되다가 사라졌습니다.';
    case 6:
      return '포집기가 켜졌습니다.';
    case 7:
      return '포집기가 꺼졌습니다.';
    default:
      return '알 수 없는 상태';
  }
}
