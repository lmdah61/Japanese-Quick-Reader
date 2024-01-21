import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:japanese_quick_reader/screens/widgets/dictionary_widget.dart';
import 'package:japanese_quick_reader/screens/widgets/japanese_text_widget.dart';
import 'config_screen.dart';

class MainScreen extends StatelessWidget {
  final RxDouble dividerPosition = 0.5.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Japanese Quick Reader'),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => ConfigScreen()),
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Obx(
        () => Column(
          children: [
            Expanded(
              flex: (dividerPosition.value * 100).toInt(),
              child: Container(
                child: Center(
                  child: JapaneseRubyText(),
                ),
              ),
            ),
            GestureDetector(
              onVerticalDragUpdate: (details) {
                dividerPosition.value +=
                    details.primaryDelta! / context.size!.height;
                dividerPosition.value = dividerPosition.value.clamp(0.2, 0.8);
              },
              child: const Align(
                alignment: Alignment.center,
                child: Divider(
                  thickness: 7,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              flex: ((1 - dividerPosition.value) * 100).toInt(),
              child: Container(
                child: Center(
                  child: DictionaryWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
