
## Frontend Setup (Flutter)

Follow the steps below to run the frontend locally.

---

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) (with emulator or physical device setup)

---

### 1. Create a New Flutter Project

Run the following command in any directory (preferably outside this repo):
```bash
flutter create project_name
cd project_name
```

---

### 2. Replace the Default Code

- Navigate to your new project folder
- Replace the generated `lib/` folder with the one from this repository:
```
karat_frontend/lib  →  your_project/lib
```

---

### 3. Update Dependencies

Replace the `pubspec.yaml` in your project with the one provided in this repo:
```
karat_frontend/pubspec.yaml  →  your_project/pubspec.yaml
```

---

### 4. Configure Backend URL

Open `lib/core/constants.dart` and set `kBaseUrl` to match your environment:
```dart
// Android Emulator
const String kBaseUrl = 'http://10.0.2.2:8000';

// Physical Device (same WiFi)
const String kBaseUrl = 'http://192.168.x.x:8000';

// Chrome / Web
const String kBaseUrl = 'http://127.0.0.1:8000';
```

---

### 5. Install Packages
```bash
flutter pub get
```

---

### 6. Run the App
```bash
flutter run
```

---

## Backend Setup (FastAPI)

### 1. Install Dependencies
```bash
pip install fastapi uvicorn yfinance tensorflow joblib pandas
```

### 2. Start the Server
```bash
uvicorn app:app --reload
```

The API will be available at `http://127.0.0.1:8000`.
Swagger docs at `http://127.0.0.1:8000/docs`.

---
>>>>>>> 92277b6 (updated readme)
