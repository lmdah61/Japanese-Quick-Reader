import 'dart:async';
import 'dart:math'; // Used for min()

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import for WidgetsBinding
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:japanese_quick_reader/controllers/settings_controller.dart';
import 'package:japanese_quick_reader/models/japanese_text.dart';
import 'package:japanese_quick_reader/services/ai_text_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Constants for storage keys
const String _currentTextKey = 'currentText';
const String _textSizeKey = 'textSize';
const String _splitRatioKey = 'splitRatio';

class HomeController extends GetxController {
  final _box = GetStorage(); // Use final for GetStorage instance

  // --- Observable State ---
  var currentText =
      JapaneseText(
        content: '',
        translation: '',
        jlptLevel:
            'N5', // Default values, will be overwritten by loaded/generated
        topic: 'Random',
      ).obs;
  var isLoading = false.obs; // For text generation
  var selectedWord = ''.obs;
  var dictionaryUrl = ''.obs; // URL for the WebView
  var textSize = 18.0.obs; // Font size for Japanese text display
  var splitRatio = 0.6.obs; // Ratio for splitting text/WebView areas
  var showTranslation = false.obs; // Toggle for showing English translation
  var isWebViewLoading = false.obs; // Loading state for the WebView

  // TODO: Investigate if forceUpdate is truly needed. Often indicates Obx might not be wrapping the right widget or state isn't fully reactive.
  var forceUpdate =
      false
          .obs; // Used to force UI updates, potentially for WebView related changes

  // Computed property for disabling buttons during loading
  bool get areButtonsDisabled => isLoading.value || isWebViewLoading.value;

  // WebView controller instance
  late WebViewController _webViewController;
  // Public getter for the WebView controller
  WebViewController get webViewController => _webViewController;

  // Access SettingsController
  // Ensure SettingsController is put() before this controller is initialized (done in main.dart)
  final SettingsController _settingsController = Get.find<SettingsController>();

  @override
  void onInit() {
    super.onInit();
    _loadState(); // Load persisted state first
    _initWebView();
    // Generate text only if nothing was loaded from storage
    if (currentText.value.content.isEmpty) {
      generateNewText();
    }
    _setupStateSavers(); // Setup listeners to save state changes
    _setupThemeListener(); // Setup listener for theme changes affecting WebView
    // Orientation listener removed - should be handled in UI
  }

  // --- Private Initialization and Setup ---

  void _loadState() {
    // Load JapaneseText
    final savedTextJson = _box.read<Map<String, dynamic>>(_currentTextKey);
    if (savedTextJson != null) {
      try {
        currentText.value = JapaneseText.fromJson(savedTextJson);
      } catch (e) {
        // Log error, keep default empty text
        debugPrint('Error decoding saved text: $e');
        currentText.value = JapaneseText(
          content: '',
          translation: '',
          jlptLevel: 'N5',
          topic: 'Random',
        );
      }
    }

    // Load UI preferences
    textSize.value = _box.read<double>(_textSizeKey) ?? 18.0;
    splitRatio.value = _box.read<double>(_splitRatioKey) ?? 0.6;
  }

  void _setupStateSavers() {
    // Save state changes automatically using GetX's `ever` listener
    ever(
      currentText,
      (_) => _box.write(_currentTextKey, currentText.value.toJson()),
    );
    ever(textSize, (_) => _box.write(_textSizeKey, textSize.value));
    ever(splitRatio, (_) => _box.write(_splitRatioKey, splitRatio.value));
  }

  void _setupThemeListener() {
    // Listen directly to the reactive themeMode from SettingsController
    ever(_settingsController.themeMode, (_) => _applyWebViewTheme());
  }

