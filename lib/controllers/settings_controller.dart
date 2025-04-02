import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:japanese_quick_reader/services/ai_text_service.dart';

// Constants for storage keys to prevent typos
const String _jlptLevelKey = 'jlptLevel';
const String _topicKey = 'topic';
const String _apiKeyKey = 'apiKey';
const String _themeKey = 'theme';
const String _showAdsKey = 'showAds';

// Constants for theme options for clarity and safety
const String _themeSystem = 'System';
const String _themeLight = 'Light';
const String _themeDark = 'Dark';

class SettingsController extends GetxController {
  // Use a private variable for the storage instance
  final _box = GetStorage();

  // --- Observable Settings ---
  // Use late final for observables initialized in onInit
  late final RxString selectedJlptLevel;
  late final RxString selectedTopic;
  late final RxBool showAds;
  late final RxString apiKey;
  late final RxString selectedTheme;
  // Reactive ThemeMode derived from selectedTheme string
  late final Rx<ThemeMode> themeMode;

  // --- Static Data ---
  // Use final for lists that don't change
  final List<String> jlptLevels = const ['N5', 'N4', 'N3', 'N2', 'N1'];
  final List<String> topics = const [
    'Random',
    'Daily Life',
    'Travel',
    'Food',
    'Culture',
    'Business',
    'Education',
    'Technology',
    'Entertainment',
    'Sports',
    'Health',
    'Nature',
    'History',
    'Politics',
    'Art',
    'Science',
    'Hobbies',
    'Family',
    'Relationships',
    'Traditions',
  ];
  final List<String> themeOptions = const [
    _themeSystem,
    _themeLight,
    _themeDark,
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSettings(); // Load all settings first

    // Initialize themeMode based on the loaded selectedTheme
    themeMode = Rx<ThemeMode>(_getThemeModeFromString(selectedTheme.value));

    // Automatically update ThemeMode when selectedTheme changes
    ever(selectedTheme, (String themeString) {
      final newMode = _getThemeModeFromString(themeString);
      if (themeMode.value != newMode) {
        themeMode.value = newMode;
        Get.changeThemeMode(newMode); // Apply the theme change globally
      }
    });

    // Apply initial theme mode based on loaded settings
    Get.changeThemeMode(themeMode.value);
  }

  // --- Private Helper Methods ---

  // Load settings from GetStorage
  void _loadSettings() {
    selectedJlptLevel = RxString(
      _box.read<String>(_jlptLevelKey) ?? jlptLevels.first,
    );
    selectedTopic = RxString(_box.read<String>(_topicKey) ?? topics.first);
    apiKey = RxString(_box.read<String>(_apiKeyKey) ?? '');
    selectedTheme = RxString(_box.read<String>(_themeKey) ?? _themeSystem);
    showAds = RxBool(_box.read<bool>(_showAdsKey) ?? true);

    // Initialize AITextService API key if available
    if (apiKey.value.isNotEmpty) {
      AITextService.setApiKey(apiKey.value);
    }
  }

  // Save all settings to GetStorage
  void _saveSettings() {
    _box.write(_jlptLevelKey, selectedJlptLevel.value);
    _box.write(_topicKey, selectedTopic.value);
    _box.write(_themeKey, selectedTheme.value);
    _box.write(_showAdsKey, showAds.value);
    _box.write(_apiKeyKey, apiKey.value);
    // GetStorage saves automatically, _box.save() is rarely needed.
  }

  // Helper to convert theme string to ThemeMode enum
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case _themeLight:
        return ThemeMode.light;
      case _themeDark:
        return ThemeMode.dark;
      case _themeSystem:
      default: // Default to system theme if unknown value
        return ThemeMode.system;
    }
  }

  // --- Public Methods to Update Settings ---

  void updateJlptLevel(String? level) {
    // Add validation
    if (level != null && jlptLevels.contains(level)) {
      selectedJlptLevel.value = level;
      _saveSettings();
    }
  }

  void updateTopic(String? topic) {
    // Add validation
    if (topic != null && topics.contains(topic)) {
      selectedTopic.value = topic;
      _saveSettings();
    }
  }

  void updateTheme(String? theme) {
    // Add validation
    if (theme != null && themeOptions.contains(theme)) {
      selectedTheme.value = theme; // This triggers the 'ever' listener
      _saveSettings();
    }
  }

  void toggleAds(bool value) {
    showAds.value = value;
    _saveSettings();
  }

  Future<void> purchasePremium() async {
    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false, // Prevent dismissing by tapping outside
    );

    try {
      // Simulate network request or purchase flow
      await Future.delayed(const Duration(seconds: 1));

      // Update state on success
      showAds.value = false;
      _saveSettings();

      Get.back(); // Close the loading dialog

      Get.snackbar(
        'Success',
        'Premium upgrade successful! Ads removed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close the loading dialog on error
      Get.snackbar(
        'Error',
        'Purchase failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void updateApiKey(String newApiKey) {
    // Trim whitespace
    final trimmedKey = newApiKey.trim();

    // Basic validation (e.g., check if empty or too short)
    if (trimmedKey.isNotEmpty && trimmedKey.length < 10) {
      Get.snackbar(
        'Invalid API Key',
        'The API key appears too short. Please check and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return; // Don't save invalid key
    }

    apiKey.value = trimmedKey;
    AITextService.setApiKey(trimmedKey); // Update the service
    _saveSettings(); // Save the new key (or empty string if cleared)

    // Provide feedback
    if (trimmedKey.isNotEmpty) {
      Get.snackbar(
        'API Key Saved',
        'Your API key has been updated.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'API Key Cleared',
        'Your API key has been removed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
