import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'mesh_network_service.dart';

/// Voice Call Service
/// Handles P2P voice calling over mesh network (Bluetooth/Wi-Fi Direct)
/// Audio pipeline: Mic -> record (PCM16 16kHz) -> mesh -> flutter_sound playback
class VoiceCallService extends ChangeNotifier {
  final MeshNetworkService _meshService;
  final Uuid _uuid = const Uuid();

  // Audio pipeline – record captures mic, flutter_sound plays received PCM
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  StreamSubscription<Uint8List>? _micStreamSub;
  StreamSubscription<Uint8List>? _incomingAudioSub;
  bool _playerReady = false;

  CallInfo? _currentCall;
  Timer? _callTimer;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isRecording = false;

  // Audio streams
  final StreamController<Uint8List> _outgoingAudioController =
      StreamController.broadcast();
  final StreamController<Uint8List> _incomingAudioController =
      StreamController.broadcast();
  final StreamController<CallInfo> _callStateController =
      StreamController.broadcast();

  Stream<Uint8List> get outgoingAudio => _outgoingAudioController.stream;
  Stream<Uint8List> get incomingAudio => _incomingAudioController.stream;
  Stream<CallInfo> get onCallStateChanged => _callStateController.stream;

  CallInfo? get currentCall => _currentCall;
  int get callDuration => _callDuration;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isInCall => _currentCall?.state == CallState.active;
  bool get isRinging =>
      _currentCall?.state == CallState.ringing ||
      _currentCall?.state == CallState.connecting;

  VoiceCallService({required MeshNetworkService meshService})
      : _meshService = meshService {
    _setupCallSignalListener();
  }

  /// Listen for incoming call signals
  void _setupCallSignalListener() {
    _meshService.onCallSignal.listen((signal) {
      _handleCallSignal(signal);
    });
  }

  /// Handle incoming call signal
  void _handleCallSignal(Map<String, dynamic> signal) {
    final type = signal['type'] as String;
    final callId = signal['callId'] as String;
    final senderId = signal['senderId'] as String;
    final senderName = signal['senderName'] as String? ?? 'Unknown';

    switch (type) {
      case 'call_request':
        _handleIncomingCall(callId, senderId, senderName);
        break;
      case 'call_accept':
        _handleCallAccepted(callId);
        break;
      case 'call_reject':
        _handleCallRejected(callId);
        break;
      case 'call_end':
        _handleCallEnded(callId);
        break;
      case 'audio_data':
        final audioData = signal['data'] as Uint8List?;
        if (audioData != null) {
          _incomingAudioController.add(audioData);
        }
        break;
    }
  }

  /// Initiate a call to a peer
  Future<CallInfo?> initiateCall(Peer peer, {CallType type = CallType.voice}) async {
    if (_currentCall != null && _currentCall!.state == CallState.active) {
      debugPrint("Already in a call");
      return null;
    }

    final callId = _uuid.v4();
    _currentCall = CallInfo(
      id: callId,
      callerId: _meshService.myDeviceId,
      callerName: 'Me',
      receiverId: peer.id,
      receiverName: peer.name,
      state: CallState.ringing,
      callType: type,
      startTime: DateTime.now(),
    );

    notifyListeners();
    _callStateController.add(_currentCall!);

    // Send call request via mesh
    final sent = await _meshService.sendCallSignal(
      'call_request',
      peer.id,
      peer.deviceId,
      callId: callId,
    );

    if (!sent) {
      _currentCall = _currentCall!.copyWith(state: CallState.ended);
      notifyListeners();
      _callStateController.add(_currentCall!);
      return null;
    }

    // Auto-cancel after 30 seconds if not answered
    Timer(const Duration(seconds: 30), () {
      if (_currentCall?.state == CallState.ringing) {
        endCall();
      }
    });

    return _currentCall;
  }

  /// Handle incoming call
  void _handleIncomingCall(String callId, String senderId, String senderName) {
    if (_currentCall?.state == CallState.active) {
      // Already in a call, auto-reject
      _meshService.sendCallSignal('call_reject', senderId, senderId,
          callId: callId);
      return;
    }

    _currentCall = CallInfo(
      id: callId,
      callerId: senderId,
      callerName: senderName,
      receiverId: _meshService.myDeviceId,
      receiverName: 'Me',
      state: CallState.ringing,
      callType: CallType.voice,
      startTime: DateTime.now(),
    );

    notifyListeners();
    _callStateController.add(_currentCall!);
  }

  /// Accept an incoming call
  Future<void> acceptCall() async {
    if (_currentCall == null || _currentCall!.state != CallState.ringing) return;

    _currentCall = _currentCall!.copyWith(state: CallState.connecting);
    notifyListeners();
    _callStateController.add(_currentCall!);

    await _meshService.sendCallSignal(
      'call_accept',
      _currentCall!.callerId,
      _currentCall!.callerId,
      callId: _currentCall!.id,
    );

    // Start the call
    _startCall();
  }

  /// Reject an incoming call
  Future<void> rejectCall() async {
    if (_currentCall == null) return;

    await _meshService.sendCallSignal(
      'call_reject',
      _currentCall!.callerId,
      _currentCall!.callerId,
      callId: _currentCall!.id,
    );

    _currentCall = _currentCall!.copyWith(state: CallState.rejected);
    notifyListeners();
    _callStateController.add(_currentCall!);

    _resetCall();
  }

