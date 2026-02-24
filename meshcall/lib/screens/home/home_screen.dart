import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../chat/chat_screen.dart';
import '../call/call_screen.dart';

/// Home Screen - Professional UI with tabs for Chats, Peers, Calls, Map
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentIndex = _tabController.index);
    });
    _requestPermissions();
    _initMesh();
  }

  Future<void> _initMesh() async {
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);

    if (mesh.myDeviceId.isEmpty) {
      final profile = db.getUserProfile();
      await mesh.initialize(
        profile['deviceId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        profile['name'] ?? 'User',
      );
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
      Permission.microphone,
    ].request();

    setState(() {
      _permissionsGranted = statuses.values.any(
        (s) => s.isGranted || s.isLimited,
      );
    });

    debugPrint("Permissions granted: $_permissionsGranted");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ChatsTab(),
          _PeersTab(),
          _CallsTab(),
          _MapTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hub, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'MeshCall',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<MeshNetworkService>(
          builder: (context, mesh, _) {
            return GestureDetector(
              onTap: () {
                if (mesh.isActive) {
                  mesh.stopMesh();
                } else {
                  _startScanning();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: mesh.isActive
                      ? AppTheme.onlineGreen.withOpacity(0.15)
                      : AppTheme.offlineGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: mesh.isActive
                        ? AppTheme.onlineGreen.withOpacity(0.5)
                        : AppTheme.offlineGrey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mesh.isActive ? AppTheme.onlineGreen : AppTheme.offlineGrey,
                        boxShadow: mesh.isActive
                            ? [BoxShadow(color: AppTheme.onlineGreen.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mesh.isActive ? 'LIVE' : 'OFF',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: mesh.isActive ? AppTheme.onlineGreen : AppTheme.offlineGrey,
                        letterSpacing: 1,
                      ),
                    ),
                    if (mesh.onlinePeers.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${mesh.onlinePeers.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          onPressed: () => _openSettings(context),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chats'),
              _buildNavItem(1, Icons.people_rounded, Icons.people_outline_rounded, 'Peers'),
              _buildNavItem(2, Icons.call_rounded, Icons.call_outlined, 'Calls'),
              _buildNavItem(3, Icons.explore_rounded, Icons.explore_outlined, 'Map'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? AppTheme.primaryColor : AppTheme.offlineGrey, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    if (_currentIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: () => _showBroadcastDialog(),
        icon: const Icon(Icons.campaign_rounded, size: 22),
        label: const Text('Broadcast', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryColor, elevation: 4,
      );
    }
    if (_currentIndex == 1) {
      return Consumer<MeshNetworkService>(
        builder: (context, mesh, _) {
          return FloatingActionButton.extended(
            onPressed: () => _startScanning(),
            icon: Icon(mesh.isActive ? Icons.refresh_rounded : Icons.search_rounded, size: 22),
            label: Text(mesh.isActive ? 'Refresh' : 'Scan', style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: mesh.isActive ? AppTheme.secondaryColor : AppTheme.primaryColor, elevation: 4,
          );
        },
      );
    }
    return null;
  }

  void _startScanning() async {
    if (!_permissionsGranted) await _requestPermissions();
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    await mesh.startMesh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Scanning for nearby devices...'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showBroadcastDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Broadcast', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller, maxLines: 3, autofocus: true,
          decoration: InputDecoration(
            hintText: 'Message to all nearby peers...',
            filled: true, fillColor: AppTheme.darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.offlineGrey))),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final mesh = Provider.of<MeshNetworkService>(context, listen: false);
                mesh.broadcastMessage(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Message broadcasted!')]),
                    backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            icon: const Icon(Icons.send_rounded, size: 18), label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => const _SettingsSheet(),
    );
  }
}

// ============================================================
//  SETTINGS SHEET
// ============================================================
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final profile = db.getUserProfile();
    final mesh = Provider.of<MeshNetworkService>(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.offlineGrey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text((profile['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile['name'] ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ID: ${(profile['deviceId'] ?? '').toString().length > 8 ? (profile['deviceId'] ?? '').toString().substring(0, 8) : profile['deviceId'] ?? ''}...', style: const TextStyle(fontSize: 12, color: AppTheme.offlineGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.darkCard),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(label: 'Peers', value: '${mesh.allPeers.length}', icon: Icons.people),
              const SizedBox(width: 12),
              _StatCard(label: 'Online', value: '${mesh.onlinePeers.length}', icon: Icons.circle, iconColor: AppTheme.onlineGreen),
              const SizedBox(width: 12),
              _StatCard(label: 'Status', value: mesh.isActive ? 'Live' : 'Off', icon: Icons.hub, iconColor: mesh.isActive ? AppTheme.secondaryColor : AppTheme.offlineGrey),
            ],
          ),
          const SizedBox(height: 20),
          const _SettingsTile(icon: Icons.bluetooth_rounded, color: AppTheme.meshBlue, title: 'Bluetooth', subtitle: 'BLE mesh discovery'),
          const _SettingsTile(icon: Icons.wifi_rounded, color: AppTheme.secondaryColor, title: 'Wi-Fi Direct', subtitle: 'P2P data transfer'),
          const _SettingsTile(icon: Icons.lock_rounded, color: AppTheme.accentColor, title: 'Encryption', subtitle: 'AES-256 + RSA-2048'),
          const _SettingsTile(icon: Icons.info_outline_rounded, color: AppTheme.offlineGrey, title: 'Version', subtitle: '1.0.0'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  const _StatCard({required this.label, required this.value, required this.icon, this.iconColor = AppTheme.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.darkBg, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.offlineGrey)),
        ]),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _SettingsTile({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.offlineGrey)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.offlineGrey, size: 20),
      ),
    );
  }
}

// ============================================================
//  CHATS TAB
// ============================================================
class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, mesh, _) {
        final peers = mesh.allPeers.values.toList();
        if (peers.isEmpty) {
          return _EmptyState(
            icon: Icons.chat_bubble_outline_rounded, title: 'No Conversations',
            subtitle: 'Start mesh scanning to discover\nnearby peers and chat offline!',
            actionLabel: 'Start Scanning', onAction: () => mesh.startMesh(),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: peers.length,
          itemBuilder: (context, index) => _ChatTile(peer: peers[index]),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Peer peer;
  const _ChatTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: AppTheme.darkCard.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: peer.isOnline
                      ? [AppTheme.primaryColor.withOpacity(0.3), AppTheme.secondaryColor.withOpacity(0.3)]
                      : [AppTheme.offlineGrey.withOpacity(0.2), AppTheme.offlineGrey.withOpacity(0.15)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: peer.isOnline ? AppTheme.primaryColor : AppTheme.offlineGrey))),
            ),
            Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: peer.isOnline ? AppTheme.onlineGreen : AppTheme.offlineGrey, border: Border.all(color: AppTheme.darkBg, width: 2)))),
          ],
        ),
        title: Text(peer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Row(children: [
          Icon(peer.connectionType == ConnectionType.bluetooth ? Icons.bluetooth_rounded : Icons.wifi_rounded, size: 12, color: AppTheme.offlineGrey),
          const SizedBox(width: 4),
          Text(peer.isOnline ? 'Online' : _formatTime(peer.lastSeen), style: const TextStyle(fontSize: 12, color: AppTheme.offlineGrey)),
        ]),
        trailing: peer.isOnline
            ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTheme.onlineGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Text('Active', style: TextStyle(fontSize: 10, color: AppTheme.onlineGreen, fontWeight: FontWeight.w600)))
            : null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(peer: peer))),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============================================================
