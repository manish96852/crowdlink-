# MeshCall - Offline Mesh Communication App

## Features
- **Offline Messaging** - Bluetooth & Wi-Fi Direct mesh networking
- **Voice Calling** - P2P voice calls without internet
- **Location Sharing** - GPS-based offline location sharing
- **Broadcasting** - Send messages to all nearby peers
- **E2E Encryption** - AES-256 + RSA encryption
- **Mesh Relay** - Messages hop through devices for extended range

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / VS Code
- Android device with Bluetooth & Wi-Fi

### Install
```bash
cd meshcall
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## Architecture
```
[Device A] <--Bluetooth--> [Device B] <--Wi-Fi Direct--> [Device C]
     |                          |                              |
     +--- Mesh Relay: Messages hop through intermediate devices
```

## Tech Stack
- **Flutter** - Cross-platform UI
- **flutter_blue_plus** - Bluetooth Low Energy
- **flutter_p2p_connection** - Wi-Fi Direct
- **Hive** - Local NoSQL database
- **PointyCastle** - Encryption (AES-256, RSA-2048)
- **Geolocator** - GPS location
- **Provider** - State management
