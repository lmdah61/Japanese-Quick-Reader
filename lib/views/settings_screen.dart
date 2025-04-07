import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:japanese_quick_reader/controllers/settings_controller.dart';
import 'package:japanese_quick_reader/controllers/home_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());
  final HomeController homeController = Get.find<HomeController>();
  final TextEditingController apiKeyController = TextEditingController();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize API key text field with current value from settings
    apiKeyController.text = controller.apiKey.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // API Key Configuration
          _buildSection(
            title: 'Gemini API Key',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your Google Gemini API key to enable AI-generated Japanese text. If left empty, the app will use built-in examples.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'API Key',
                    hintText: 'AIzaSyA...',
                    helperText: 'Get your API key from makersuite.google.com',
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    controller.updateApiKey(value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Removed async
                        // Use the controller's method which already sets the API key in AITextService
                        controller.updateApiKey(
                          apiKeyController.text,
                        ); // Removed await
                        // No need to call AITextService.setApiKey again as it's done in the controller
                      },
                      child: const Text('Save API Key'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Removed async
                        apiKeyController.clear();
                        // Use the controller's method which already sets the API key in AITextService
                        controller.updateApiKey(''); // Removed await
                        // No need to call AITextService.setApiKey again as it's done in the controller
                        Get.snackbar(
                          'Info',
                          'API key cleared. Using built-in examples.',
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // JLPT Level Selection
          _buildSection(
            title: 'JLPT Level',
            child: Wrap(
              spacing: 8,
              children:
                  controller.jlptLevels
                      .map((level) => _buildJlptChip(level))
                      .toList(),
            ),
          ),

          // Topic Selection
          _buildSection(
            title: 'Topics',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              children:
                  controller.topics
                      .map((topic) => _buildTopicChip(topic))
                      .toList(),
            ),
          ),

          // Theme Selection section removed

          // Premium section removed

          // Apply Settings Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              child: const Text(
                'Apply Settings & Generate New Text',
              ), // Clarify button action
              onPressed: () {
                // Settings are already saved reactively by SettingsController.
                // HomeController reads the latest settings when generateNewText is called.
                // No need to manually update HomeController state here.

                // No need to set API key here as it's already set when the user saves it in SettingsController

                // Generate new text with updated settings
                homeController.generateNewText();

                // Go back to home screen
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a section with title and child
  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // Helper method to build JLPT level chip
  Widget _buildJlptChip(String level) {
    return Obx(
      () => FilterChip(
        label: Text(level),
        selected: controller.selectedJlptLevel.value == level,
        onSelected: (selected) {
          if (selected) {
            controller.updateJlptLevel(level);
          }
        },
        backgroundColor: _getJlptLevelColor(level).withOpacity(0.2),
        selectedColor: _getJlptLevelColor(level),
        labelStyle: TextStyle(
          color:
              controller.selectedJlptLevel.value == level
                  ? Colors.white
                  : _getJlptLevelColor(level),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method to build topic chip
  Widget _buildTopicChip(String topic) {
    return Builder(
      builder: (context) {
        // Get theme-aware colors
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        final backgroundColor =
            isDarkMode
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surface;

        final selectedColor = Theme.of(context).colorScheme.primary;

        final textColor =
            isDarkMode
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface;

        final selectedTextColor = Theme.of(context).colorScheme.onPrimary;

        return Obx(
          () => FilterChip(
            label: Text(topic),
            selected: controller.selectedTopic.value == topic,
            onSelected: (selected) {
              if (selected) {
                controller.updateTopic(topic);
              }
            },
            backgroundColor: backgroundColor,
            selectedColor: selectedColor,
            labelStyle: TextStyle(
              color:
                  controller.selectedTopic.value == topic
                      ? selectedTextColor
                      : textColor,
              fontWeight:
                  controller.selectedTopic.value == topic
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    controller.selectedTopic.value == topic
                        ? selectedColor
                        : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      },
    );
  }

  // Helper method to get color based on JLPT level
  Color _getJlptLevelColor(String level) {
    switch (level) {
      case 'N5':
        return Colors.blue;
      case 'N4':
        return Colors.green;
      case 'N3':
        return Colors.orange;
      case 'N2':
        return Colors.purple;
      case 'N1':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