  /// End current call
  Future<void> endCall() async {
    if (_currentCall == null) return;

    final peerId = _currentCall!.callerId == _meshService.myDeviceId
        ? _currentCall!.receiverId
        : _currentCall!.callerId;

    await _meshService.sendCallSignal(
      'call_end',
      peerId,
      peerId,
      callId: _currentCall!.id,
    );

    _currentCall = _currentCall!.copyWith(
      state: CallState.ended,
      endTime: DateTime.now(),
      durationSeconds: _callDuration,
    );

    notifyListeners();
    _callStateController.add(_currentCall!);

    _stopCall();
    _resetCall();
  }

  /// Handle call accepted by remote
  void _handleCallAccepted(String callId) {
    if (_currentCall?.id != callId) return;

    _currentCall = _currentCall!.copyWith(state: CallState.connecting);
    notifyListeners();
    _callStateController.add(_currentCall!);

    _startCall();
  }

  /// Handle call rejected by remote
  void _handleCallRejected(String callId) {
    if (_currentCall?.id != callId) return;

    _currentCall = _currentCall!.copyWith(state: CallState.rejected);
    notifyListeners();
    _callStateController.add(_currentCall!);

    _resetCall();
  }

  /// Handle call ended by remote
  void _handleCallEnded(String callId) {
    if (_currentCall?.id != callId) return;

    _currentCall = _currentCall!.copyWith(
      state: CallState.ended,
      endTime: DateTime.now(),
      durationSeconds: _callDuration,
    );

    notifyListeners();
    _callStateController.add(_currentCall!);

    _stopCall();
    _resetCall();
  }

  /// Start the actual call (audio streaming)
  void _startCall() {
    _currentCall = _currentCall!.copyWith(state: CallState.active);
    _callDuration = 0;
    notifyListeners();
    _callStateController.add(_currentCall!);

    // Start call duration timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      notifyListeners();
    });

    // Start audio recording and streaming
    _startAudioStreaming();
  }

  /// Stop the call
  void _stopCall() {
    _callTimer?.cancel();
    _stopAudioStreaming();
  }

  /// Reset call state
  void _resetCall() {
    Future.delayed(const Duration(seconds: 2), () {
      _currentCall = null;
      _callDuration = 0;
      _isMuted = false;
      _isSpeakerOn = false;
      notifyListeners();
    });
  }

  /// Start audio streaming – mic → mesh → speaker
  void _startAudioStreaming() async {
    _isRecording = true;

    // ── Playback side ─────────────────────────────────────────────────────────
    try {
      await _audioPlayer.openPlayer();
      await _audioPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        bufferSize: 4096,
        interleaved: false,
      );
      _playerReady = true;
      debugPrint('[VoiceCall] Flutter Sound player started');
    } catch (e) {
      debugPrint('[VoiceCall] Player init error: $e');
    }

    // Receive incoming PCM chunks from mesh and feed to sink (non-blocking)
    _incomingAudioSub = _meshService.onAudioData.listen((chunk) {
      if (_playerReady && !_audioPlayer.isStopped) {
        _audioPlayer.uint8ListSink?.add(chunk);
      }
    });

    // ── Recording / sending side ──────────────────────────────────────────────
    try {
      final micStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 32000,
        ),
      );

      _micStreamSub = micStream.listen((audioChunk) {
        if (!_isMuted && _currentCall != null) {
          final peerDeviceId = _getPeerDeviceId();
          if (peerDeviceId != null) {
            _meshService.sendAudioData(audioChunk, peerDeviceId);
          }
        }
      });

      debugPrint('[VoiceCall] Mic stream started');
    } catch (e) {
      debugPrint('[VoiceCall] Mic start error: $e');
    }
  }

  /// Stop audio streaming
  void _stopAudioStreaming() async {
    if (!_isRecording) return;
    _isRecording = false;

    // Cancel subscriptions
    await _micStreamSub?.cancel();
    _micStreamSub = null;
    _incomingAudioSub?.cancel();
    _incomingAudioSub = null;

    // Stop mic recording
    try {
      await _audioRecorder.stop();
      debugPrint('[VoiceCall] Mic stopped');
    } catch (e) {
      debugPrint('[VoiceCall] Mic stop error: $e');
    }

    // Stop and close player
    try {
      if (_playerReady) {
        await _audioPlayer.stopPlayer();
        await _audioPlayer.closePlayer();
        _playerReady = false;
        debugPrint('[VoiceCall] Player stopped');
      }
    } catch (e) {
      debugPrint('[VoiceCall] Player stop error: $e');
    }
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(isMuted: _isMuted);
    }
    notifyListeners();
  }

  /// Toggle speaker
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(isSpeakerOn: _isSpeakerOn);
    }
    notifyListeners();
  }

  /// Format call duration as MM:SS
  String get formattedDuration {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Look up the BLE/WiFi device ID for the remote peer in the current call
  String? _getPeerDeviceId() {
    if (_currentCall == null) return null;
    final isCallerMe = _currentCall!.callerId == _meshService.myDeviceId;
    final remotePeerId =
        isCallerMe ? _currentCall!.receiverId : _currentCall!.callerId;
    // Search allPeers by logical id, then fallback to deviceId match
    for (final p in _meshService.allPeers.values) {
      if (p.id == remotePeerId || p.deviceId == remotePeerId) {
        return p.deviceId;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _stopAudioStreaming();
    _audioRecorder.dispose();
    _outgoingAudioController.close();
    _incomingAudioController.close();
    _callStateController.close();
    super.dispose();
  }
}
