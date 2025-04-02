# Japanese Quick Reader

**Japanese Quick Reader** is a Flutter application designed to help users improve their Japanese reading skills through AI-generated texts and integrated dictionary lookups.

## Features

*   **AI-Generated Content:** Generates short Japanese texts tailored to different JLPT levels (N5-N1) on various topics using an AI service.
*   **Interactive Reading:** Displays the Japanese text with clear formatting.
*   **Tap-to-Lookup:** Simply tap any word in the text to instantly look it up in an embedded dictionary view (powered by Jisho.org via WebView).
*   **Resizable Layout:** Adjust the reading pane and dictionary view sizes using a draggable divider.
*   **Text Controls:**
    *   Increase or decrease the text size for comfortable reading.
    *   Show/Hide the English translation of the generated text.
*   **JLPT Level Indicator:** Each text snippet is tagged with its corresponding JLPT level.
*   **Settings:** Configure the AI service (e.g., API key) via the settings screen.
*   **Theme Aware:** Adapts to light and dark modes.

## Screenshots

## How It Works

1.  The app requests a new Japanese text snippet from an AI service (configured in settings), specifying a desired JLPT level and topic.
2.  The generated text, along with its translation, JLPT level, and topic, is displayed in the top panel.
3.  Users can read the text and tap on unfamiliar words.
4.  Tapping a word loads the corresponding Jisho.org dictionary page in the bottom WebView panel.
5.  Users can adjust text size, view translations, or generate new text using the controls on the divider.

## Getting Started

This is a standard Flutter project.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/japanese_quick_reader.git
    cd japanese_quick_reader
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure AI Service:**
    *   Navigate to the Settings screen within the app.
    *   Enter your API key for the AI text generation service.
4.  **Run the app:**
    ```bash
    flutter run
    ```
<sub>**Leave a Tip:** opulentmenu06@walletofsatoshi.com</sub>
