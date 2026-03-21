# 🥇 Gold Rate Predictor — Flutter App

A Flutter mobile app for real-time gold price viewing, historical trends, and LSTM-based predictions. Connects to your existing FastAPI backend (`app.py`).

---

## 📁 Folder Structure

```
gold_predictor/
├── android/
├── ios/
├── lib/
│   ├── main.dart                    # App entry point, theme, routing
│   ├── core/
│   │   ├── constants.dart           # API base URL, colors, strings
│   │   └── theme.dart               # App-wide ThemeData
│   ├── models/
│   │   ├── gold_current.dart        # Model for /current response
│   │   ├── gold_history.dart        # Model for /history response
│   │   └── gold_prediction.dart     # Model for /predict response
│   ├── services/
│   │   └── gold_api_service.dart    # All HTTP calls to FastAPI backend
│   ├── screens/
│   │   ├── home_screen.dart         # Dashboard: current price cards
│   │   ├── history_screen.dart      # Historical chart + table
│   │   ├── predict_screen.dart      # Prediction input + results
│   │   └── login_screen.dart        # Optional auth screen
│   └── widgets/
│       ├── price_card.dart          # Reusable gold price card widget
│       ├── gold_chart.dart          # Line chart widget (fl_chart)
│       └── prediction_result.dart   # Prediction output display
├── pubspec.yaml
└── README.md
```

---

## 🚀 Setup Instructions

### 1. Create Flutter Project

```bash
flutter create gold_predictor
cd gold_predictor
```

### 2. Replace `pubspec.yaml` dependencies section

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  fl_chart: ^0.68.0
  provider: ^6.1.2
  intl: ^0.19.0
  shimmer: ^3.0.0
  lottie: ^3.1.2
  shared_preferences: ^2.2.3
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

Then run:
```bash
flutter pub get
```

### 3. Configure Backend URL

Edit `lib/core/constants.dart`:
```dart
const String kBaseUrl = 'http://YOUR_BACKEND_IP:8000';
// For local emulator: http://10.0.2.2:8000
// For physical device: http://<your-machine-LAN-ip>:8000
```

### 4. Run the app

```bash
flutter run
```

---

## 🔌 API Endpoints Used

| Screen | Endpoint | Method |
|---|---|---|
| Home | `/current` | GET |
| History | `/history?days=30` | GET |
| Predict | `/predict?days_ahead=N` | GET |

---

## 📱 Screens Overview

### 🏠 Home Screen
- Displays live gold price (24K / 10g) and Kerala Pavan (22K) price
- USD index shown as a secondary card
- Pull-to-refresh to fetch latest

### 📈 History Screen
- Line chart of historical gold prices (default: 30 days)
- Day selector: 7 / 30 / 90 / 180 days
- Both 24K and Pavan prices plotted

### 🔮 Predict Screen
- Slider to select days ahead (1–30)
- Shows predicted 24K and Pavan prices per day
- Bar or line chart of prediction trend

### 🔐 Login Screen (Optional)
- Simple email/password UI
- Can be wired to your own auth backend or skipped

---

## 💡 Notes

- The backend uses a **dummy fallback** when the LSTM model is unavailable — predictions will still work.
- Sentiment & news count fields in the backend are randomly generated; no input needed from the app.
- For production, change `allow_origins=["*"]` in your FastAPI CORS settings to your specific domain/IP.

---

## 📦 Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
