import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:japanese_quick_reader/screens/main_screen.dart';
import 'controllers/dictionary_controller.dart';
import 'controllers/japanese_text_controller.dart';

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final txtController = Get.put(JpTextController());
  final dicController = Get.put(DictionaryWidgetController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        brightness: Brightness.light, // Set the default theme to light mode
        // Define other theme properties here
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Set the dark theme
        // Define other dark theme properties here
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      title: 'Japanese Quick Reader',
      home: MainScreen(),
    );
  }
}
