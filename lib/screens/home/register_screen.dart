import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/route/server.dart';
import 'package:front/utils/handle_error.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../states/camera_provider.dart';
import '../../theme/colors.dart';
import '../../states/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final List<Map<String, String>> cameras; // 카메라 목록을 받는 변수

  RegisterScreen({required this.cameras});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  late int _cameraCount;

  @override
  void initState() {
    super.initState();
    // _cameraCount = widget.cameras.length + 1;
    _cameraCount = Provider.of<CameraProvider>(context, listen: false).cameras.length + 1;
  }

  void registerRequest(BuildContext context, String number, String name) async {
    final url = Uri.parse('${main_server}/sensor/register');

    final response = await http.patch(
      url,
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).accessToken}',
      },
      body: jsonEncode({
        'SN': number,
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      print('카메라 등록 성공: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라가 성공적으로 등록되었습니다.')),
      );

      Provider.of<CameraProvider>(context, listen: false).addCamera({
        'serialNumber': number,
        'cameraName': name,
      });

      setState(() {

      });

      _serialNumberController.clear();
      _nameController.clear();
    } else {
      handleErrors(context, response);
    }
  }

  void unregisterRequest(BuildContext context, String number, String name) async {
    final url = Uri.parse('${main_server}/sensor/unregister');

    try {
      final response = await http.patch(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).accessToken}',
        },
        body: jsonEncode({
          'SN': number,
        }),
      );

      if (response.statusCode == 200) {
        print('카메라 해제 성공: ${response.body}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('카메라가 성공적으로 등록 해제되었습니다.')),
          );

          // Provider 접근은 mounted 체크 이후에만 실행
          Provider.of<CameraProvider>(context, listen: false).removeCamera({
            'serialNumber': number,
            'cameraName': name,
          });

          // setState로 리스트뷰 업데이트
          setState(() {});
        }
      } else {
        handleErrors(context, response);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버와 통신 중 오류가 발생했습니다. 다시 시도하세요.')),
        );
      }
    }
  }


  void _registerCamera() {
    if (_formKey.currentState!.validate()) {
      String serialNumber = _serialNumberController.text;
      String name = _nameController.text.trim();

      if (name.isEmpty) {
        name = 'Cam$_cameraCount';
        _cameraCount++;
      }

      registerRequest(context, serialNumber, name);
    }
  }

  void _showUnregisterDialog(BuildContext context, Map<String, String> camera) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("카메라 등록 해제"),
          content: Text("카메라 '${camera['cameraName']}'을(를) 등록 해제 하시겠습니까?"),
          actions: [
            TextButton(
              child: Text("취소"),
              onPressed: () {
                context.pop();
              },style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)
              ),
              // backgroundColor: yelloMyStyle1,
              foregroundColor: blackMyStyle1,
              padding: EdgeInsets.symmetric(vertical: 8.0),
            ),

            ),
            TextButton(
              child: Text("예"),
              onPressed: () {
                unregisterRequest(context, camera['serialNumber']!, camera['cameraName']!);
                context.pop();
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                ),
                backgroundColor: yelloMyStyle1,
                foregroundColor: blackMyStyle1,
                padding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: yelloMyStyle2,
        appBar: AppBar(
          title: const Text(
            '카메라 등록',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _serialNumberController,
                      decoration: InputDecoration(
                        labelText: '시리얼 번호 12자리 (필수)',
                        hintText: '123456789012',
                        border: UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: yelloMyStyle1),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: blackMyStyle2),
                        ),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(12),
                      ],
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '시리얼 번호는 필수입니다.';
                        }
                        if (!RegExp(r'^\d{12}$').hasMatch(value)) {
                          return '숫자 12자를 입력하세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '카메라 이름 최대 20자 (선택)',
                        hintText: 'Cam1',
                        helperText: '이름은 미입력 시 자동으로 부여됩니다.',
                        border: UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: yelloMyStyle1),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: blackMyStyle2),
                        ),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 100,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _registerCamera,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor: yelloMyStyle1,
                              foregroundColor: blackMyStyle1,
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                            ),
                            child: Text(
                              '등록하기',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.0),
              Container(
                height: 1.0,
                color: yelloMyStyle1,
              ),
              SizedBox(height: 24.0),
              Container(
                height: 40.0,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      '등록된 카메라',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontFamily: 'PretendardBold',
                      ),
                    ),
                    SizedBox(width: 8.0,),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Text(
                                '카메라를 꾹 눌러 등록 해제하세요.',
                                style: TextStyle(fontSize: 16.0,),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: Text('확인',),
                                  style: TextButton.styleFrom(
                                    foregroundColor: blackMyStyle1,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Icon(
                        Icons.lightbulb_circle_outlined,
                        size: 20,
                        color: greyMyStyle,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Consumer<CameraProvider>(
                  builder: (context, cameraProvider, child) {
                    final cameras = cameraProvider.cameras;
                    return cameras.isEmpty
                        ? Center(
                      child: Text(
                        '등록된 카메라가 없습니다.',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                        : ListView.builder(
                      itemCount: cameras.length,
                      itemBuilder: (context, index) {
                        final camera = cameras[index];
                        return Card(
                          color: whiteMyStyle1,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(
                              Icons.camera_alt,
                              color: yelloMyStyle1,
                              size: 36,
                            ),
                            title: Text(
                              camera['cameraName'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle: Text(
                              'SN: ${camera['serialNumber']}',
                              style: const TextStyle(
                                  fontSize: 14, color: greyMyStyle),
                            ),
                            // onTap: () {
                            //   // 클릭 시 동작 정의
                            // },
                            onLongPress: () {
                              _showUnregisterDialog(context, camera);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

