import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'mesh_network_service.dart';

/// Location Service for offline GPS-based location sharing
class LocationService extends ChangeNotifier {
  final MeshNetworkService _meshService;
  final Uuid _uuid = const Uuid();

  Position? _currentPosition;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  final List<Position> _locationHistory = [];

  final StreamController<Position> _positionController =
      StreamController.broadcast();

  Stream<Position> get onPositionChanged => _positionController.stream;
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  List<Position> get locationHistory => List.unmodifiable(_locationHistory);

  LocationService({required MeshNetworkService meshService})
      : _meshService = meshService;

  /// Initialize location service and check permissions
  Future<bool> initialize() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permission permanently denied");
      return false;
    }

    return true;
  }

  /// Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  /// Start continuous location tracking
  Future<void> startTracking({Duration interval = const Duration(seconds: 10)}) async {
    if (_isTracking) return;

    _isTracking = true;
    notifyListeners();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // minimum 10 meters change
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        _locationHistory.add(position);
        _positionController.add(position);
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Location tracking error: $e");
      },
    );
  }

  /// Stop location tracking
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    notifyListeners();
  }

  /// Share current location with a specific peer
  Future<bool> shareLocation(String receiverId, String receiverDeviceId,
      {String? locationName}) async {
    final position = await getCurrentLocation();
    if (position == null) return false;

    return await _meshService.sendLocation(
      position.latitude,
      position.longitude,
      locationName,
      receiverId,
      receiverDeviceId,
    );
  }

  /// Share location with all peers (broadcast)
  Future<void> broadcastLocation({String? locationName}) async {
    final position = await getCurrentLocation();
    if (position == null) return;

    for (var peer in _meshService.onlinePeers) {
      await _meshService.sendLocation(
        position.latitude,
        position.longitude,
        locationName,
        peer.id,
        peer.deviceId,
      );
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Get formatted distance string
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get compass direction from bearing
  String bearingToDirection(double bearing) {
    const directions = [
      'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'
    ];
    final index = ((bearing + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  @override
  void dispose() {
    stopTracking();
    _positionController.close();
    super.dispose();
  }
}
