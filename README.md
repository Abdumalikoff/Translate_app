# Ezzy Translate

Flutter translator app using Yandex Cloud Translate API.  
Stores recent translations and favorites locally with Hive.

---

## Features

- Language selection (From / To)
- Swap languages button
- Auto-translate with debounce
- Translation result card
- Recent translations (max 3, smart update logic)
- Favorites (star system)
- Star synchronization between Recent and Favorites
- Translation detail bottom sheet:
  - Separate sections: Original / Translation
  - Copy buttons
  - Star toggle
- Local persistence (Hive)

---

## Screenshots

Preview:

<img src="assets/screenshots/screen1.png" width="500">
<img src="assets/screenshots/screen2.png" width="500">
<img src="assets/screenshots/screen3.png" width="500">


---

## Project Structure

lib/
├── main.dart
├── app_shell.dart
│
├── settings/
│ └── settings_service.dart
│
└── translate/
├── translate_screen.dart
├── yandex_translate_service.dart
├── translation_service.dart
├── translation_models.dart
│
├── models/
│ ├── lang.dart
│ └── translation_history_item.dart
│
├── screens/
│ ├── favorites_screen.dart
│ └── translation_storage.dart
│
└── widgets/
├── card_container_widget.dart
├── recent_translation_card.dart
└── translation_detail_sheet.dart
