import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:japanese_quick_reader/models/japanese_text.dart';

class AITextService {
  // User's custom API key - No default key anymore
  static String _customApiKey = '';

  // Method to set the API key
  static void setApiKey(String apiKey) {
    _customApiKey = apiKey;
    print(
      'Custom API key set in AITextService: ${apiKey.isEmpty ? "empty" : "${apiKey.substring(0, min(5, apiKey.length))}..."}',
    );
  }

  // Get the active API key (only returns the custom key now)
  static String get activeApiKey {
    // Always return the custom key, even if empty. Validation happens in generateText.
    print(
      '>>> AITextService: Providing API key ($_customApiKey)',
    ); // Log the key being provided
    return _customApiKey;
  }

  // Generate Japanese text using Gemini API
  static Future<JapaneseText> generateText({
    required String jlptLevel,
    required String topic,
  }) async {
    print(
      'AITextService.generateText called with level: $jlptLevel, topic: $topic',
    );
    // Directly check the custom API key
    if (_customApiKey.isEmpty) {
      throw Exception(
        'API key is missing. Please add your Gemini API key in the settings.',
      );
    }

    // Use the custom key directly for length check
    if (_customApiKey.length < 10) {
      throw Exception(
        'API key is too short. Please check your Gemini API key in the settings.',
      );
    }

    // Log the key being used (same as activeApiKey getter)
    print(
      'Using API key: ${_customApiKey.substring(0, min(5, _customApiKey.length))}...',
    );

    // Directly call the API using the custom key and let errors propagate
    return await _generateWithGemini(jlptLevel, topic);
  }

  // Try to generate text using Gemini API
  static Future<JapaneseText> _generateWithGemini(
    String jlptLevel,
    String topic,
  ) async {
    // Create a more varied prompt based on JLPT level and topic
    String promptTopic = topic;

    // For "Random" topic, select a random scenario to increase variety
    if (topic == 'Random') {
      final randomScenarios = [
        'a surprising encounter',
        'an unexpected discovery',
        'a memorable dream',
        'a childhood memory',
        'a future aspiration',
        'a strange coincidence',
        'a seasonal change',
        'a local festival',
        'a personal challenge',
        'a funny misunderstanding',
        'a cultural difference',
        'a new hobby',
        'a travel experience',
        'a favorite place',
        'a special person',
      ];

      // Select a random scenario
      final random = Random();
      promptTopic = randomScenarios[random.nextInt(randomScenarios.length)];
      print('Random topic selected: $promptTopic');
    }

    final prompt = '''
    You are a creative Japanese language teacher. Create a unique and interesting short Japanese text (2-3 phrases) about ${promptTopic.toLowerCase()} 
    that would be appropriate for students at JLPT $jlptLevel level.
    
    Make this text different from standard examples. Include some interesting cultural context or a surprising element if possible.
    
    The text should use vocabulary and grammar appropriate for $jlptLevel level students, but try to be creative and varied in your expression.
    
    IMPORTANT RULES:
    - DO NOT include any emojis or special symbols in the text
    - DO NOT include furigana or reading aids in parentheses
    - Use only standard Japanese characters (hiragana, katakana, and kanji)
    - Keep the text clean and consistent
    - Use proper Japanese punctuation
    
    Respond in this exact format:
    Japanese: [your Japanese text here]
    English: [English translation here]
    ''';

    print(
      'Calling Gemini API for text generation with prompt: ${prompt.substring(0, min(100, prompt.length))}...',
    );

    try {
      // Updated to use gemini-2.0-flash model
      final url =
          'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$activeApiKey';
      print('API URL: ${url.substring(0, url.indexOf('?') + 10)}...');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature':
                    0.7, // Higher temperature for more creative and varied output
                'maxOutputTokens': 500,
                'topP': 0.9,
                'topK': 40,
              },
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
                {
                  'category': 'HARM_CATEGORY_HATE_SPEECH',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
                {
                  'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('API request timed out after 15 seconds');
              throw Exception(
                'Request timeout: The API request took too long to complete.',
              );
            },
          );

      print('API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
          'API response body: ${response.body.substring(0, min(200, response.body.length))}...',
        );
        final data = jsonDecode(response.body);

        if (data.containsKey('candidates') &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0].containsKey('content') &&
            data['candidates'][0]['content'].containsKey('parts') &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final content =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          print(
            'Extracted content: ${content.substring(0, min(100, content.length))}...',
          );

          final parsedResponse = _parseResponse(content, jlptLevel, topic);
          print(
            'Parsed response - Japanese: ${parsedResponse.content.substring(0, min(50, parsedResponse.content.length))}...',
          );
          print(
            'Parsed response - English: ${parsedResponse.translation.substring(0, min(50, parsedResponse.translation.length))}...',
          );

          // Verify that the response contains Japanese characters
          if (!_containsJapanese(parsedResponse.content)) {
            print('No Japanese characters found in response');
            throw Exception(
              'Generated text does not contain Japanese characters.',
            );
          }

          return parsedResponse;
        }

