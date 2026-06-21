import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TelemetryData {
  final String status; // IDLE, RECORDING, PLAYING
  final int steps;     // Recorded steps count on ESP
  final int heapFree;
  final double latencyMs;

  TelemetryData({
    required this.status,
    required this.steps,
    required this.heapFree,
    required this.latencyMs,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json, double latency) {
    return TelemetryData(
      status: (json['status'] ?? 'IDLE') as String,
      steps: (json['steps'] ?? 0).toInt(),
      heapFree: (json['heap'] ?? 0).toInt(),
      latencyMs: latency,
    );
  }

  factory TelemetryData.empty() {
    return TelemetryData(status: 'IDLE', steps: 0, heapFree: 0, latencyMs: 0);
  }
}

class MovementSequence {
  final List<List<int>> frames;
  final String name;
  final DateTime timestamp;

  MovementSequence({
    required this.frames,
    required this.name,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'frames': frames.map((f) => f).toList(),
        'name': name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MovementSequence.fromJson(Map<String, dynamic> json) {
    var framesList = json['frames'] as List;
    return MovementSequence(
      frames: framesList.map((f) => List<int>.from(f)).toList(),
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class RobotService extends ChangeNotifier {
  String _ipAddress = '192.168.4.1';
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _throttleTimer;
  final List<int> _pendingAngles = List.filled(7, 90);
  TelemetryData _telemetry = TelemetryData.empty();
  final List<TelemetryData> _telemetryHistory = [];

  // --- Recording & Sequences State ---
  final List<MovementSequence> _sequences = [];
  bool _isRecording = false;
  final List<List<int>> _currentRecordingFrames = [];
  bool _isPlaying = false;
  int _currentPlayIndex = -1;
  int _currentFrameIndex = 0;
  Timer? _playTimer;
  double _playSpeed = 1.0;
  bool _loop = false;

  RobotService() {
    _loadSequences();
  }

  // Getters
  String get ipAddress => _ipAddress;
  bool get isConnected => _isConnected;
  TelemetryData get telemetry => _telemetry;
  List<TelemetryData> get telemetryHistory => List.unmodifiable(_telemetryHistory);
  List<int> get currentAngles => List.unmodifiable(_pendingAngles);

  List<MovementSequence> get sequences => List.unmodifiable(_sequences);
  bool get isRecording => _isRecording;
  int get recordingFrameCount => _currentRecordingFrames.length;
  bool get isPlaying => _isPlaying;
  int get currentPlayIndex => _currentPlayIndex;
  double get playSpeed => _playSpeed;
  bool get playLoop => _loop;

  set ipAddress(String value) {
    _ipAddress = value;
    notifyListeners();
  }

  String get _baseUrl => 'http://$_ipAddress';

  // --- Connection ---

  Future<String?> connect(String ip) async {
    _ipAddress = ip;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/'))
          .timeout(const Duration(seconds: 3));
      _isConnected = response.statusCode == 200;
      if (!_isConnected) {
        return "Received status code: ${response.statusCode}";
      }
    } catch (e) {
      _isConnected = false;
      return "Error: $e";
    }
    if (_isConnected) {
      _startHeartbeat();
    }
    notifyListeners();
    return null; // returning null means success
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isConnected = false;
    _telemetryHistory.clear();
    stopSequence();
    notifyListeners();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/'))
            .timeout(const Duration(seconds: 2));
        final wasConnected = _isConnected;
        _isConnected = response.statusCode == 200;
        if (wasConnected != _isConnected) notifyListeners();
      } catch (_) {
        if (_isConnected) {
          _isConnected = false;
          notifyListeners();
        }
      }
    });
  }

  // --- Servo Control ---

  void sendSingleServo(int servoNumber, int angle) {
    // Servo 1 (Gripper) is constrained to 0-90, others 0-180
    final maxAngle = servoNumber == 1 ? 90 : 180;
    final clamped = angle.clamp(0, maxAngle);
    _pendingAngles[servoNumber - 1] = clamped;
    _sendServoThrottled(servoNumber, clamped);
  }

  void sendServoAngles(List<int> angles) {
    for (int i = 0; i < 7 && i < angles.length; i++) {
      _pendingAngles[i] = angles[i].clamp(0, 180);
    }
    for (int i = 0; i < 7; i++) {
      _doSendSingle(i + 1, _pendingAngles[i]);
    }
  }

  Timer? _perServoTimer;

  void _sendServoThrottled(int servo, int value) {
    _perServoTimer?.cancel();
    _perServoTimer = Timer(const Duration(milliseconds: 50), () {
      _doSendSingle(servo, value);
    });
  }

  Future<void> _doSendSingle(int servo, int value) async {
    if (!_isConnected) return;
    try {
      await http
          .get(Uri.parse('$_baseUrl/set?servo=$servo&value=$value'))
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('OGARM: Send servo $servo failed: $e');
    }
  }

  // --- Emergency Stop ---

  Future<void> emergencyStop() async {
    _perServoTimer?.cancel();
    for (int i = 0; i < 7; i++) {
      _pendingAngles[i] = 90;
    }
    // Also stop any ESP recording/playback
    try {
      await http.get(Uri.parse('$_baseUrl/stop')).timeout(const Duration(seconds: 2));
    } catch (_) {}
    for (int i = 1; i <= 7; i++) {
      try {
        await http
            .get(Uri.parse('$_baseUrl/set?servo=$i&value=90'))
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('OGARM: E-Stop servo $i failed: $e');
      }
    }
    notifyListeners();
  }

  // --- ESP On-Board Record / Play / Stop ---

  Future<void> espRecord() async {
    if (!_isConnected) return;
    try {
      await http.get(Uri.parse('$_baseUrl/record')).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('OGARM: ESP Record failed: $e');
    }
  }

  Future<void> espPlay() async {
    if (!_isConnected) return;
    try {
      await http.get(Uri.parse('$_baseUrl/play')).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('OGARM: ESP Play failed: $e');
    }
  }

  Future<void> espStop() async {
    if (!_isConnected) return;
    try {
      await http.get(Uri.parse('$_baseUrl/stop')).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('OGARM: ESP Stop failed: $e');
    }
  }

  // --- Telemetry ---

  Future<TelemetryData> fetchTelemetry() async {
    if (!_isConnected) return TelemetryData.empty();
    try {
      final sw = Stopwatch()..start();
      final response = await http
          .get(Uri.parse('$_baseUrl/telemetry'))
          .timeout(const Duration(seconds: 2));
      sw.stop();
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _telemetry = TelemetryData.fromJson(json, sw.elapsedMilliseconds.toDouble());
        _telemetryHistory.add(_telemetry);
        if (_telemetryHistory.length > 60) {
          _telemetryHistory.removeAt(0);
        }
        notifyListeners();
        return _telemetry;
      }
    } catch (e) {
      debugPrint('OGARM: Telemetry fetch failed: $e');
    }
    return TelemetryData.empty();
  }

  // --- Sequence Management ---

  Future<void> _loadSequences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sequencesJson = prefs.getString('ogarm_sequences');
    if (sequencesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(sequencesJson);
        _sequences.clear();
        _sequences.addAll(decoded.map((e) => MovementSequence.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading sequences: $e');
      }
    }
  }

  Future<void> _saveSequences() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_sequences.map((e) => e.toJson()).toList());
    await prefs.setString('ogarm_sequences', encoded);
  }

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    _currentRecordingFrames.clear();
    notifyListeners();
  }

  void addFrame() {
    if (!_isRecording) return;
    _currentRecordingFrames.add(List.from(_pendingAngles));
    notifyListeners();
  }

  void stopRecordingAndSave(String name) {
    if (!_isRecording) return;
    if (_currentRecordingFrames.isNotEmpty) {
      _sequences.add(MovementSequence(
        frames: List.from(_currentRecordingFrames),
        name: name,
        timestamp: DateTime.now(),
      ));
      _saveSequences();
    }
    _isRecording = false;
    _currentRecordingFrames.clear();
    notifyListeners();
  }

  void cancelRecording() {
    _isRecording = false;
    _currentRecordingFrames.clear();
    notifyListeners();
  }

  void deleteSequence(int index) {
    _sequences.removeAt(index);
    if (_currentPlayIndex == index) {
      stopSequence();
    } else if (_currentPlayIndex > index) {
      _currentPlayIndex--;
    }
    _saveSequences();
    notifyListeners();
  }

  void reorderSequence(int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx--;
    final item = _sequences.removeAt(oldIdx);
    _sequences.insert(newIdx, item);
    _saveSequences();
    notifyListeners();
  }

  void setPlaySpeed(double speed) {
    _playSpeed = speed;
    notifyListeners();
  }

  void setPlayLoop(bool loop) {
    _loop = loop;
    notifyListeners();
  }

  void playSequence(int index) {
    if (_sequences.isEmpty || _sequences[index].frames.isEmpty) return;
    _isPlaying = true;
    _currentPlayIndex = index;
    _currentFrameIndex = -1; // -1 represents 90 degrees state
    notifyListeners();
    _executeFrame();
  }

  void stopSequence() {
    _playTimer?.cancel();
    _isPlaying = false;
    _currentPlayIndex = -1;
    _currentFrameIndex = 0;
    notifyListeners();
  }

  void _executeFrame() {
    if (!_isPlaying || _currentPlayIndex >= _sequences.length) {
      stopSequence();
      return;
    }

    final seq = _sequences[_currentPlayIndex];
    final delay = (1500 / _playSpeed).round();

    if (_currentFrameIndex == -1) {
      // 90 degree neutral state
      sendServoAngles(List.filled(7, 90));
      _playTimer = Timer(Duration(milliseconds: delay), () {
        if (!_isPlaying) return;
        _currentFrameIndex = 0;
        notifyListeners();
        _executeFrame();
      });
      return;
    }

    if (_currentFrameIndex >= seq.frames.length) {
      if (_loop && _isPlaying) {
        _currentFrameIndex = -1;
        notifyListeners();
        _executeFrame();
        return;
      }
      stopSequence();
      return;
    }

    sendServoAngles(seq.frames[_currentFrameIndex]);
    
    _playTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isPlaying) return;
      _currentFrameIndex++;
      notifyListeners();
      _executeFrame();
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _throttleTimer?.cancel();
    _playTimer?.cancel();
    super.dispose();
  }
}