//  PEERS TAB
// ============================================================
class _PeersTab extends StatelessWidget {
  const _PeersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, mesh, _) {
        final onlinePeers = mesh.onlinePeers;
        final offlinePeers = mesh.allPeers.values.where((p) => !p.isOnline).toList();
        if (mesh.allPeers.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline_rounded, title: 'No Peers Found',
            subtitle: 'Make sure both devices have MeshCall\nand Bluetooth/WiFi is ON',
            actionLabel: mesh.isActive ? 'Scanning...' : 'Start Scan',
            onAction: mesh.isActive ? null : () => mesh.startMesh(),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (mesh.isActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3))),
                child: const Row(children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                  SizedBox(width: 12),
                  Text('Scanning for nearby devices...', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor)),
                ]),
              ),
            if (onlinePeers.isNotEmpty) ...[
              _SectionHeader(title: 'ONLINE', count: onlinePeers.length, color: AppTheme.onlineGreen),
              const SizedBox(height: 8),
              ...onlinePeers.map((peer) => _PeerTile(peer: peer)),
              const SizedBox(height: 20),
            ],
            if (offlinePeers.isNotEmpty) ...[
              _SectionHeader(title: 'OFFLINE', count: offlinePeers.length, color: AppTheme.offlineGrey),
              const SizedBox(height: 8),
              ...offlinePeers.map((peer) => _PeerTile(peer: peer)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Text('$title ($count)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5)),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: color.withOpacity(0.3))),
    ]);
  }
}

