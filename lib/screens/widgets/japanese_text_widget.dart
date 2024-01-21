import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_text_touch/ruby_text_touch.dart';
import '../../controllers/dictionary_controller.dart';
import '../../controllers/japanese_text_controller.dart';

class JapaneseRubyText extends StatelessWidget {
  final JpTextController controller = Get.find();
  final DictionaryWidgetController dicController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Obx(
        () => AbsorbPointer(
          absorbing: controller.isLoading.value,
          child: Stack(
            children: [
              Opacity(
                opacity: controller.isLoading.value ? 0.5 : 1,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          children: controller.japaneseText.value
                              .split(' ')
                              .map(_parseWord)
                              .toList()
                              .map(
                                (wordData) => GestureDetector(
                                  onTap: () {
                                    controller.fetchWord(wordData.text);
                                    dicController.loadDictionaryWord();
                                  },
                                  child: RubyText(
                                    [wordData],
                                    textDirection: TextDirection.ltr,
                                    spacing: 5.0,
                                    style: TextStyle(
                                        fontSize:
                                            controller.mainTextFontSize.value),
                                    rubyStyle: TextStyle(
                                        fontSize:
                                            controller.rubyTextFontSize.value,
                                        color: controller.showFurigana.value
                                            ? Colors.red
                                            : Colors.transparent),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: controller.decreaseFontSize,
                            icon: Icon(Icons.remove),
                          ),
                          IconButton(
                            onPressed: controller.increaseFontSize,
                            icon: Icon(Icons.add),
                          ),
                          IconButton(
                            onPressed: () {
                              dicController.loadTranslation();
                            },
                            icon: Icon(Icons.translate),
                          ),
                          IconButton(
                            onPressed: () {
                              controller.generateText();
                            },
                            icon: Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.value)
                Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  RubyTextData _parseWord(String word) {
    final parts = word.split('[');
    final mainText = parts.first;
    final ruby = parts.length > 1 ? parts[1].replaceAll(']', '') : '';
    return RubyTextData(mainText, ruby: ruby);
  }
}
