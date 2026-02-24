import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

/// Onboarding / Setup Screen
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _nameController = TextEditingController();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSettingUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Page indicators
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? AppTheme.primaryColor
                          : AppTheme.offlineGrey.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildHowItWorksPage(),
                  _buildSetupPage(),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),

                  if (_currentPage < 3)
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isSettingUp ? null : _completeSetup,
                      child: _isSettingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Get Started'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.hub,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'MeshCall',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Offline Mesh Communication',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chat, call, and share location\nwithout internet or cell service!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLight.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 32),
          _FeatureItem(
            icon: Icons.chat_bubble,
            color: AppTheme.primaryColor,
            title: 'Offline Messaging',
            description: 'Send text messages without internet',
          ),
          _FeatureItem(
            icon: Icons.call,
            color: AppTheme.callGreen,
            title: 'Voice Calls',
            description: 'P2P voice calls via Bluetooth/Wi-Fi',
          ),
          _FeatureItem(
            icon: Icons.location_on,
            color: AppTheme.accentColor,
            title: 'Location Sharing',
            description: 'Share GPS location offline',
          ),
          _FeatureItem(
            icon: Icons.broadcast_on_home,
            color: AppTheme.meshBlue,
            title: 'Broadcasting',
            description: 'Send messages to everyone nearby',
          ),
          _FeatureItem(
            icon: Icons.lock,
            color: AppTheme.secondaryColor,
            title: 'End-to-End Encryption',
            description: 'All communications are encrypted',
          ),
          _FeatureItem(
            icon: Icons.hub,
            color: Colors.orange,
            title: 'Mesh Network',
            description: 'Messages relay through other devices',
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 32),
          _buildStepItem(
            '1',
            'Discover',
            'Your phone finds nearby devices using\nBluetooth and Wi-Fi Direct',
            Icons.search,
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '2',
            'Connect',
            'Creates a secure P2P connection\nwith encryption',
            Icons.link,
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '3',
            'Communicate',
            'Send messages, make calls, share location\nall without internet!',
            Icons.chat,
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '4',
            'Mesh Relay',
            'Messages hop through other devices\nto reach farther distances',
            Icons.hub,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Setup Your Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This name will be visible to nearby peers',
            style: TextStyle(
              color: AppTheme.textLight.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 48),
          // Avatar placeholder
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.2),
              border: Border.all(
                  color: AppTheme.primaryColor, width: 2),
            ),
            child: const Icon(
              Icons.person,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          // Name input
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: AppTheme.darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.person_outline,
                  color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          // Permissions info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Required Permissions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPermissionItem(Icons.bluetooth, 'Bluetooth'),
                _buildPermissionItem(Icons.wifi, 'Wi-Fi / Location'),
                _buildPermissionItem(Icons.mic, 'Microphone (for calls)'),
                _buildPermissionItem(Icons.location_on, 'GPS Location'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
      String number, String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textLight.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(icon, color: AppTheme.primaryColor.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildPermissionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.secondaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    setState(() => _isSettingUp = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final encryption =
          Provider.of<EncryptionService>(context, listen: false);

      // Generate encryption keys
      await encryption.generateKeyPair();

      // Save user profile
      await db.saveUserProfile(
        name: name,
        deviceId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await db.saveSetting('setup_complete', true);

      // Initialize mesh network BEFORE navigating to home
      final mesh = Provider.of<MeshNetworkService>(context, listen: false);
      final profile = db.getUserProfile();
      await mesh.initialize(
        profile['deviceId'] ?? '',
        profile['name'] ?? 'User',
      );

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isSettingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup error: $e'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
