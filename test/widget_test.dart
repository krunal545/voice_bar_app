import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_bar_app/services/voice_controller.dart';
import 'package:voice_bar_app/widgets/voice_bar.dart';

void main() {
  testWidgets('Voice bar shows idle state', (WidgetTester tester) async {
    final controller = VoiceController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceBar(controller: controller),
        ),
      ),
    );

    expect(find.text('Voice Bar'), findsOneWidget);
    expect(find.textContaining('F5'), findsOneWidget);

    controller.dispose();
  });
}
