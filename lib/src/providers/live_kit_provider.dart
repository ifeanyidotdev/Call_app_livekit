import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveKitController extends ChangeNotifier {
  final Room _room = Room(
    roomOptions: RoomOptions(
      defaultCameraCaptureOptions: const CameraCaptureOptions(
        deviceId: '',
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      ),
      defaultAudioCaptureOptions: const AudioCaptureOptions(
        deviceId: '',
        noiseSuppression: true,
        echoCancellation: true,
        autoGainControl: true,
        highPassFilter: true,
        typingNoiseDetection: true,
      ),
      defaultVideoPublishOptions: VideoPublishOptions(
        videoEncoding: VideoParametersPresets.h720_169.encoding,
        videoSimulcastLayers: [
          VideoParametersPresets.h180_169,
          VideoParametersPresets.h360_169,
        ],
      ),
      defaultAudioPublishOptions: const AudioPublishOptions(
        dtx: true,
      ),
    ),
  );
  bool _isConnected = false;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isScreenSharing = false;
  bool _isJoining = false;

  bool get isConnected => _isConnected;
  bool get isMicEnabled => _isMicEnabled;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isJoining => _isJoining;

  Future<void> connectToRoom(String url, String token) async {
    try {
      _isJoining = true;
      notifyListeners();
      await _room.prepareConnection("wss://cloudnotte-xbiutpjq.livekit.cloud",
          "eyJhbGciOiJIUzI1NiJ9.eyJ2aWRlbyI6eyJyb29tSm9pbiI6dHJ1ZSwicm9vbSI6IjQ0OTljYzU5YzMiLCJjYW5QdWJsaXNoIjp0cnVlLCJjYW5TdWJzY3JpYmUiOnRydWUsImNhblB1Ymxpc2hEYXRhIjp0cnVlfSwiaXNzIjoiQVBJV0c4RGE5UTMzWkVRIiwiZXhwIjoxNzM1MzU1Mzg1LCJuYmYiOjAsInN1YiI6Ijc5NjkzNSJ9.baceIGI7Za46hPc3YWbbFzdYakVN7aljEoH_nJe9-_w");
      await _room.connect("wss://cloudnotte-xbiutpjq.livekit.cloud",
          "eyJhbGciOiJIUzI1NiJ9.eyJ2aWRlbyI6eyJyb29tSm9pbiI6dHJ1ZSwicm9vbSI6IjQ0OTljYzU5YzMiLCJjYW5QdWJsaXNoIjp0cnVlLCJjYW5TdWJzY3JpYmUiOnRydWUsImNhblB1Ymxpc2hEYXRhIjp0cnVlfSwiaXNzIjoiQVBJV0c4RGE5UTMzWkVRIiwiZXhwIjoxNzM1MzU1Mzg1LCJuYmYiOjAsInN1YiI6Ijc5NjkzNSJ9.baceIGI7Za46hPc3YWbbFzdYakVN7aljEoH_nJe9-_w");
      await _room.localParticipant?.setCameraEnabled(_isCameraEnabled);
      await _room.localParticipant?.setMicrophoneEnabled(_isMicEnabled);
      _isConnected = true;
      _room.addListener(_onRoomEvent);
      _isJoining = false;
      notifyListeners();
    } catch (e) {
      print('Error connecting to room: $e');
    }
  }

  void _onRoomEvent() {
    notifyListeners();
  }

  void toggleMic() {
    if (_room.localParticipant != null) {
      _isMicEnabled = !_isMicEnabled;
      _room.localParticipant!.setMicrophoneEnabled(_isMicEnabled);
      notifyListeners();
    }
  }

  void toggleCamera() {
    if (_room.localParticipant != null) {
      _isCameraEnabled = !_isCameraEnabled;
      _room.localParticipant!.setCameraEnabled(_isCameraEnabled);
      notifyListeners();
    }
  }

  Future<void> startScreenShare() async {
    if (_room.localParticipant != null) {
      try {
        _isScreenSharing = true;
        await _room.localParticipant!.setScreenShareEnabled(true);
        notifyListeners();
      } catch (e) {
        print('Error starting screen share: $e');
      }
    }
  }

  Future<void> stopScreenShare() async {
    if (_room.localParticipant != null && _isScreenSharing) {
      try {
        _isScreenSharing = false;
        await _room.localParticipant!.setScreenShareEnabled(false);
        notifyListeners();
      } catch (e) {
        print('Error stopping screen share: $e');
      }
    }
  }

  Future<void> startRecording(String roomName) async {
    // Call backend API to start recording
  }

  Future<void> stopRecording() async {
    // Call backend API to stop recording
  }

  void disconnect() {
    _room.dispose();
    _isConnected = false;
    notifyListeners();
  }
}
