import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Import GetStorage
import 'package:japanese_quick_reader/controllers/settings_controller.dart'; // Import SettingsController
import 'package:japanese_quick_reader/views/home_screen.dart';
import 'package:japanese_quick_reader/views/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize GetStorage for persistence
  await GetStorage.init();
  // Initialize SettingsController. It loads settings in its onInit.
  Get.put(SettingsController());

  // Run the app. Theme is now handled reactively within SettingsController and MyApp.
  runApp(const MyApp());
}

// MyApp can now be a const StatelessWidget as theme is handled by GetX
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the SettingsController instance
    final SettingsController settingsController = Get.find();

    // Use Obx to reactively listen to themeMode changes
    return Obx(
      () => GetMaterialApp(
        title: 'Japanese Quick Reader',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme(),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ),
        ),
        // Bind themeMode directly to the controller's reactive variable
        themeMode: settingsController.themeMode.value,
        // Remove const as HomeScreen constructor is not const
        home: HomeScreen(),
        getPages: [
          // Remove const as SettingsScreen constructor is not const
          GetPage(name: '/settings', page: () => SettingsScreen()),
        ],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
