import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:moducbt/features/main/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'moducbt',
      theme: ThemeData(),
      home: const MainScreen(),
    );
  }
}
