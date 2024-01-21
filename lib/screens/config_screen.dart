import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/japanese_text_controller.dart';

class ConfigScreen extends StatelessWidget {
  // Initialize controller
  final JpTextController controller = Get.find();

  String getDifficultyText(double value) {
    if (value >= 0 && value <= 25) {
      return 'Easy';
    } else if (value >= 26 && value <= 50) {
      return 'Normal';
    } else if (value >= 51 && value <= 75) {
      return 'Hard';
    } else {
      return 'Very Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle for Furigana display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Show Furigana:'),
                Obx(() => Switch(
                      value: controller.showFurigana.value,
                      onChanged: (value) => controller.toggleFurigana(value),
                    )),
              ],
            ),
            // Difficulty slider
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Text Difficulty:'),
                    Obx(() => Text(
                          getDifficultyText(controller.difficulty.value),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
                Obx(() => Slider(
                      value: controller.difficulty.value,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: controller.difficulty.value.round().toString(),
                      onChanged: (value) => controller.setDifficulty(value),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
