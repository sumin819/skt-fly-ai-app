import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:front/route/server.dart';
import 'package:front/states/auth_provider.dart';
import 'package:front/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging import

void sendLoginInRequest(BuildContext context, String id, String pw, String fcmToken, Function onError) async {
  final url = Uri.parse('${main_server}/user/signin');

  print('---login_screen - sendLoginInRequest---');
  print(fcmToken);

  final response = await http.patch(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'username': id,
      'password': pw,
      'fcm': fcmToken,  // FCM 토큰 추가
    }),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    final token = responseData['access_token'];

    Provider.of<AuthProvider>(context, listen: false).login(token);
    context.go('/');
    print('POST 요청 성공: ${response.body}');
  } else {
    if (response.statusCode == 401) {
      onError('비밀번호가 틀렸습니다.', true, false);
    } else if (response.statusCode == 404) {
      onError('해당 ID가 존재하지 않습니다.', false, true);
    } else {
      print('POST 요청 실패: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${response.statusCode}')),
      );
    }
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  Color _suffixIconColor = blackMyStyle2;
  String? _phoneNumberError;
  String? _passwordError;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(_validatePhoneNumber);

    // FCM 토큰 가져오기
    FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        _fcmToken = token;
        print("FCM 토큰: $_fcmToken");
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || !RegExp(r'^\d{11}$').hasMatch(value)) {
      return '올바른 핸드폰 번호를 입력하세요.';
    }
    return _phoneNumberError;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력하세요.';
    }
    return _passwordError;
  }

  void _validatePhoneNumber() {
    String input = _textEditingController.text;
    bool isValid = RegExp(r'^\d{11}$').hasMatch(input);

    setState(() {
      _suffixIconColor = isValid ? yelloMyStyle1 : blackMyStyle2;
    });
  }

  void _login(BuildContext context) {
    if (_formKey.currentState!.validate() && _fcmToken != null) {
      print("-------------");
      print(_fcmToken);
      print("-------------");

      sendLoginInRequest(
        context,
        _textEditingController.text,
        _passwordController.text,
        _fcmToken!,  // FCM 토큰 전달
            (String errorMsg, bool isPasswordError, bool isPhoneError) {
          setState(() {
            if (isPasswordError) {
              _passwordError = errorMsg;
            } else if (isPhoneError) {
              _phoneNumberError = errorMsg;
            }
          });
          _formKey.currentState!.validate(); // Revalidate the form to show error messages
        },
      );
    } else {
      // FCM 토큰이 null인 경우에 대한 처리 (예: 네트워크 문제 등)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM 토큰을 가져오는 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: ClearMyStyle1,
      ),
      backgroundColor: yelloMyStyle2,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 150,
                              height: 150,
                            ),
                            const SizedBox(height: 48.0),
                            Container(
                              width: double.infinity,
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: const Text(
                                '로그인 하기',
                                style: TextStyle(
                                  fontFamily: 'PretendardBold',
                                  fontSize: 30,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _textEditingController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [MaskedInputFormatter('00000000000')],
                                      decoration: InputDecoration(
                                        suffixIcon: Icon(
                                          Icons.check,
                                          color: _suffixIconColor,
                                        ),
                                        border: const UnderlineInputBorder(),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: yelloMyStyle1),
                                        ),
                                        enabledBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: blackMyStyle2),
                                        ),
                                        hintText: '핸드폰 번호',
                                        errorText: _phoneNumberError,
                                      ),
                                      validator: validatePhoneNumber,
                                    ),
                                    const SizedBox(height: 8.0),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        border: const UnderlineInputBorder(),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: yelloMyStyle1),
                                        ),
                                        enabledBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: blackMyStyle2),
                                        ),
                                        hintText: '비밀번호',
                                        errorText: _passwordError,
                                      ),
                                      validator: validatePassword,
                                    ),
                                    const SizedBox(height: 32.0),
                                    Container(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _phoneNumberError = null;
                                            _passwordError = null;
                                          });
                                          _login(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          backgroundColor: yelloMyStyle1,
                                          foregroundColor: blackMyStyle1,
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        ),
                                        child: const Text(
                                          '로그인 하기',
                                          style: TextStyle(
                                            fontFamily: 'PretendardBold',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          width: double.infinity,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          // child: const Text(
                          //   '꿀벌 방범대',
                          //   style: TextStyle(
                          //     fontFamily: 'PretendardBold',
                          //     fontSize: 30,
                          //   ),
                          //   textAlign: TextAlign.center,
                          // ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
