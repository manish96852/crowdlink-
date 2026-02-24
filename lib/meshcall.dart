/// MeshCall - Offline Mesh Communication App
/// 
/// A complete offline mesh networking application with:
/// - Bluetooth mesh messaging
/// - Wi-Fi Direct P2P communication  
/// - Voice calling (P2P)
/// - GPS location sharing
/// - End-to-end encryption
/// - Message broadcasting
/// - Mesh relay (multi-hop messaging)
///
/// Project Structure:
/// ```
/// meshcall/
/// ├── lib/
/// │   ├── main.dart                     # App entry point
/// │   ├── models/
/// │   │   ├── models.dart               # Export barrel
/// │   │   ├── peer.dart                 # Peer/device model
/// │   │   ├── message.dart              # Message model
/// │   │   └── call_info.dart            # Call information model
/// │   ├── services/
/// │   │   ├── services.dart             # Export barrel
/// │   │   ├── bluetooth_mesh_service.dart  # BLE mesh networking
/// │   │   ├── wifi_direct_service.dart     # Wi-Fi Direct P2P
/// │   │   ├── mesh_network_service.dart    # Main mesh orchestrator
/// │   │   ├── voice_call_service.dart      # P2P voice calling
/// │   │   ├── location_service.dart        # GPS location sharing
/// │   │   ├── encryption_service.dart      # E2E encryption (AES + RSA)
/// │   │   └── database_service.dart        # Local storage (Hive)
/// │   ├── screens/
/// │   │   ├── home/
/// │   │   │   └── home_screen.dart      # Main screen (4 tabs)
/// │   │   ├── chat/
/// │   │   │   └── chat_screen.dart      # Chat conversation UI
/// │   │   ├── call/
/// │   │   │   └── call_screen.dart      # Voice call UI
/// │   │   └── setup/
/// │   │       └── setup_screen.dart     # Onboarding & setup
/// │   └── utils/
/// │       └── app_theme.dart            # Theme & colors
/// ├── android/
/// │   └── app/src/main/
/// │       └── AndroidManifest.xml       # Permissions
/// └── pubspec.yaml                      # Dependencies
/// ```
/// 
/// Getting Started:
/// 1. Install Flutter SDK
/// 2. Run: flutter pub get
/// 3. Run: flutter run
/// 
/// Required Permissions:
/// - Bluetooth (scan, connect, advertise)
/// - Wi-Fi (state, P2P)  
/// - Location (GPS)
/// - Microphone (voice calls)
/// - Storage (local database)
library meshcall;
