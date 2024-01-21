import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'japanese_text_controller.dart';

class DictionaryWidgetController extends GetxController {
  final JpTextController txtController = Get.find();
  final WebViewController webviewController = WebViewController();

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDictionaryWord();
  }

  void loadDictionaryWord() {
    isLoading.value = true;
    String selectedUrl =
        'https://jisho.org/search/${txtController.japaneseWord.value}';
    webviewController.loadRequest(Uri.parse(selectedUrl));
    webviewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webviewController.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          isLoading.value = false;
        },
      ),
    ); // Enable JavaScript
    //isLoading.value = false;
  }

  void loadTranslation() {
    isLoading.value = true;
    String selectedUrl =
        'https://www.deepl.com/en/translator#ja/en/${txtController.cleanJapaneseText.value}';
    webviewController.loadRequest(Uri.parse(selectedUrl));
    webviewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webviewController.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          isLoading.value = false;
        },
      ),
    ); // Enable JavaScript// Enable JavaScript
    //isLoading.value = false;
  }
}