  void _initWebView() {
    try {
      _webViewController =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (_) => _setWebViewLoading(true),
                onPageFinished: (_) {
                  _setWebViewLoading(false);
                  _applyWebViewTheme(); // Apply theme after page finishes loading
                  _applyJapaneseFontStyles(); // Apply font styles
                },
                onWebResourceError: (WebResourceError error) {
                  debugPrint("WebResourceError: ${error.description}");
                  _setWebViewLoading(false); // Stop loading on error
                  // Optionally show a snackbar or message
                  Get.snackbar(
                    'Dictionary Error',
                    'Failed to load dictionary page. Please check connection.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            );
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      // Handle initialization error, maybe show a message
      Get.snackbar(
        'Error',
        'Could not initialize dictionary view.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Helper to safely update WebView loading state
  void _setWebViewLoading(bool loading) {
    // Use addPostFrameCallback to avoid updating state during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      isWebViewLoading.value = loading;
      // Force update might be needed here if Obx doesn't catch isWebViewLoading change reliably
      // forceUpdate.value = !forceUpdate.value;
    });
  }

  // --- WebView Styling ---

  void _applyJapaneseFontStyles() {
    // Apply custom styles for better Japanese text rendering in WebView
    try {
      _webViewController.runJavaScript('''
        document.querySelectorAll('.japanese').forEach(function(el) {
          el.style.fontFamily = "'Noto Sans JP', 'Hiragino Sans', 'Meiryo', sans-serif";
          el.style.fontSize = "1.1em"; /* Adjust as needed */
          el.style.lineHeight = "1.6"; /* Adjust as needed */
        });
      ''');
    } catch (e) {
      debugPrint('Error applying Japanese font styles: $e');
    }
  }

  void _applyWebViewTheme() {
    // Apply CSS to WebView based on the app's current theme mode
    try {
      final themeMode = _settingsController.themeMode.value;
      final bool isDarkMode =
          themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system && Get.isDarkMode);

      debugPrint('Applying WebView theme: ${isDarkMode ? "dark" : "light"}');

      if (isDarkMode) {
        // Inject dark mode CSS (similar to previous version, hides header/footer)
        _webViewController.runJavaScript(_getDarkModeCss());
      } else {
        // Inject CSS to hide header/footer in light mode
        _webViewController.runJavaScript(_getLightModeCss());
      }
    } catch (e) {
      debugPrint('Error applying WebView theme: $e');
    }
  }

  // Helper function to get Dark Mode CSS string
  String _getDarkModeCss() {
    return '''
      (function() {
        var styleId = 'jqr-theme-styles';
        var existingStyle = document.getElementById(styleId);
        if (existingStyle) existingStyle.remove();

        var style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
          /* Hide Jisho UI elements */
          #logo, .navigation, .logo-container, .nav-container, .logo, nav, .sign-in-out, footer {
            display: none !important;
          }
          /* Dark theme adjustments */
          body { background-color: #1f1f1f !important; color: #e0e0e0 !important; }
          a { color: #78a9ff !important; } a:hover { color: #a5c8ff !important; }
          header, .search-bar, .search-form-wrapper, .search-sidebar { background-color: #2d2d2d !important; border-color: #444 !important; }
          .search-form { background-color: #2d2d2d !important; }
          input, select, button, .search-input, .search-dropdown { background-color: #3d3d3d !important; color: #e0e0e0 !important; border-color: #555 !important; }
          input:focus, select:focus, .search-input:focus { border-color: #78a9ff !important; outline-color: #78a9ff !important; }
          .concept_light { background-color: #2d2d2d !important; border: 1px solid #444 !important; margin-bottom: 1rem !important; border-radius: 4px !important; }
          .concept_light .concept_light-representation { color: #ffffff !important; }
          .concept_light .concept_light-readings { color: #e0e0e0 !important; }
          .concept_light .concept_light-status { color: #bbbbbb !important; }
          .concept_light .concept_light-meanings { background-color: #383838 !important; border-top: 1px solid #444 !important; border-radius: 0 0 4px 4px !important; }
          .concept_light .concept_light-meanings .meaning-tags { color: #a0a0a0 !important; }
          .concept_light .concept_light-meanings .meaning-wrapper { color: #e0e0e0 !important; }
          .concept_light .concept_light-meanings .supplemental_info { color: #bbbbbb !important; }
          .concept_light .concept_light-meanings .sentences { color: #d0d0d0 !important; }
          .concept_light .concept_light-meanings .sentences .sentence { border-color: #555 !important; }
          .concept_light .concept_light-meanings .sentences .english { color: #c0c0c0 !important; }
          .concept_light .concept_light-tag, .label, .badge { background-color: #4d4d4d !important; color: #e0e0e0 !important; border-color: #555 !important; }
          .btn, button { background-color: #3d3d3d !important; color: #e0e0e0 !important; border-color: #555 !important; }
          .btn:hover, button:hover { background-color: #4d4d4d !important; }
          .btn-primary { background-color: #2c5ea9 !important; border-color: #3a6ebd !important; }
          .btn-primary:hover { background-color: #3a6ebd !important; }
          /* Ensure main content area is visible */
          #page_container { padding-top: 10px !important; } /* Adjust padding if needed */
        `;
        document.head.appendChild(style);
      })();
    ''';
  }

  // Helper function to get Light Mode CSS string (just hides UI elements)
  String _getLightModeCss() {
    return '''
      (function() {
        var styleId = 'jqr-theme-styles';
        var existingStyle = document.getElementById(styleId);
        if (existingStyle) existingStyle.remove();

        var style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
          /* Hide Jisho UI elements */
           #logo, .navigation, .logo-container, .nav-container, .logo, nav, .sign-in-out, footer {
            display: none !important;
          }
           /* Ensure main content area is visible */
          #page_container { padding-top: 10px !important; } /* Adjust padding if needed */
        `;
        document.head.appendChild(style);
      })();
    ''';
  }

  // --- Core Functionality ---

  Future<void> generateNewText() async {
    isLoading.value = true;
    try {
      final response = await AITextService.generateText(
        jlptLevel:
            _settingsController.selectedJlptLevel.value, // Use controller value
        topic: _settingsController.selectedTopic.value, // Use controller value
      );

      if (response.content.isNotEmpty) {
        currentText.value = response;
        showTranslation.value = false; // Hide translation for new text
      } else {
        // Handle case where AI returns empty content but no error
        throw Exception('Received empty response from AI service');
      }
    } catch (e) {
      debugPrint('Error generating text: $e');
      // Clear current text on error
      currentText.value = JapaneseText(
        content: '',
        translation: '',
        jlptLevel: _settingsController.selectedJlptLevel.value,
        topic: _settingsController.selectedTopic.value,
      );
      _showErrorSnackbar(e); // Show user-friendly error
    } finally {
      isLoading.value = false;
    }
  }

  void lookupWord(String word) {
    if (word.trim().isEmpty) return;

    try {
      selectedWord.value = word.trim();
      final encodedWord = Uri.encodeComponent(selectedWord.value);
      final url = 'https://jisho.org/search/$encodedWord';
      dictionaryUrl.value = url; // Update URL state if needed elsewhere

      debugPrint('Looking up word: ${selectedWord.value}, URL: $url');

      // Set loading state *before* calling loadRequest
      _setWebViewLoading(true);
      _webViewController.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('Error in lookupWord: $e');
      _setWebViewLoading(false); // Ensure loading is off on error
      Get.snackbar(
        'Dictionary Error',
        'Failed to initiate word lookup.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void translateFullText() {
    showTranslation.value = !showTranslation.value;
  }

  // --- UI Control Methods ---

  void increaseTextSize() {
    if (textSize.value < 30) {
      // Add upper limit
      textSize.value += 2;
    }
  }

  void decreaseTextSize() {
    if (textSize.value > 12) {
      // Add lower limit
      textSize.value -= 2;
    }
  }

  void updateSplitRatio(double ratio) {
    // Add clamping to prevent extreme values
    splitRatio.value = ratio.clamp(0.1, 0.9);
  }

  // --- Error Handling ---

  void _showErrorSnackbar(dynamic e) {
    // Map common error strings/types to user-friendly messages
    final Map<String, Map<String, dynamic>> errorMessages = {
      '401': {
        'title': 'API Key Error',
        'message': 'Invalid Gemini API key. Please update in Settings.',
        'color': Colors.red,
      },
      '429': {
        'title': 'Rate Limit Exceeded',
        'message': 'Gemini API rate limit reached. Try again later.',
        'color': Colors.orange,
      },
      'safety filters triggered': {
        'title': 'Content Filtered',
        'message': 'AI content filtered for safety. Try a different topic.',
        'color': Colors.orange,
      },
      '404': {
        'title': 'API Model Not Found',
        'message': 'Gemini model not available with your key.',
        'color': Colors.red,
      },
      '400': {
        'title': 'API Request Error',
        'message': 'Invalid request to Gemini API. Please try again.',
        'color': Colors.red,
      },
      'does not contain Japanese': {
        'title': 'Generation Error',
        'message': 'AI failed to generate Japanese text. Please try again.',
        'color': Colors.orange,
      },
      'SocketException': {
        'title': 'Network Error',
        'message': 'Check internet connection and try again.',
        'color': Colors.red,
      },
      'Network error': {
        'title': 'Network Error',
        'message': 'Check internet connection and try again.',
        'color': Colors.red,
      },
      'timeout': {
        'title': 'Request Timeout',
        'message': 'Gemini API request timed out. Try again later.',
        'color': Colors.orange,
      },
      'empty response': {
        'title': 'Generation Error',
        'message': 'AI returned empty content. Please try again.',
        'color': Colors.orange,
      },
    };

    String errorString = e.toString().toLowerCase();
    var errorInfo =
        errorMessages.entries
            .firstWhere(
              (entry) => errorString.contains(entry.key.toLowerCase()),
              orElse:
                  () => MapEntry('default', {
                    'title': 'Error',
                    'message': 'Failed to generate text. Please try again.',
                    'color': Colors.red,
                  }),
            )
            .value;

    Get.snackbar(
      errorInfo['title'],
      errorInfo['message'],
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (errorInfo['color'] as Color).withOpacity(0.8),
      colorText: Colors.white,
    );
  }
}
