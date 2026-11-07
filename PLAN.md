# 100% On-Device Flutter Mobile App Architecture Plan (InstaLens Mobile)

## 1. Executive Summary & Vision

**InstaLens Mobile** (`insta_lens_mobile`) is an entirely **standalone, 100% on-device** mobile application for iOS and Android. It requires **zero external backend microservices or server infrastructure**. Every stage of content extraction—Instagram metadata retrieval, media caching, on-device OCR text scanning, regex link parsing, deduplication, and AI summary generation—runs locally on the user's mobile device hardware.

The existing web app backend (`backend.py`, `index.html`) remains in the repository as an independent web deployment artifact, completely decoupled from the mobile app.

---

## 2. 100% On-Device Architecture Blueprint

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                           InstaLens Mobile App (Flutter)                          │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │ User Interface Layer (InstaLens Dynamic Dark M3 - Stitch Designs)           │  │
│  │  - URL Input Card with Clipboard Paste & Validation                         │  │
│  │  - Segmented Mode Control (Reels/Videos, Single Posts, Creator Profiles)    │  │
│  │  - Live 5-Stage Animated Stepper & Glowing Progress Ring                    │  │
│  │  - Categorized Extracted Links (OCR Video vs Caption) + 1-Tap Copy          │  │
│  │  - Expandable Raw OCR Snippets, Transcripts & Caption Accordions            │  │
│  └──────────────────────────────────────┬──────────────────────────────────────┘  │
│                                         │                                         │
│  ┌──────────────────────────────────────▼──────────────────────────────────────┐  │
│  │ On-Device Extraction Coordinator (Pure Client-Side Orchestration)           │  │
│  └──────┬────────────────────┬────────────────────┬────────────────────┬───────┘  │
│         │                    │                    │                    │          │
│  ┌──────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐   │
│  │ Stage 1     │      │ Stage 2     │      │ Stage 3     │      │ Stage 4 & 5 │   │
│  │ Instagram   │      │ Media &     │      │ Google      │      │ Dart Regex  │   │
│  │ Direct      │      │ Frame       │      │ ML Kit      │      │ Link Engine │   │
│  │ Scraper     │      │ Cache       │      │ On-Device   │      │ & Extractive│   │
│  │ oEmbed & OG │      │ Local Temp  │      │ Vision OCR  │      │ AI Summary  │   │
│  │ metadata    │      │ Storage     │      │ Latin script│      │ Heuristics  │   │
│  └─────────────┘      └─────────────┘      └─────────────┘      └─────────────┘   │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │ Local Device Persistence Layer (SharedPreferences / Local Cache)            │  │
│  │  - Offline Extractions History (Titles, Authors, Extracted Links, Timestamps)│
│  │  - App Preferences & History Management                                     │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. On-Device Pipeline Breakdown

Every extraction pipeline stage executes locally on the mobile device:

### Stage 1: Direct Client-Side Instagram Metadata Scraper
- **Input**: Public Instagram URL (`instagram.com/reel/...`, `instagram.com/p/...`, `instagram.com/username`).
- **Shortcode Parsing**: Extracted via high-performance Dart RegExp matching.
- **Direct Web & oEmbed Fetching**:
  - Connects directly from the mobile client to Instagram's public endpoints (`https://api.instagram.com/oembed/` and OpenGraph meta tags).
  - Uses native mobile HTTP clients with browser user-agent spoofing.
  - Retrieves author display name, post title, caption text, media type, and high-resolution thumbnail/video CDN streams.
- **Fail-Safe & Diagnostics**: If a post is private or age-gated, diagnoses the `403 / Login Wall` condition locally and presents actionable troubleshooting guidance without crashing.

### Stage 2: Local Media & Frame Ingestion
- Media assets and preview frames are streamed directly to the device's sandbox temporary directory (`path_provider`).
- Zero remote servers sit between the mobile device and Instagram CDN.
- Temporary files are automatically managed to avoid storage bloat.

### Stage 3: On-Device Vision OCR (Google ML Kit)
- **Engine**: `google_mlkit_text_recognition` utilizing native Google ML Kit binaries for Android and iOS.
- **Execution**: Runs directly on the device CPU/GPU/NPU hardware without sending any imagery to cloud APIs.
- **Capability**:
  - Scans image frames, carousel slides, and video stills for on-screen text.
  - Identifies embedded URLs, affiliate handles, discount codes, and domain patterns.
  - Generates structured OCR snippets with confidence scores and timestamp estimations.