class _PeerTile extends StatelessWidget {
  final Peer peer;
  const _PeerTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.6), borderRadius: BorderRadius.circular(16),
        border: peer.isOnline ? Border.all(color: AppTheme.onlineGreen.withOpacity(0.2)) : null,
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: peer.isOnline ? [AppTheme.secondaryColor.withOpacity(0.3), AppTheme.primaryColor.withOpacity(0.2)] : [AppTheme.offlineGrey.withOpacity(0.2), AppTheme.offlineGrey.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: peer.isOnline ? AppTheme.secondaryColor : AppTheme.offlineGrey))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(peer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 3),
          Row(children: [
            Icon(peer.connectionType == ConnectionType.bluetooth ? Icons.bluetooth_rounded : Icons.wifi_rounded, size: 13, color: AppTheme.offlineGrey),
            const SizedBox(width: 4),
            Text(peer.connectionType == ConnectionType.bluetooth ? 'Bluetooth' : 'Wi-Fi Direct', style: const TextStyle(fontSize: 11, color: AppTheme.offlineGrey)),
            const SizedBox(width: 8),
            _SignalBars(rssi: peer.signalStrength),
          ]),
        ])),
        if (peer.isOnline) ...[
          _ActionButton(icon: Icons.chat_rounded, color: AppTheme.primaryColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(peer: peer)))),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.call_rounded, color: AppTheme.callGreen, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(peer: peer)))),
        ],
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int rssi;
  const _SignalBars({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final strength = rssi > -50 ? 3 : rssi > -70 ? 2 : rssi > -90 ? 1 : 0;
    return Row(children: List.generate(3, (i) => Container(
      width: 3, height: 5.0 + (i * 3.5), margin: const EdgeInsets.only(right: 1),
      decoration: BoxDecoration(color: i < strength ? AppTheme.secondaryColor : AppTheme.offlineGrey.withOpacity(0.3), borderRadius: BorderRadius.circular(1.5)),
    )));
  }
}

// ============================================================
//  CALLS TAB
// ============================================================
class _CallsTab extends StatelessWidget {
  const _CallsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceCallService>(
      builder: (context, callService, _) {
        return const _EmptyState(icon: Icons.call_outlined, title: 'No Call History', subtitle: 'Find a peer and tap the call button\nto make your first P2P call!');
      },
    );
  }
}

// ============================================================
//  MAP TAB
// ============================================================
class _MapTab extends StatelessWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<MeshNetworkService, LocationService>(
      builder: (context, mesh, location, _) {
        return Stack(children: [
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.darkBg, AppTheme.darkSurface])),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.explore_rounded, size: 56, color: AppTheme.primaryColor)),
              const SizedBox(height: 20),
              const Text('Offline Map', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('GPS location sharing\nworks without internet!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.offlineGrey, height: 1.5)),
            ])),
          ),
          Positioned(bottom: 20, right: 16, child: Column(children: [
            FloatingActionButton(heroTag: 'share_loc', backgroundColor: AppTheme.secondaryColor, onPressed: () {
              location.broadcastLocation();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Row(children: [Icon(Icons.location_on, color: Colors.white, size: 18), SizedBox(width: 8), Text('Location shared!')]),
                backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
              ));
            }, child: const Icon(Icons.share_location_rounded)),
            const SizedBox(height: 10),
            FloatingActionButton(heroTag: 'my_loc', backgroundColor: AppTheme.primaryColor, onPressed: () => location.getCurrentLocation(), child: const Icon(Icons.my_location_rounded)),
          ])),
          if (location.currentPosition != null)
            Positioned(top: 16, left: 16, right: 16, child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.darkCard.withOpacity(0.95), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.gps_fixed, color: AppTheme.secondaryColor, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('My Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${location.currentPosition!.latitude.toStringAsFixed(6)}, ${location.currentPosition!.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 11, color: AppTheme.offlineGrey)),
                ])),
              ]),
            )),
        ]);
      },
    );
  }
}

// ============================================================
//  EMPTY STATE
// ============================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, size: 64, color: AppTheme.primaryColor.withOpacity(0.4))),
      const SizedBox(height: 24),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
      const SizedBox(height: 10),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.offlineGrey, height: 1.5)),
      if (actionLabel != null) ...[
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onAction,
          icon: Icon(onAction != null ? Icons.search_rounded : Icons.hourglass_top, size: 18),
          label: Text(actionLabel!),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ],
    ])));
  }
}
