import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:japanese_quick_reader/controllers/home_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japanese Quick Reader'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.toNamed('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Split screen with resizable panels
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;

                return Obx(() {
                  final splitPosition = height * controller.splitRatio.value;
                  final dividerHeight = 40.0; // Increased height

                  return Stack(
                    children: [
                      // Upper panel - Japanese text
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: splitPosition - dividerHeight / 2,
                        child: _buildJapaneseTextPanel(),
                      ),

                      // Draggable divider
                      Positioned(
                        top: splitPosition - dividerHeight / 2,
                        left: 0,
                        right: 0,
                        height: dividerHeight,
                        child: _buildDivider(height),
                      ),

                      // Lower panel - Dictionary
                      Positioned(
                        top: splitPosition + dividerHeight / 2,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildDictionaryPanel(),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Japanese text panel
  Widget _buildJapaneseTextPanel() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Check if there's no content (error state)
      if (controller.currentText.value.content.isEmpty) {
        return Builder(
          builder: (context) {
            // Get theme-aware colors for error state
            final errorColor =
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.red[300]
                    : Colors.red[300];

            final subtitleColor =
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600];

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: errorColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to generate text',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your API key or try again',
                    style: TextStyle(color: subtitleColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.generateNewText(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          },
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JLPT level and topic indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getJlptLevelColor(
                        controller.currentText.value.jlptLevel,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      controller.currentText.value.jlptLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      // Get theme-aware color for topic text
                      final topicColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[600];

                      return Text(
                        controller.currentText.value.topic,
                        style: TextStyle(color: topicColor),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Japanese text with tappable words
              Obx(
                () => _buildTappableText(
                  controller.currentText.value.content,
                  controller.textSize.value,
                ),
              ),

              // Translation (shown only when translation button is pressed)
              Obx(() {
                if (controller.showTranslation.value) {
                  return Builder(
                    builder: (context) {
                      // Get theme-aware color for translation text
                      final translationColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Obx(
                            () => Text(
                              controller.currentText.value.translation,
                              style: TextStyle(
                                fontSize: controller.textSize.value,
                                fontStyle: FontStyle.italic,
                                color: translationColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      );
    });
  }

  // Build tappable text with word detection
  Widget _buildTappableText(String text, double fontSize) {
    // Split text into words using a more sophisticated approach for Japanese text
    final List<String> words = [];
    String currentWord = '';

    // Improved regex for Japanese text segmentation
    final RegExp punctuation = RegExp(r'[\s。、！？．，：；「」『』（）［］【】〈〉《》〔〕・…―]');
    final RegExp particles = RegExp(r'[はがをにへでとやからまでよりなのには]');

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Handle punctuation
      if (punctuation.hasMatch(char)) {
        if (currentWord.isNotEmpty) {
          words.add(currentWord);
          currentWord = '';
        }
        words.add(char);
        continue;
      }

      // Add character to current word
      currentWord += char;

      // Check if we should split here (end of current word)
      if (i < text.length - 1) {
        final nextChar = text[i + 1];

        // Split before particles
        if (particles.hasMatch(nextChar)) {
          words.add(currentWord);
          currentWord = '';
          continue;
        }

        // Split between kanji and kana
        final isCurrentKanji = RegExp(r'[\u4E00-\u9FAF]').hasMatch(char);
        final isNextKanji = RegExp(r'[\u4E00-\u9FAF]').hasMatch(nextChar);
        final isCurrentKana = RegExp(
          r'[\u3040-\u309F\u30A0-\u30FF]',
        ).hasMatch(char);
        final isNextKana = RegExp(
          r'[\u3040-\u309F\u30A0-\u30FF]',
        ).hasMatch(nextChar);

        // Split between kanji and kana transitions
        if ((isCurrentKanji && isNextKana) || (isCurrentKana && isNextKanji)) {
          words.add(currentWord);
          currentWord = '';
        }
      }
    }

    // Add the last word if it exists
    if (currentWord.isNotEmpty) {
      words.add(currentWord);
    }

    return Builder(
      builder: (context) {
        // Get the current text color from the theme
        final textColor =
            Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

        return RichText(
          text: TextSpan(
            style: GoogleFonts.notoSans(
              fontSize: fontSize,
              height: 1.8,
              fontWeight: FontWeight.w400,
              color: textColor, // Use theme-aware text color
            ),
            children:
                words.map((word) {
                  if (word.isEmpty) return const TextSpan(text: '');

                  // Only make actual words tappable, not particles or punctuation
                  if (punctuation.hasMatch(word) ||
                      word.length == 1 && particles.hasMatch(word)) {
                    return TextSpan(text: word);
                  }

                  return TextSpan(
                    text: word,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).colorScheme.primary
                          .withOpacity(0.3), // Use theme primary color
                    ),
                    recognizer:
                        TapGestureRecognizer()
                          ..onTap = () {
                            controller.lookupWord(word);
                          },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // Middle divider with controls
  Widget _buildDivider(double height) {
    return Builder(
      builder: (context) {
        // Get theme-aware colors
        final dividerColor =
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200];

        final handleColor =
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]
                : Colors.grey[400];

        final shadowColor =
            Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1);

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            // Disable dragging when loading
            if (controller.areButtonsDisabled) return;

            final newRatio = (controller.splitRatio.value +
                    details.delta.dy / height)
                .clamp(0.3, 0.7); // Limit the range
            controller.updateSplitRatio(newRatio);
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(
                        0xFF2a2a2a,
                      ) // Jisho.org dark theme background
                      : Colors.white, // Jisho.org light theme background
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor, // Use theme-aware shadow
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              // Added Padding
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ), // Added Padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Text size decrease button
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      size: 20,
                    ), // Changed icon size
                    onPressed:
                        controller.areButtonsDisabled
                            ? null
                            : controller.decreaseTextSize,
                    tooltip: 'Decrease text size',
                  ),

                  // Text size increase button
                  IconButton(
                    icon: const Icon(Icons.add, size: 20), // Changed icon size
                    onPressed:
                        controller.areButtonsDisabled
                            ? null
                            : controller.increaseTextSize,
                    tooltip: 'Increase text size',
                  ),

                  // Drag handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: handleColor, // Use theme-aware color
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // Reload button
                  IconButton(
                    icon: const Icon(
                      Icons.replay,
                      size: 20,
                    ), // Changed icon size
                    onPressed:
                        controller.areButtonsDisabled
                            ? null
                            : controller.generateNewText,
                    tooltip: 'Generate new text',
                  ),

                  // Translation button
                  IconButton(
                    icon: const Icon(
                      Icons.language,
                      size: 20,
                    ), // Changed icon size
                    onPressed:
                        controller.areButtonsDisabled
                            ? null
                            : controller.translateFullText,
                    tooltip: 'Show/hide translation',
                  ),
                ],
              ),
            ), // Closing Padding
          ),
        );
      },
    );
  }

  // Dictionary panel
  Widget _buildDictionaryPanel() {
    return Obx(() {
      // Read forceUpdate to ensure Obx rebuilds when it changes
      final _ = controller.forceUpdate.value;

      if (controller.selectedWord.isEmpty) {
        // Apply specific background color for the placeholder
        return Builder(
          builder: (context) {
            // Use Builder to get context for Theme
            return Container(
              // Set background color based on theme
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A) // Dark mode color
                      : Colors.white, // Light mode color (matching divider)
              child: Center(
                // Center the content within the Container
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 48,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                    ), // Theme-aware icon color
                    const SizedBox(height: 16),
                    Text(
                      'Tap any word in the text to look it up',
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ), // Theme-aware text color
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isLoading = controller.isWebViewLoading.value;

          return Stack(
            children: [
              // Apply blur effect when loading
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: isLoading ? 8.0 : 0.0, // Increased blur intensity
                  sigmaY: isLoading ? 8.0 : 0.0, // Increased blur intensity
                ),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  // Absorb pointer events while blurred to prevent interaction
                  child: AbsorbPointer(
                    absorbing: isLoading,
                    child: Builder(
                      builder: (context) {
                        try {
                          return WebViewWidget(
                            controller: controller.webViewController,
                          );
                        } catch (e) {
                          print('Error rendering WebView: $e');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading dictionary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.lookupWord(
                                      controller.selectedWord.value,
                                    );
                                  },
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              // Loading indicator remains on top
              if (isLoading) const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      );
    });
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
