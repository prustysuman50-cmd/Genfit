# GenFit 🏋️‍♂️⚡

> **AI-Powered Campus Fitness & Student Wellness Companion**  
> Real-time on-device computer vision pose detection, hostel & campus nutrition intelligence, gamified progression, and campus community.

---

## 📑 Table of Contents
- [Tech Stack Overview](#-tech-stack-overview)
- [Detailed Technology Breakdown](#-detailed-technology-breakdown)
  - [1. Core Framework & Language](#1-core-framework--language)
  - [2. Computer Vision & Machine Learning (AI)](#2-computer-vision--machine-learning-ai)
  - [3. Hardware, Sensors & Device APIs](#3-hardware-sensors--device-apis)
  - [4. Software Architecture & Design Patterns](#4-software-architecture--design-patterns)
  - [5. Data Storage & Local Persistence](#5-data-storage--local-persistence)
  - [6. UI/UX Design System & Aesthetics](#6-uiux-design-system--aesthetics)
  - [7. Testing & Quality Assurance](#7-testing--quality-assurance)
  - [8. Platform & Build Infrastructure](#8-platform--build-infrastructure)
- [Core Application Features](#-core-application-features)
- [AI Biomechanical Pose Analysis Pipeline](#-ai-biomechanical-pose-analysis-pipeline)
- [Dependencies Reference](#-dependencies-reference)
- [Project Directory Structure](#-project-directory-structure)
- [Getting Started & Local Setup](#-getting-started--local-setup)

---

## 🚀 Tech Stack Overview

| Layer | Technologies / Libraries |
| :--- | :--- |
| **Framework & Language** | **Flutter SDK** (Material 3), **Dart** (`^3.13.4`) |
| **On-Device Computer Vision & AI** | **Google ML Kit Pose Detection** (`^0.16.1`), **Google ML Kit Commons** (`^0.13.0`) |
| **Biomechanical Analysis** | Custom 33-point skeletal vector kinematics, trigonometric joint angle calculation (`atan2`), finite state machine rep counters, form deviation feedback |
| **Hardware & Camera Interfacing** | **Camera plugin** (`^0.12.1`), `startImageStream` low-latency frame pipeline, camera lens switching (Front/Rear), torch control |
| **Device Permissions** | **Permission Handler** (`12.0.3`) for dynamic runtime permissions (Camera, Storage) |
| **Architecture** | Clean Layered Architecture + Service-Oriented Pattern (Presentation, Service, Domain/Model, Data) |
| **State Management** | Reactive `StatefulWidget` lifecycles, Singleton Service patterns, `ValueNotifier`, `SchedulerPhase` post-frame synchronization |
| **Data Persistence** | Custom sandboxed multi-path local JSON engine (`StorageService`) with resilient Android/iOS file system fallbacks |
| **Local Databases & Datasets** | Comprehensive offline Indian & college hostel food nutrition database (`local_food_database.dart`), mock community & peer feed datasets |
| **Styling & UI System** | Custom Dark Theme ("Deep Midnight" `#0B0F14` & Energetic Lime `#B8F35A`), Glassmorphism, Custom Canvas Painters (`CustomPainter`) for skeletal HUD wireframes & branding vectors |
| **Testing Suite** | `flutter_test` (21 unit, service, biomechanical, and widget test suites), `flutter_lints` (`^6.0.0`) |
| **Target Platforms** | Android (minSdk, compileSdk, targetSdk with Kotlin Gradle DSL), iOS, Web, macOS, Linux, Windows |

---

## 🔬 Detailed Technology Breakdown

### 1. Core Framework & Language
- **Flutter SDK**: High-performance, cross-platform declarative UI framework compiled directly to native ARM and x86 machine code. GenFit utilizes Flutter's hardware-accelerated rendering engine (Impeller/Skia) for high-FPS camera viewfinder overlays.
- **Dart (`^3.13.4`)**: Sound null-safe modern object-oriented language with asynchronous stream support (`Future`, `Stream`), isolates, and fast JIT (development) & AOT (production) compilation.
- **Material 3 Design (`uses-material-design: true`)**: Uses Material 3 design tokens and responsive widget primitives.

### 2. Computer Vision & Machine Learning (AI)
GenFit runs **100% on-device, low-latency AI** without sending video streams to any cloud servers, ensuring total privacy and instantaneous user feedback:
- **`google_mlkit_pose_detection: ^0.16.1`**:
  - Leverages Google's neural network pose detection model.
  - Detects **33 3D skeletal landmarks** in real time (shoulders, elbows, wrists, hips, knees, ankles, feet, facial keypoints).
  - Provides coordinates $(X, Y, Z)$ and landmark detection likelihood/confidence scores.
- **`google_mlkit_commons: ^0.13.0`**:
  - Manages cross-platform `InputImage` transformations, native pixel formats (YUV420_888 on Android, BGRA8888 on iOS), image metadata, and sensor orientation alignment.
- **Biomechanical Kinematics & Form Analysis Engine**:
  - **Trigonometric Joint Angle Estimation**: Computes dynamic joint angles using 2D/3D vectors:
    $$\theta = |\text{atan2}(C_y - B_y, C_x - B_x) - \text{atan2}(A_y - B_y, A_x - B_x)| \times \frac{180}{\pi}$$
    where $B$ is the joint vertex (e.g. knee, elbow), and $A, C$ are adjacent body landmarks (e.g. hip and ankle).
  - **Rep Counting State Machines**:
    - **Squat Engine** (`squat_analysis_service.dart`): Tracks states `[Standing/Up -> Descending -> In Squat (Inflection) -> Ascending -> Rep Complete]`. Evaluates parallel depth (hip below knee), back inclination, and knee-toe alignment.
    - **Push-up Engine** (`push_up_analysis_service.dart`): Tracks states `[Plank/Top -> Lowering -> Chest-to-floor (Inflection) -> Ascending -> Rep Complete]`. Monitors elbow flexion angle, spinal straightness (preventing sagging hips), and cadence.
  - **Real-Time Visual Skeletal Overlay**:
    - Custom Canvas Painter (`ai_viewfinder_preview.dart`) renders real-time skeletal wireframe lines, joint nodal indicators, and depth/angle indicators directly over the live camera viewfinder.

### 3. Hardware, Sensors & Device APIs
- **`camera: ^0.12.1`**:
  - Direct integration with camera hardware on Android (CameraX/Camera2) and iOS (AVFoundation).
  - Live preview stream subscription (`startImageStream`) forwarding raw camera buffers into ML Kit inference pipeline.
  - Front and back camera lens direction toggling.
  - Resolution preset management (`ResolutionPreset.medium` / `ResolutionPreset.high` balanced for high inference frame rate).
- **`permission_handler: 12.0.3`**:
  - Dynamic runtime permission checking and requesting for Camera (`Permission.camera`) and local file storage.
  - Graceful permission denial and fallback UX handling.

### 4. Software Architecture & Design Patterns
GenFit is structured with a modular, maintainable **Clean Service-Oriented Architecture**:

```
lib/
├── core/
│   ├── branding/        # Custom vector brand painters and splash views
│   ├── services/        # Singleton domain services & AI analysis engines
│   ├── theme/           # Design system tokens, color palettes & typography
│   └── widgets/         # Shared global UI components (Metric cards, badges, buttons)
├── data/                # Static & offline food datasets, community seed data
├── models/              # Immutable data contracts & entities
│   ├── community/       # Post, comments, and campus feed models
│   ├── gamification/    # XP, level, badges, and quest models
│   ├── journey/         # Fitness milestone & journey models
│   ├── leaderboard/     # Campus rank & leaderboard models
│   ├── nutrition/       # Meal, food item, macro calculation models
│   └── progress/        # Weekly/daily workout and metric telemetry
└── screens/             # Feature views & presentation layer
    ├── community/       # Campus feed, discussions, student interaction
    ├── home/            # Main dashboard, daily streaks, quick workout launch
    ├── journey/         # Long-term goals and progress milestones
    ├── leaderboard/     # Campus & hostel ranking boards
    ├── nutrition/       # Hostel mess menu, meal logging, affordable diet swaps
    ├── onboarding/      # Multi-step profile setup & personalization flow
    ├── profile/         # Student fitness profile, BMI, level badges
    ├── progress/        # Metric charts, workout history & analytics
    └── workout/         # Live camera AI workout session & exercise catalogue
```

**Key Architectural Patterns:**
- **Singleton Services**: Provides centralized state and business logic (`StorageService.instance`, `UserService.instance`, `NutritionService.instance`, `GamificationService.instance`, `CommunityService.instance`).
- **Finite State Machines**: Powers rep detection stages to eliminate false triggers and double counts.
- **Custom Painter Pattern**: Utilizes Flutter's `CustomPainter` to draw vector logos (`GenFitSymbolPainter`) and dynamic AI pose skeletons with zero asset overhead.
- **Repository / In-Memory Dataset Pattern**: Decouples UI screens from raw food and nutrition datasets.

### 5. Data Storage & Local Persistence
- **Sandboxed Local File Engine (`StorageService`)**:
  - Completely offline-first architecture; does not require an active internet connection to log workouts or track meals.
  - Performs JSON serialization and file persistence (`genfit_onboarding.json`, user preferences, progress logs).
  - Robust multi-path resolution: checks Android app-specific data directories (`/data/user/0/<package>/files`, `/data/data/...`) with fallback to system temporary directories.
- **Offline Indian Campus Food Database (`local_food_database.dart`)**:
  - Exhaustive database containing Indian mess staples (Dal, Roti, Paneer, Rice, Soya Chunks, Eggs, Curd, Poha, etc.).
  - Detailed macronutrient data: Calories, Protein, Carbohydrates, Fats.
  - Intelligent suggestions for **Affordable Student Alternatives** (e.g. high-protein budget foods for hostel living).

### 6. UI/UX Design System & Aesthetics
- **Color Palette (`AppColors`)**:
  - **Background**: Deep Midnight (`#0B0F14`)
  - **Surfaces**: Dark Muted Slate (`#151B22`, `#1B232C`)
  - **Primary Brand Accent**: Energetic Lime Green (`#B8F35A`)
  - **Secondary Accents**: Cyan Telemetry (`#38BDF8`), Fire Orange (`#F97316`), XP Gold (`#EAB308`), Electric Purple (`#A855F7`)
- **Typography (`AppTextStyles`)**:
  - Structured typographic scale with custom tracking, weights, and high-contrast accessibility on dark backgrounds.
- **Icons**:
  - `CupertinoIcons` (`^1.0.8`) & Material Icons.
- **Micro-Interactions**:
  - Live animated metric progress indicators, real-time angle readouts, streak counters, and floating bottom sheets (`add_meal_sheet.dart`, `hostel_food_detail_sheet.dart`).

### 7. Testing & Quality Assurance
GenFit maintains a thorough test suite of **21 test files** located in `test/`:
- **Biomechanical Tests**:
  - `pose_detection_service_test.dart`
  - `squat_analysis_service_test.dart` (validates knee angles, depth thresholds, and rep transitions)
  - `push_up_analysis_service_test.dart` (validates elbow angles, form infractions, and rep increments)
- **Domain Service Tests**:
  - `nutrition_service_test.dart`, `expanded_food_database_test.dart`, `todays_hostel_menu_test.dart`
  - `gamification_service_test.dart`, `journey_service_test.dart`, `leaderboard_service_test.dart`, `user_service_test.dart`
- **UI & Widget Tests**:
  - `widget_test.dart`, `user_profile_ui_test.dart`, `personal_info_step_test.dart`, `branding_system_test.dart`, etc.
- **Linting & Code Analysis**:
  - `flutter_lints: ^6.0.0` with custom analysis rules in `analysis_options.yaml`.

### 8. Platform & Build Infrastructure
- **Android**:
  - Gradle Kotlin DSL (`android/app/build.gradle.kts`)
  - Java Version: Java 17 (`JavaVersion.VERSION_17`, `JVM_17`)
  - Android SDK: Uses Flutter SDK configured `compileSdk`, `minSdk`, `targetSdk`
- **iOS**:
  - AVFoundation camera integration, Camera permission privacy keys (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`)
- **Multi-Platform Ready**:
  - Codebase contains setup for Android, iOS, Web, macOS, Linux, and Windows.

---

## ⚡ Core Application Features

1. **AI Vision Workout Coach**:
   - Real-time posture tracking for squats and push-ups via phone camera.
   - Live skeletal wireframe overlay with joint angle visualization.
   - Automatic rep counting with form validation (depth detection, back posture warning).
2. **Campus & Hostel Nutrition Engine**:
   - Today's Hostel Mess Menu tracker (Breakfast, Lunch, Snacks, Dinner).
   - Daily calorie and macronutrient progress (Protein, Carbs, Fats vs daily goals).
   - "Affordable Alternatives" tool designed to help students hit protein targets on a tight budget.
3. **Gamification & Daily Quests**:
   - XP points gained for logged workouts, completed daily quests, and consistent nutrition tracking.
   - Tiered campus levels (e.g., Level 4 "Campus Warrior") with progress indicators to next level.
   - Streak engine with fire streak badges to maintain daily consistency.
4. **Campus Community & Leaderboard**:
   - College campus leaderboard (`ITER • Bhubaneswar Campus` and collegiate ranking).
   - Social feed for peer motivation, workout shares, and community encouragement.
5. **Interactive Onboarding Flow**:
   - Multi-step questionnaire capturing age, height, weight, BMI, diet preferences, workout locations, and equipment availability.

---

## 🔄 AI Biomechanical Pose Analysis Pipeline

```
     ┌────────────────────────────────────────────────────────┐
     │                  Device Camera Stream                  │
     │            (camera: ^0.12.1 startImageStream)          │
     └──────────────────────────┬─────────────────────────────┘
                                │
                                ▼
     ┌────────────────────────────────────────────────────────┐
     │              Native Image Format Adapter               │
     │      (google_mlkit_commons InputImage metadata)        │
     └──────────────────────────┬─────────────────────────────┘
                                │
                                ▼
     ┌────────────────────────────────────────────────────────┐
     │          Google ML Kit Pose Detection Engine           │
     │           (On-Device Neural Network Inference)         │
     └──────────────────────────┬─────────────────────────────┘
                                │
                                ▼
     ┌────────────────────────────────────────────────────────┐
     │             33 3D Skeletal Landmark Points             │
     │       (Hips, Knees, Ankles, Shoulders, Elbows, etc.)   │
     └──────────────────────────┬─────────────────────────────┘
                                │
             ┌──────────────────┴──────────────────┐
             ▼                                     ▼
┌─────────────────────────────┐       ┌─────────────────────────────┐
│ Biomechanical State Machine │       │  Custom Canvas HUD Painter  │
│  - Joint Angle Calculations │       │  - Skeletal Wireframe Lines │
│  - Depth & Form Validation  │       │  - Real-time Angle Readouts │
│  - Rep Stage Transition     │       │  - Form Correction Hints    │
└────────────┬────────────────┘       └──────────────┬──────────────┘
             │                                       │
             └──────────────────┬────────────────────┘
                                │
                                ▼
     ┌────────────────────────────────────────────────────────┐
     │               User Workout Feedback HUD                │
     │        (Rep Counter, Form Audio/Haptic Alerts)         │
     └────────────────────────────────────────────────────────┘
```

---

## 📦 Dependencies Reference

Below are the primary packages defined in `pubspec.yaml`:

| Package | Version | Purpose |
| :--- | :--- | :--- |
| [`flutter`](https://flutter.dev) | SDK | Core UI rendering framework and Material/Cupertino components |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | `^1.0.8` | iOS-styled iconography assets |
| [`camera`](https://pub.dev/packages/camera) | `^0.12.1` | Hardware camera stream controller for real-time video feed |
| [`google_mlkit_pose_detection`](https://pub.dev/packages/google_mlkit_pose_detection) | `^0.16.1` | Real-time on-device human pose detection and landmark extraction |
| [`google_mlkit_commons`](https://pub.dev/packages/google_mlkit_commons) | `^0.13.0` | Cross-platform ML Kit camera frame and image transformation utilities |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | `12.0.3` | Dynamic cross-platform permissions manager (Camera, Storage) |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) *(dev)* | `^6.0.0` | Official Flutter recommended linting and code quality rules |
| [`flutter_test`](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) *(dev)* | SDK | Unit, service, and widget test framework |

---

## 📁 Project Directory Structure

```
genfit/
├── android/                   # Native Android host configuration (Gradle Kotlin DSL)
├── ios/                       # Native iOS host configuration (Xcode & CocoaPods)
├── lib/
│   ├── main.dart              # Application entrypoint & service initializers
│   ├── core/
│   │   ├── branding/          # GenFit logo, splash view & symbol painters
│   │   ├── services/          # AI pose analysis, storage, user, & nutrition services
│   │   ├── theme/             # AppColors, AppTextStyles, AppTheme
│   │   └── widgets/           # Global reusable UI widgets
│   ├── data/                  # Local food database & mock campus feeds
│   ├── models/                # Typed data models (UserProfile, Workout, Food, Post)
│   └── screens/               # Feature screens (Home, Workout, Nutrition, Community)
├── test/                      # 21 unit, biomechanical, service, and UI test files
├── pubspec.yaml               # Project dependencies and environment metadata
└── README.md                  # Project documentation & tech stack reference
```

---

## 🛠️ Getting Started & Local Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.4`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extension
- A physical Android or iOS device recommended (for hardware camera and ML Kit pose detection testing)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/genfit.git
   cd genfit
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run automated test suites:**
   ```bash
   flutter test
   ```

4. **Launch the application on connected device:**
   ```bash
   flutter run
   ```
#   g e n f i t  
 