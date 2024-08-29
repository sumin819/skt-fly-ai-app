import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void handleErrors(BuildContext context, http.Response response) {
  if (response.statusCode == 400) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('엑세스 토큰 오류: 다시 로그인하세요.')),
    );
  } else if (response.statusCode == 404) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('카메라 시리얼 번호를 찾을 수 없습니다.')),
    );
  } else if (response.statusCode == 409) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이미 등록/해제된 카메라입니다.')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('카메라 등록/해제 실패: ${response.statusCode}')),
    );
  }
}