        print('Unexpected API response format');
        throw Exception('Unexpected API response format');
      } else if (response.statusCode == 404) {
        print('API endpoint not found. Response body: ${response.body}');
        throw Exception(
          'API endpoint not found (404): The Gemini model is not available with your API key.',
        );
      } else if (response.statusCode == 400) {
        print('Bad request. Response body: ${response.body}');
        // More detailed error handling for 400 errors
        if (response.body.contains('safety')) {
          throw Exception('Content safety filters triggered.');
        } else {
          throw Exception('Bad request (400): The API request was invalid.');
        }
      } else if (response.statusCode == 401) {
        print('Authentication failed. Response body: ${response.body}');
        throw Exception('Authentication failed (401): Invalid API key.');
      } else if (response.statusCode == 429) {
        print('Rate limit exceeded. Response body: ${response.body}');
        throw Exception(
          'Rate limit exceeded (429): You have sent too many requests in a short period of time.',
        );
      } else {
        print(
          'API error. Status code: ${response.statusCode}, Response body: ${response.body}',
        );
        throw Exception(
          'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception during API call: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  // Parse the generated text into Japanese and English parts
  static JapaneseText _parseResponse(
    String generatedText,
    String jlptLevel,
    String topic,
  ) {
    // Improved parsing for Gemini responses
    String japaneseText = '';
    String englishTranslation = '';

    // Look for Japanese: and English: patterns
    final japaneseMatch = RegExp(
      r'Japanese:\s*(.+?)(?=English:|$)',
      dotAll: true,
    ).firstMatch(generatedText);
    final englishMatch = RegExp(
      r'English:\s*(.+?)$',
      dotAll: true,
    ).firstMatch(generatedText);

    if (japaneseMatch != null) {
      japaneseText = japaneseMatch.group(1)?.trim() ?? '';
    }

    if (englishMatch != null) {
      englishTranslation = englishMatch.group(1)?.trim() ?? '';
    }

    // If the above patterns didn't work, try splitting by newlines
    if (japaneseText.isEmpty || englishTranslation.isEmpty) {
      final parts = generatedText.split(RegExp(r'\n\n|\nEnglish:|\n英語:'));

      if (parts.length >= 2) {
        japaneseText = parts[0].replaceAll('Japanese:', '').trim();
        englishTranslation = parts[1].trim();
      } else {
        // If we can't clearly separate, use the whole text as Japanese
        japaneseText = generatedText.trim();
        englishTranslation = 'Translation not available';
      }
    }

    // Ensure the text isn't too long
    if (japaneseText.length > 200) {
      japaneseText = '${japaneseText.substring(0, 200)}...';
    }

    if (englishTranslation.length > 300) {
      englishTranslation = '${englishTranslation.substring(0, 300)}...';
    }

    // If we couldn't extract any Japanese text, throw an error
    if (japaneseText.isEmpty) {
      throw Exception('Failed to extract Japanese text from API response.');
    }

    return JapaneseText(
      content: japaneseText,
      translation: englishTranslation,
      jlptLevel: jlptLevel,
      topic: topic,
    );
  }

  // Check if text contains Japanese characters
  static bool _containsJapanese(String text) {
    // Check for hiragana, katakana, or kanji
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
}
