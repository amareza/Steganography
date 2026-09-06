import 'package:flutter_test/flutter_test.dart';
import 'package:project/main.dart'; // نام پروژه خود را به جای your_project_name بگذارید

void main() {
  testWidgets('StegoApp loads correctly test', (WidgetTester tester) async {
    // بارگذاری ویجت اصلی برنامه
    await tester.pumpWidget(const StegoApp());

    // بررسی وجود عنوان دکمه‌ها در صفحه اصلی
    expect(find.text('Encoding (کدگذاری)'), findsOneWidget);
    expect(find.text('Decoding (رمزگشایی)'), findsOneWidget);
  });
}
