// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart'; // TripicApp이 정의된 파일 import

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TripicApp());

    // 스플래시 화면이 잘 뜨는지 확인 (Tripic 텍스트가 있는지)
    expect(find.text('Tripic'), findsWidgets); // Tripic 텍스트가 하나 이상 있는지 확인
  });
}
