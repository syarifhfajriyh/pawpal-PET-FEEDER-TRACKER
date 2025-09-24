# 🐾 PawPal – Pet Feeder Tracker

PawPal is a **smart pet feeder tracker** built with **Flutter**, designed to help pet owners monitor and manage their pet’s feeding schedules anytime, anywhere.
The app integrates with IoT devices to track feeding activities, provide data history, and ensure pets are always fed on time.

---

# 🚀 Features

* 📊 **Feeding History Tracking** – Record and view your pet’s feeding times with timestamps.
* 🔔 **Reminders & Notifications** – Get notified when it’s time to feed your pet.
* 👨‍👩‍👧 **Multi-User Access** – Supports both **Admin** and **User** roles for easy management.
* 🌐 **Real-Time IoT Integration** – Syncs with the pet feeder device to monitor feeding status.
* 🔒 **Secure Login** – Password encryption, email verification, and password reset support.
* 📱 **Friendly UI** – Simple, elegant, and mobile-friendly design.

---

# 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase / SQL Database (depending on setup)
* **Device Integration:** ESP32 / Raspberry Pi (IoT-enabled feeder)
* **Authentication:** Firebase Auth / Email Verification

---

# 📂 Project Structure

```
pawpal/
│-- android/
│-- ios/
│-- lib/
│   ├── main.dart
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   └── services/
│-- assets/
│   ├── images/
│   └── icons/
│-- pubspec.yaml
└── README.md
```

---

# ⚡ Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Android Studio / VS Code with Flutter & Dart plugins
* Connected device or emulator

### Installation

```bash
# Clone this repository
git clone https://github.com/bibekkakati/pawfeeder-flutter.git

# Navigate to project directory
cd pawpal

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🤝 Contributing

1. Fork the project
2. Create a new branch (`git checkout -b feature-branch`)
3. Commit changes (`git commit -m 'Add new feature'`)
4. Push to branch (`git push origin feature-branch`)
5. Open a Pull Request

---

## 💡 Acknowledgements

* IoT integration inspired by community projects.
* Special thanks to the Flutter and Firebase communities.

---


