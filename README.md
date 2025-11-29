# 🌟 ASTRA - Accessibility Smart Tactile Recognition Assistant

<div align="center">

![Astra Logo](assets/icons/ic_launcher.png)

**Empowering DeafBlind individuals with AI-powered real-time environmental awareness**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Cactus SDK](https://img.shields.io/badge/Cactus_SDK-1.2.0-purple.svg)](https://cactuscompute.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange.svg)](https://flutter.dev)

</div>

---

## 📖 About ASTRA

**ASTRA** (Accessibility Smart Tactile Recognition Assistant) is a revolutionary mobile application designed specifically for **DeafBlind individuals**. Using advanced on-device AI vision models with intelligent tool calling, ASTRA provides real-time environmental awareness through a unique combination of:

- 🎯 **Haptic Feedback** (Morse code vibrations)
- 🔊 **Text-to-Speech** (Voice guidance)
- 📱 **Visual Display** (High contrast UI)
- 🧠 **AI Tool Calling** (Intelligent action decisions)

The app analyzes the camera feed in real-time using a **dual AI model system** and provides **actionable safety guidance** - telling users whether to STOP, WALK, WAIT, or MOVE based on their surroundings.

---

## APK URL : https://drive.google.com/file/d/17kI7v5rfE-28YAXLuT2dplIsxN7SS3zM/view?usp=sharing

## ✨ Key Features

### 🎥 Real-Time Scene Analysis
- **Ultra-fast** analysis every **2 seconds**
- **Sub-second response time** in Fast Mode
- Streaming responses for immediate feedback
- On-device AI processing (no internet required)
- Privacy-focused - all processing happens locally
- Optimized for low-latency DeafBlind assistance

### 🧠 Intelligent Tool Calling (Qwen Model)
The app uses **Qwen 3 0.6B** model for intelligent decision making:
- Automatically decides when to alert about danger
- Chooses appropriate haptic patterns
- Generates friendly, helpful voice guidance
- Adapts responses based on scene context

### 🚨 Smart Danger Detection
| Danger Type | Detection | Response |
|-------------|-----------|----------|
| 🚗 Moving Vehicles | Approaching cars, traffic | Critical alert + STOP |
| 💧 Water Hazards | Pools, rivers, puddles | Warning + CAUTION |
| 🚧 Obstacles | Stairs, holes, barriers | Alert + WALK SLOWLY |
| 🛣️ Road Crossings | Active intersections | Warning + WAIT |
| ✅ Safe Areas | Indoor, clear paths | Confirmation + MOVE |

### 📳 Morse Code Haptic Feedback
Unique vibration patterns for different scenarios:

| Pattern | Morse Code | Meaning |
|---------|------------|---------|
| `---...---` | SOS-reversed | 🚨 DANGER - Stop immediately |
| `-...-` | V | 🚗 Vehicle nearby |
| `.--` | W | 💧 Water detected |
| `.-.` | R | 🛣️ Road/Crossing |
| `---` | O | 🚧 Obstacle ahead |
| `.--.` | P | 👤 Person nearby |
| `...` | S | ✅ Safe area |

### 🔊 Voice Guidance (TTS)
- Clear, concise safety instructions
- **Warm, friendly tone** - like a caring guide
- Actionable commands: STOP, WALK, WAIT, MOVE, SIT, STAND
- Adjustable speech rate and pitch
- Works with screen readers

### 📱 Accessible UI Design
- **Material Design 3** components
- **High contrast** dark theme
- **Large touch targets** for easy interaction
- **Simple navigation** for assistive devices

---

## 🛠️ Technical Architecture

### 🤖 Dual AI Model System (Powered by Cactus SDK)

ASTRA uses a **two-model pipeline** for intelligent assistance:

| Model | Name | Purpose | Size |
|-------|------|---------|------|
| 👁️ **Vision Model** | `lfm2-vl-450m` | Image analysis & scene description | ~150MB |
| 🧠 **Tool Calling Model** | `qwen3-0.6` | Intelligent action decisions | ~400MB |

#### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    📷 Camera Frame                       │
│                          ↓                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  👁️ Vision Model (lfm2-vl-450m)                 │   │
│  │  • Analyzes image                               │   │
│  │  • Describes scene in friendly tone            │   │
│  │  • Identifies objects and hazards              │   │
│  └─────────────────────────────────────────────────┘   │
│                          ↓                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🧠 Tool LLM (qwen3-0.6)                        │   │
│  │  • Receives scene description                  │   │
│  │  • Decides which tools to call                 │   │
│  │  • Triggers appropriate actions                │   │
│  └─────────────────────────────────────────────────┘   │
│                          ↓                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🛠️ Tool Execution                              │   │
│  │  • 📳 Haptic vibration (Morse code)            │   │
│  │  • 🔊 Voice guidance (TTS)                     │   │
│  │  • 🚨 Danger alerts                            │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 🛠️ AI Tool Calling System

The Qwen model can call **5 specialized tools** to help DeafBlind users:

| Tool | Purpose | Example |
|------|---------|---------|
| `detect_danger` | Report hazards | `{danger_type: "vehicle", level: "critical"}` |
| `alert_danger` | Urgent warnings | `{message: "Stop! Car approaching!"}` |
| `speak_text` | Voice guidance | `{text: "You're safe, indoor room ahead"}` |
| `vibrate_morse` | Haptic feedback | `{object_type: "person"}` |
| `describe_scene` | Environment info | `{environment: "outdoor", description: "..."}` |

#### Tool Calling Flow Example

```
Scene: "Person standing near a parked car on sidewalk"

🧠 Qwen Model Decision:
├── ✅ speak_text: "You're safe! A person is nearby on the sidewalk."
├── ✅ vibrate_morse: {object_type: "person"} → Vibrates: .--.
└── ✅ describe_scene: {environment: "outdoor", description: "Clear sidewalk"}

Result: User hears friendly guidance + feels person pattern (.--)
```

#### Danger Detection Example

```
Scene: "Car approaching fast on the road"

🧠 Qwen Model Decision:
├── 🚨 detect_danger: {danger_type: "vehicle", level: "critical"}
├── 🚨 alert_danger: {message: "Stop! Car coming fast!"}
├── ✅ speak_text: "Danger! Moving car ahead. Stop immediately!"
└── ✅ vibrate_morse: {object_type: "vehicle"} → Vibrates: -...-

Result: Strong vibration alert + urgent voice warning
```

### Clean Architecture Pattern

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  HomePage   │  │  Settings   │  │   Widgets   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                         │                               │
│                    ┌────┴────┐                         │
│                    │  BLoC   │  (State Management)     │
│                    └────┬────┘                         │
└─────────────────────────┼───────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────┐
│                    Domain Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Use Cases  │  │  Entities   │  │ Repositories│     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────┼───────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────┐
│                     Data Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │VisionService│  │ToolExecutor │  │CameraService│     │
│  │ (2 Models)  │  │ (5 Tools)   │  │  (Camera)   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│         │                │                │             │
│  ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐    │
│  │FeedbackSvc  │  │ToolDefinitions│ │DangerDetector│   │
│  │(TTS/Haptic) │  │  (Cactus)    │  │  (Logic)    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### Key Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.x | Cross-platform UI framework |
| **Dart** | 3.x | Programming language |
| **Cactus SDK** | 1.2.0 | On-device AI inference + Tool Calling |
| **Qwen 3** | 0.6B | Tool calling & decision making |
| **LFM2-VL** | 450M | Vision & image understanding |
| **Flutter BLoC** | Latest | State management |
| **GetIt** | Latest | Dependency injection |
| **flutter_tts** | Latest | Text-to-speech engine |
| **vibration** | Latest | Haptic feedback control |

### AI Model Configuration

```dart
// Vision Model Settings (OPTIMIZED for speed)
visionModel: 'lfm2-vl-450m'
visionMaxTokens: 25          // Short responses = fast TTS
contextSize: 512             // Small context = fast inference

// Tool Calling Model (Optional - disabled in Fast Mode)
toolCallingModel: 'qwen3-0.6'
toolMaxTokens: 40
analysisInterval: 2 seconds  // Real-time feel

// Performance Mode
useFastMode: true            // Skip tool LLM for lowest latency
```

### 🚀 Fast Mode vs Full Mode

| Feature | Fast Mode ✅ | Full Mode |
|---------|-------------|-----------|
| Latency | **<1 second** | ~2 seconds |
| Tool Calling | Disabled | Enabled |
| Models Used | Vision only | Vision + Qwen |
| Storage | ~150MB | ~550MB |
| Best For | Real-time safety | Detailed guidance |

---

## 📲 Installation

### Prerequisites
- Flutter SDK 3.x or higher
- Android Studio / Xcode
- Android 8.0+ or iOS 13.0+
- **~150MB storage** (Fast Mode) or ~550MB (Full Mode)

### Setup Instructions

1. **Clone the repository**
```bash
git clone https://github.com/seshasai/astra.git
cd astra
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🎮 How to Use

### First Launch
1. **Grant Permissions** - Camera and microphone access required
2. **Download Models** - AI models download automatically
   - **Fast Mode:** Vision Model only (~150MB) ⚡
   - **Full Mode:** Vision + Qwen (~550MB total)
3. **Wait for Initialization** - Models load in ~3-5 seconds
4. **Check Internet** - Required only for initial model download

### Daily Usage

#### Starting Scene Analysis
1. Open the app
2. Point camera at your surroundings
3. Tap **"Start Analysis"** button
4. Listen for voice guidance and feel vibrations

#### Understanding Feedback

**Voice Commands (Friendly Tone):**
- *"Hello! You're safe here. This is an indoor room with furniture. Feel free to move around."*
- *"Careful! There's a person walking nearby on your right. Walk slowly."*
- *"Danger! I see a car approaching. Please stop and wait."*

**Vibration Patterns:**
- **Long continuous** (2 sec) = CRITICAL DANGER
- **3 quick pulses** = WARNING
- **2 short pulses** = CAUTION
- **Single gentle tap** = SAFE

#### Settings
Access settings to customize:
- ✅ Enable/Disable voice feedback
- ✅ Enable/Disable haptic feedback
- ✅ Adjust speech rate
- ✅ Enable/Disable danger alerts

---

## 🎯 Use Cases

### 🚶 Walking Outdoors
- Detects approaching vehicles
- Warns about road crossings
- Identifies obstacles in path
- **Qwen decides**: When to alert vs when to stay calm

### 🏠 Indoor Navigation
- Identifies furniture and objects
- Warns about stairs and steps
- Confirms safe areas
- **Qwen provides**: Friendly room descriptions

### 🌊 Near Water Bodies
- Alerts about pools, rivers
- Warns about flood areas
- Identifies water hazards
- **Qwen triggers**: Water-specific morse pattern (.--) 

### 🚧 Construction Zones
- Detects barriers and holes
- Warns about unstable surfaces
- Identifies drop-offs
- **Qwen alerts**: With appropriate urgency level

---

## 🔒 Privacy & Security

- **100% On-Device Processing** - No data sent to cloud
- **No Data Collection** - Camera feed processed locally
- **No Internet Required** - Works offline after model download
- **No Account Required** - No sign-up or login needed
- **Models Run Locally** - Both Vision and Qwen models run on your device

---

## 📋 Requirements

### Minimum Requirements
| Platform | Version | Storage (Fast Mode) | Storage (Full Mode) |
|----------|---------|---------------------|---------------------|
| Android | 8.0 (API 26) | **150MB** | 550MB |
| iOS | 13.0 | **150MB** | 550MB |

### Permissions Required
- 📷 **Camera** - For scene analysis
- 🔊 **Microphone** - For TTS (optional)
- 📳 **Vibration** - For haptic feedback

---

## 🤝 Accessibility Standards

ASTRA is designed following:
- **WCAG 2.1** AA guidelines
- **Android Accessibility** best practices
- **iOS Accessibility** guidelines
- **DeafBlind International** recommendations

---

## 📊 Performance

### ⚡ Fast Mode (Recommended for DeafBlind Users)

| Metric | Value |
|--------|-------|
| Analysis Interval | **2 seconds** |
| Vision Response | **< 1 second** |
| Total Response Time | **< 1 second** |
| Time to First Token | ~200ms |
| Battery Usage | Optimized |
| Memory Usage | ~250MB |
| Model Size | **~150MB** |

### 🧠 Full Mode (With Tool Calling)

| Metric | Value |
|--------|-------|
| Analysis Interval | 2 seconds |
| Vision Response | ~1 second |
| Tool Calling Response | ~0.5 seconds |
| Total Response Time | ~1.5-2 seconds |
| Memory Usage | ~400MB |
| Total Model Size | ~550MB |

---

## 🐛 Known Limitations

- Low light conditions may reduce accuracy
- Rapid movement may cause blurry analysis
- Very crowded scenes may have reduced accuracy
- First analysis may take slightly longer (~2 seconds)
- Requires stable internet for initial model download

### 🌐 Network Error Handling
If model download fails, the app will:
- Show a friendly **"Check Internet Connection"** message
- Display helpful tips (WiFi, mobile data, airplane mode toggle)
- Provide a **"Try Again"** button to retry download

---

## 🗺️ Roadmap

- [ ] Multi-language TTS support
- [ ] Customizable vibration patterns
- [ ] Object distance estimation
- [ ] Offline voice model
- [ ] Apple Watch / WearOS support
- [ ] Integration with smart glasses
- [ ] More tool calling capabilities
- [ ] Conversation history for context

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer

<div align="center">

### **Seshasai Nagadevara**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/seshasai-subrahmanyam-48b2512b4/)
[![Email](https://img.shields.io/badge/Email-Contact-red?style=for-the-badge&logo=gmail)](mailto:nvsseshasai@gmail.com)

**Email:** nvsseshasai@gmail.com

**LinkedIn:** [linkedin.com/in/seshasai-subrahmanyam-48b2512b4](https://www.linkedin.com/in/seshasai-subrahmanyam-48b2512b4/)

</div>

---

## 🧪 Technical Optimizations

### Prompt Engineering
```
Vision Prompt: "SAFE or DANGER? 5 words max."
```
- Ultra-short prompt for fastest inference
- Consistent SAFE/DANGER prefix for reliable parsing
- 5-word limit ensures sub-second TTS playback

### Performance Tuning
- **Context Size:** 512 tokens (minimal memory)
- **Max Tokens:** 25 (short responses)
- **Analysis Interval:** 2 seconds (real-time feel)
- **Image Resolution:** 384px (fast processing)
- **JPEG Quality:** 75% (speed vs quality balance)

---

## 🙏 Acknowledgments

- **Cactus Compute** - For the amazing on-device AI SDK with Tool Calling support
- **Qwen Team** - For the efficient Qwen 3 model
- **Flutter Team** - For the cross-platform framework
- **DeafBlind Community** - For inspiration and feedback
- **Open Source Contributors** - For the amazing packages

---

## 💖 Support

If ASTRA has helped you or someone you know, please consider:
- ⭐ **Star this repository**
- 🐛 **Report bugs** and suggest features
- 📢 **Share** with others who might benefit
- 💬 **Provide feedback** for improvements

---

<div align="center">

**Built with ❤️ for the DeafBlind Community**

*Making the world more accessible, one vibration at a time.*

---

### 🤖 Powered by

**Cactus SDK** | **Qwen 3** | **LFM2-VL** | **Flutter**

</div>
