# ⚡️ Blink

Save your text, images, files and links into **boards**, then paste them into any app through Blink's **custom iOS keyboard**. Everything syncs with iCloud through CloudKit.

<p align="center">
  <img src="https://codingreema.github.io/assets/Keyboard.webp" alt="Blink custom keyboard on iPhone" width="320">
</p>

## Features

- Organize content into boards
- Save four kinds of content: text, images, files (with PDF preview) and links
- A custom keyboard extension that shows your saved items, so you can copy any of them into the app you're typing in
- iCloud sync and storage with CloudKit, plus delete support

## Tech stack

- **SwiftUI**, structured with MVVM (`ViewModel/`, `Model/`, `View/`)
- **CloudKit**: `CKRecord`-based models, with references linking items to their board
- **Keyboard Extension** (`UIInputViewController`) hosting a SwiftUI view
- **PDFKit** for file previews
- `UIPasteboard` to hand content from the keyboard to other apps

## Project structure

```
NewBlink/
├── NewBlink/          # Main app
│   ├── Model/         # BoardModel, multimedia model (CloudKit records)
│   ├── ViewModel/     # BoardViewModel, MultimediaViewModel
│   ├── View/          # Boards, board detail
│   └── MediaSheet/    # Add text, link and file sheets, delete
└── KeyExtension/      # Custom keyboard (KeyboardViewController + KeyView)
```

## Run it

1. Open `NewBlink/NewBlink.xcodeproj` in Xcode.
2. Set your own Team and iCloud container under *Signing & Capabilities*.
3. Run on a device, then enable the keyboard in **Settings → General → Keyboard → Keyboards → Add New Keyboard**.

## Author

**Rimah Aldaghfaq**: [Portfolio](https://codingreema.github.io) · [LinkedIn](https://www.linkedin.com/in/rimahaldaghfaq)
