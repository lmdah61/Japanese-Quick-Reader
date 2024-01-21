import 'package:get/get.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:get_storage/get_storage.dart';

class JpTextController extends GetxController {
  final box = GetStorage();

  // Properties for text, translation, settings, and state
  var japaneseText = ''.obs;
  var cleanJapaneseText = ''.obs;

  var showFurigana = true.obs;

  var difficulty = 50.0.obs;

  var japaneseWord = '単語'.obs;

  var mainTextFontSize = 24.0.obs;
  var rubyTextFontSize = 16.0.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load persisted values on initialization
    japaneseText.value = box.read('japaneseText') ??
        '私[わたし] は 、 日本[にほん] の 言葉[ことば] を 学び[まなび] 、 漢字[かんじ] を 練習しています[れんしゅうしています] 。 新しい[あたらしい] 文化[ぶんか] を 知る[しる] の が 楽しいです[たのしいです] 。 毎日[まいにち] 一つずつ[ひとつずつ] 成長しています[せいちょうしています] 。 ありがとうございます 。';
    showFurigana.value = box.read('showFurigana') ?? true;
    difficulty.value = box.read('difficulty') ?? 50.0;
    cleanTextFromFurigana();
  }

  void generateText() async {
    isLoading.value = true;

    // Set your OpenAI API key
    OpenAI.apiKey = 'YOUR_API_KEY';

    // Define an array of prompts
    var prompts = [
      ''' Write a small random Japanese text about any subject with approximately 30 words. 

Follow these rules to format the text:

1) For expressions that contain kanji, write the hiragana version of the whole expression in square brackets ‘[]’ right after the original expression, without any space in between. For example, '成長しています[せいちょうしています] ’ , '励みになります[はげみになります] 。 ’ , '古い[ふるい] ’ or '幸せ[しあわせ] '. Do not add square brackets to expressions that have no kanji in them. For example, 'ありがとう[ありがとう] ’ is incorrect, it should be just 'ありがとう '. 'に します[にします] 。 ’ is also incorrect, it should be just 'に します 。 '. 'しています[しています] ' is incorrect, it should be just 'しています ' . Expressions like 'もたらします[もたらします] 。 ’ should be just 'もたらします '. Expressions like '挑戦[ちょうせん] しています[しています] ’ or '感動[かんどう] しています[しています] ’ are incorrect, they should be '挑戦しています[ちょうせんしています] ’ and '感動しています[かんどうしています] ’ respectively.

2) Always leave a space after a square bracket that closes an expression, like this: '] ’ or '成長しています[せいちょうしています] '. Do not write any text immediately after a closing square bracket.

3) Do not insert spaces within square brackets, like this: ‘一つずつ[ひとつ ずつ]’. This is incorrect, it should be ‘一つずつ[ひとつずつ]’.

4) Make sure to leave spaces on both sides of any punctuation or particle, like this: ’ 。 ’ and ’ 、 ’ and ’ の '.

5) The text should have a difficulty level of ${difficulty.value} on a scale of 0 to 100, where 0 is the easiest and 100 is the hardest, according to the JLPT standards.

6) Don't write anything but the final text. Do NOT write comments, do NOT print quotation marks ("), do NOT add explanations, extra symbols nor translations. Write everything in the same line.

Adhere to all these rules strictly. Avoid any errors.

Examples:

私[わたし] は 、 日本[にほん] の 言葉[ことば] を 学び[まなび] 、 漢字[かんじ] を 練習しています[れんしゅうしています] 。 新しい[あたらしい] 文化[ぶんか] を 知る[しる] の が 楽しい[たのしい] です 。 毎日[まいにち] 一つずつ[ひとつずつ] 成長しています[せいちょうしています] 。 ありがとうございます 。幸せ[しあわせ] な 毎日[まいにち] です 。 

新聞[しんぶん] の 記事[きじ] を 読んでいます[よんでいます] 。面白[おもしろい] トピック が 沢山[たくさん] あります 。 毎日[まいにち] 一つずつ[ひとつずつ] 学んでいます[まなんでいます] 。友達[ともだち] と 一緒[いっしょ] に 練習しています[れんしゅうしています] 。感謝[かんしゃ] の 気持ち[きもち] が 大切[たいせつ] です 。 

新しい[あたらしい] アート を 鑑賞[かんしょう] しています 。 芸術家[げいじゅつか] の 発想[はっそう] が 魅力的[みりょくてき] です 。 毎日[まいにち] 一つずつ[ひとつずつ] 発見[はっけん] が あります 。 友達[ともだち] と 分かち合う[わかちあう] の が 嬉しい[うれしい] です 。 感謝[かんしゃ] の 心[こころ] を 大切[たいせつ] に します 。 

公園[こうえん] で 花見[はなみ] を 楽しんでいます[たのしんでいます] 。 桜[さくら] の 花[はな] が 綺麗[きれい] です 。 毎年[まいとし] 訪れています[おとずれています] 。 友達[ともだち] と 一緒[いっしょ] に ピクニック を 楽しんでいます[たのしんでいます] 。 自然[しぜん] の 中[なか] で リフレッシュ[りふれっしゅ] しています 。 

友達[ともだち] と 一緒[いっしょ] に 料理[りょうり] を 楽しんでいます[たのしんでいます] 。 新しい[あたらしい] レシピ を 試しています[ためしています] 。 毎日[まいにち] 一つずつ[ひとつずつ] 学び[まなび] ながら 、 美味しい[おいしい] 料理[りょうり] が できるように 頑張っています[がんばっています] 。 ありがとう 、 料理[りょうり] は 楽しい[たのしい] です 。 

新しい[あたらしい] トピック を 話しています[はなしています] 。 意見[いけん] を 交換[こうかん] する の が 面白い[おもしろい] です 。 毎日[まいにち] 一つずつ[ひとつずつ] 知識[ちしき] を 増やしています[ふやしています] 。 友達[ともだち] と 共有[きょうゆう] する の は 有意義[ゆういぎ] です 。 ありがとう 、 学ぶ[まなぶ] の は 楽しい[たのしい] です 。 

友達[ともだち] と 一緒[いっしょ] に 映画[えいが] を 観ています[みています] 。 新作[しんさく] の ドラマ[どらま] も 楽しみ[たのしみ] です 。 毎週[まいしゅう] 一つずつ[ひとつずつ] 話題[わだい] に なります 。感動[かんどう] が 深い[ふかい] 作品[さくひん] が 多い[おおい] です 。 ありがとう 、 映画[えいが] は 魔法[まほう] の ようです 。 

''',
    ];

    String finalText = '';

    // Initialize an empty list to store the conversation history
    List<OpenAIChatCompletionChoiceMessageModel> messages = [];

    for (var prompt in prompts) {
      // Create a user message for each prompt
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
        ],
        role: OpenAIChatMessageRole.user,
      );

      // Add the user message to the conversation history
      messages.add(userMessage);

      // Send the chat request with the full conversation history
      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'gpt-4',
        messages: messages,
      );

      // Create a system message with the response
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              chatCompletion.choices.first.message.content?.first.text ?? ''),
        ],
        role: OpenAIChatMessageRole.system,
      );

      // Add the system message to the conversation history
      messages.add(systemMessage);

      // Get the result of the current prompt
      finalText =
          chatCompletion.choices.first.message.content?.first.text ?? '';

      // Print the prompt and the result
      print('Prompt: $prompt');
      print('Result: $finalText');
    }

    // Store the result of the last prompt in japaneseText.value
    japaneseText.value = finalText;

    // Persist the generated text
    box.write('japaneseText', japaneseText.value);

    cleanTextFromFurigana();

    isLoading.value = false;
  }

  void cleanTextFromFurigana() {
    var regex = RegExp(r'\[.*?\]');
    cleanJapaneseText.value = japaneseText.value.replaceAll(regex, '');
  }

  // Toggle methods for settings
  void toggleFurigana(bool value) {
    showFurigana.value = value;
    // Persist the value
    box.write('showFurigana', value);
  }

  void setDifficulty(double value) {
    difficulty.value = value;
    // Persist the value
    box.write('difficulty', value);
  }

  void fetchWord(String word) {
    japaneseWord.value = word;
    print(word);
  }

  void decreaseFontSize() {
    mainTextFontSize.value -= 2;
    rubyTextFontSize.value -= 2;
    adjustFontSizes();
  }

  void increaseFontSize() {
    mainTextFontSize.value += 2;
    rubyTextFontSize.value += 2;
    adjustFontSizes();
  }

  void adjustFontSizes() {
    if (mainTextFontSize.value < 12) {
      mainTextFontSize.value = 12;
      rubyTextFontSize.value = 10;
    }
    if (mainTextFontSize.value > 40) {
      mainTextFontSize.value = 40;
      rubyTextFontSize.value = 30;
    }
  }
}
