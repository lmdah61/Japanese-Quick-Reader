import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controllers/dictionary_controller.dart';

class DictionaryWidget extends StatelessWidget {
  final DictionaryWidgetController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AbsorbPointer(
        absorbing: controller.isLoading.value,
        child: Stack(
          children: [
            if (controller.isLoading.value)
              Center(child: CircularProgressIndicator()),
            Opacity(
              opacity: controller.isLoading.value ? 0.5 : 1.0,
              // Change opacity based on loading state
              child: WebViewWidget(
                controller: controller.webviewController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
