import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'services/voice_controller.dart';
import 'widgets/voice_bar.dart';

const _windowWidth = 480.0;
const _windowHeight = 88.0;
const _bottomMargin = 24.0;
const _windowPadding = 8.0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  final controller = VoiceController();
  await controller.initialize();

  final display = await screenRetriever.getPrimaryDisplay();
  final screenSize = display.size;
  final x = (screenSize.width - _windowWidth) / 2;
  final y = screenSize.height - _windowHeight - _bottomMargin;

  const windowOptions = WindowOptions(
    size: Size(_windowWidth, _windowHeight),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPosition(Offset(x, y));
    await windowManager.setMinimumSize(const Size(_windowWidth, _windowHeight));
    await windowManager.setMaximumSize(const Size(_windowWidth, _windowHeight));
    await windowManager.setResizable(false);
    await windowManager.setHasShadow(false);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.show();
  });

  if (Platform.isMacOS || Platform.isWindows) {
    final f5HotKey = HotKey(
      key: PhysicalKeyboardKey.f5,
      modifiers: const [],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      f5HotKey,
      keyDownHandler: (_) => controller.toggleRecording(),
    );
  }

  runApp(VoiceBarApp(controller: controller));
}

class VoiceBarApp extends StatelessWidget {
  const VoiceBarApp({super.key, required this.controller});

  final VoiceController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Bar',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(_windowPadding),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: VoiceBar(controller: controller),
          ),
        ),
      ),
    );
  }
}