### Stage 4: On-Device Regex Link Extraction & Deduplication
- **Engine**: Pure Dart implementation matching `backend.py`'s regular expressions:
  ```dart
  RegExp(
    r'(?<!@)(?:https?://|www\.)[^\s<>"{}|\\^`\[\]]+|'
    r'(?<!@)\b(?:[a-zA-Z0-9-]+\.)+(?:com|io|ai|dev|org|net|co|app|me|ly|gg|sh|xyz|ee|tv|so|link|notion|substack|gumroad|patreon|etsy|shopify|spotify|soundcloud|bandcamp|vimeo|dailymotion|loom|streamable|clips|cdn|store)(?:/[^\s<>"{}|\\^`\[\]]*)?\b',
    caseSensitive: false,
  );
  ```
- **Categorization**:
  - `video_ocr`: Links extracted from on-screen frames via ML Kit.
  - `caption`: Links extracted from the post description and creator bio.
  - `transcript`: Spoken URLs or voice transcript references.
- **Canonical Normalization & Deduplication**:
  - Strips trailing punctuation (`.,;:!?)/`).
  - Drops redundant `www.` prefixes and lowercases domains so `https://example.com/` and `http://www.Example.com` are recognized as the same link.

### Stage 5: On-Device Extractive AI Summarizer
- Cleans hashtag clusters, emoji spam, and promotional boilerplates from captions.
- Analyzes sentence importance, leading narrative hooks, and structured bullets.
- Synthesizes a clean **TL;DR** executive summary and **Key Highlights** list locally on the device in < 50ms.

---

## 4. UI Design Reference (Google Stitch Designs)

The UI faithfully reflects the **InstaLens Dynamic Dark M3** design system generated via Stitch MCP (Project ID: `4200957771671621522`):
- **Theme Palette**: Dark slate surface (`#111317`), Vibrant rose-magenta (`#E1306C`), Electric orchid-purple (`#833AB4`), Warm solar amber (`#F77737`).
- **Screen 1 — Home / Input Screen** ([screen_1_home.png](file:///Users/sivanesandharumadurai/Projects/insta_reel_extractor_app/stitch/screens/screen_1_home.png)): Mode segmented control, URL card with paste chip, gradient CTA button, recent extractions.
- **Screen 2 — Results Screen** ([screen_2_results.png](file:///Users/sivanesandharumadurai/Projects/insta_reel_extractor_app/stitch/screens/screen_2_results.png)): Summary hero card, duration, TL;DR, key points, separated OCR Video vs Caption links with 1-tap copy, expandable accordions.
- **Screen 3 — Live Progress Stepper** ([screen_3_loading.png](file:///Users/sivanesandharumadurai/Projects/insta_reel_extractor_app/stitch/screens/screen_3_loading.png)): Glowing animated progress ring, 5-stage on-device pipeline stepper, tip card, cancel button.
- **Screen 4 — Error & Diagnostics Screen** ([screen_4_error.png](file:///Users/sivanesandharumadurai/Projects/insta_reel_extractor_app/stitch/screens/screen_4_error.png)): 403 / Private post diagnostic box, troubleshooting checklist, retry actions.

---

## 5. Code Architecture & File Layout

All mobile code resides in `mobile/`:

```
mobile/
├── pubspec.yaml                          # Dependencies (google_mlkit, provider, http, etc.)
├── android/app/src/main/AndroidManifest.xml # Permissions (INTERNET)
└── lib/
    ├── main.dart                         # Entry point, MultiProvider & Theme
    ├── models/
    │   ├── extraction_result.dart        # Unified typed models: ExtractedLink, ExtractionResult, etc.
    │   └── progress_event.dart           # On-device 5-stage progress event model
    ├── services/
    │   ├── instagram_scraper_service.dart # On-device HTTP scraping, regex & extractive summarizer
    │   ├── ocr_service.dart              # Google ML Kit on-device Vision OCR
    │   └── extraction_coordinator.dart   # 100% on-device pipeline orchestrator
    ├── providers/
    │   └── extraction_provider.dart      # Reactive state management & history persistence
    ├── theme/
    │   └── app_theme.dart                # InstaLens Dynamic Dark M3 tokens
    ├── widgets/
    │   ├── gradient_button.dart          # Gradient pill CTA
    │   ├── link_card.dart                # Extracted link card with copy/open
    │   ├── step_progress_stepper.dart    # 5-step on-device progress stepper
    │   ├── summary_hero_card.dart        # Video thumbnail, TL;DR & highlights
    │   └── settings_dialog.dart          # Local settings & history management
    └── screens/
        ├── home_screen.dart              # Main input & mode selector
        ├── loading_screen.dart           # Live progress stepper view
        ├── results_screen.dart           # Extraction results view
        └── error_screen.dart             # Diagnostics & troubleshooting view
```

---

## 6. Verification Criteria & Deliverables

1. **Zero External Server Dependency**: The mobile application operates completely autonomously without running `uvicorn backend:app` or any background microservice.
2. **Native On-Device ML**: Google ML Kit OCR executes locally on device without external API calls or tokens.
3. **Regex Link Extraction Parity**: Exact behavioral parity with the link regex and deduplication rules from `backend.py`.
4. **Code Quality**: `flutter analyze` passes with 0 issues; automated test suite (`flutter test`) passes.
5. **Web Decoupling**: Existing web app files (`backend.py`, `index.html`, `requirements.txt`) remain 100% untouched.
