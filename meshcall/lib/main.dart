import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/services.dart';
import 'screens/home/home_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();

  // Initialize encryption
  final encryptionService = EncryptionService();

  // Initialize Bluetooth mesh service
  final bluetoothService = BluetoothMeshService();

  // Initialize Wi-Fi Direct service
  final wifiDirectService = WifiDirectService();

  // Initialize main mesh network service
  final meshNetworkService = MeshNetworkService(
    bluetoothService: bluetoothService,
    wifiDirectService: wifiDirectService,
    encryptionService: encryptionService,
    databaseService: databaseService,
  );

  // Initialize voice call service
  final voiceCallService = VoiceCallService(
    meshService: meshNetworkService,
  );

  // Initialize location service
  final locationService = LocationService(
    meshService: meshNetworkService,
  );

  // Check if setup is complete
  final isSetupComplete =
      databaseService.getSetting<bool>('setup_complete') ?? false;

  // Initialize mesh if setup is complete
  if (isSetupComplete) {
    final profile = databaseService.getUserProfile();
    await meshNetworkService.initialize(
      profile['deviceId'] ?? '',
      profile['name'] ?? 'User',
    );
    await locationService.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: bluetoothService),
        ChangeNotifierProvider.value(value: wifiDirectService),
        ChangeNotifierProvider.value(value: meshNetworkService),
        ChangeNotifierProvider.value(value: voiceCallService),
        ChangeNotifierProvider.value(value: locationService),
        Provider.value(value: databaseService),
        Provider.value(value: encryptionService),
      ],
      child: MeshCallApp(isSetupComplete: isSetupComplete),
    ),
  );
}

class MeshCallApp extends StatelessWidget {
  final bool isSetupComplete;

  const MeshCallApp({super.key, required this.isSetupComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshCall',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isSetupComplete ? const HomeScreen() : const SetupScreen(),
    );
  }
}
