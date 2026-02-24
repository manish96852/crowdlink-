import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

/// Call Screen - Voice call UI
class CallScreen extends StatefulWidget {
  final Peer peer;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.peer,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for avatar during call
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Initiate call if outgoing
    if (!widget.isIncoming) {
      _initiateCall();
    }
  }

  void _initiateCall() {
    final callService = Provider.of<VoiceCallService>(context, listen: false);
    callService.initiateCall(widget.peer);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceCallService>(
      builder: (context, callService, _) {
        final isActive = callService.isInCall;
        final isRinging = callService.isRinging;

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar with back button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (isActive || isRinging) {
                            callService.endCall();
                          }
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      // Connection type indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.peer.connectionType ==
                                      ConnectionType.bluetooth
                                  ? Icons.bluetooth
                                  : Icons.wifi,
                              size: 16,
                              color: AppTheme.meshBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.peer.connectionType ==
                                      ConnectionType.bluetooth
                                  ? 'Bluetooth'
                                  : 'Wi-Fi Direct',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.meshBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),

                const Spacer(),

                // Call status
                Text(
                  _getCallStatusText(callService),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.offlineGrey,
                  ),
                ),
                const SizedBox(height: 8),

                // Duration (if active)
                if (isActive)
                  Text(
                    callService.formattedDuration,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),

                const SizedBox(height: 24),

                // Animated avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isActive ? _pulseAnimation.value : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse waves (during ringing)
                          if (isRinging) ..._buildPulseWaves(),

                          // Avatar
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isActive
                                    ? [
                                        AppTheme.secondaryColor,
                                        AppTheme.primaryColor,
                                      ]
                                    : [
                                        AppTheme.primaryColor.withOpacity(0.7),
                                        AppTheme.primaryColor,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive
                                          ? AppTheme.secondaryColor
                                          : AppTheme.primaryColor)
                                      .withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.peer.name.isNotEmpty
                                    ? widget.peer.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Peer name
                Text(
                  widget.peer.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 14, color: AppTheme.secondaryColor),
                    const SizedBox(width: 4),
                    const Text(
                      'End-to-End Encrypted',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Call controls
                if (isActive) _buildActiveCallControls(callService),
                if (isRinging && widget.isIncoming)
                  _buildIncomingCallControls(callService),
                if (isRinging && !widget.isIncoming)
                  _buildOutgoingCallControls(callService),

                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPulseWaves() {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          final progress =
              (_waveController.value + index * 0.3).clamp(0.0, 1.0);
          return Container(
            width: 140 + (progress * 100),
            height: 140 + (progress * 100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor
                    .withOpacity(0.3 * (1.0 - progress)),
                width: 2,
              ),
            ),
          );
        },
      );
    });
  }

  /// Active call controls (mute, speaker, end)
  Widget _buildActiveCallControls(VoiceCallService callService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _CallControlButton(
            icon: callService.isMuted ? Icons.mic_off : Icons.mic,
            label: callService.isMuted ? 'Unmute' : 'Mute',
            color: callService.isMuted
                ? AppTheme.accentColor
                : AppTheme.darkCard,
            onPressed: () => callService.toggleMute(),
          ),

          // End call button
          _CallControlButton(
            icon: Icons.call_end,
            label: 'End',
            color: AppTheme.callRed,
            size: 72,
            onPressed: () {
              callService.endCall();
              Navigator.pop(context);
            },
          ),

          // Speaker button
          _CallControlButton(
            icon: callService.isSpeakerOn
                ? Icons.volume_up
                : Icons.volume_down,
            label: 'Speaker',
            color: callService.isSpeakerOn
                ? AppTheme.meshBlue
                : AppTheme.darkCard,
            onPressed: () => callService.toggleSpeaker(),
          ),
        ],
      ),
    );
  }

  /// Incoming call controls (accept, reject)
  Widget _buildIncomingCallControls(VoiceCallService callService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reject
          _CallControlButton(
            icon: Icons.call_end,
            label: 'Decline',
            color: AppTheme.callRed,
            size: 72,
            onPressed: () {
              callService.rejectCall();
              Navigator.pop(context);
            },
          ),

          // Accept
          _CallControlButton(
            icon: Icons.call,
            label: 'Accept',
            color: AppTheme.callGreen,
            size: 72,
            onPressed: () => callService.acceptCall(),
          ),
        ],
      ),
    );
  }

  /// Outgoing call controls (cancel)
  Widget _buildOutgoingCallControls(VoiceCallService callService) {
    return _CallControlButton(
      icon: Icons.call_end,
      label: 'Cancel',
      color: AppTheme.callRed,
      size: 72,
      onPressed: () {
        callService.endCall();
        Navigator.pop(context);
      },
    );
  }

  String _getCallStatusText(VoiceCallService callService) {
    final call = callService.currentCall;
    if (call == null) return 'Connecting...';

    switch (call.state) {
      case CallState.ringing:
        return widget.isIncoming ? 'Incoming Call...' : 'Ringing...';
      case CallState.connecting:
        return 'Connecting...';
      case CallState.active:
        return 'Call Active';
      case CallState.ended:
        return 'Call Ended';
      case CallState.rejected:
        return 'Call Declined';
      case CallState.missed:
        return 'Missed Call';
      default:
        return 'Initializing...';
    }
  }
}

/// Call control button widget
class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.size = 56,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.offlineGrey,
          ),
        ),
      ],
    );
  }
}
