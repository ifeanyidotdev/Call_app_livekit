import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:call_app_livekit/src/models/participant_track_model.dart';

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
  List<ParticipantTrack> participantTracks = [];
  bool _isConnected = false;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isScreenSharing = false;
  bool _isJoining = false;
  bool _isError = false;
  bool _isRecording = false;
  String _errorMessage = "";
  late EventsListener<RoomEvent> _listener;

  bool get isConnected => _isConnected;
  bool get isMicEnabled => _isMicEnabled;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isJoining => _isJoining;
  bool get isRecording => _isRecording;
  bool get isError => _isError;
  bool get isScreenSharing => _isScreenSharing;
  String get errorMessage => _errorMessage;
  Room get room => _room;
  EventsListener<RoomEvent> get listener => _listener;

  Future<String> getConnectionToken(
      {required String username,
      required String meetId,
      required String userId}) async {
    _isJoining = true;
    _isError = false;
    notifyListeners();
    try {
      final dio = Dio(BaseOptions(baseUrl: "https://local.cloudnotte.com/api"));
      final response = await dio.post("/liveClass/joinCall", data: {
        "username": username,
        "userIdentity": userId,
        "callId": meetId
      });
      final data = response.data;
      print("DATA ${data.toString()}");
      return data['token'] as String;
    } catch (e) {
      print("TOKEN ERROR: $e");
      _isJoining = false;
      notifyListeners();
      return "";
    }
  }

  Future<void> connectToRoom(String token) async {
    try {
      _isJoining = true;
      _isConnected = false;
      notifyListeners();
      _listener = room.createListener();
      await _room.prepareConnection(
        "wss://cloudnotte-xbiutpjq.livekit.cloud",
        token,
      );
      await _room.connect("wss://cloudnotte-xbiutpjq.livekit.cloud", token);
      await _room.localParticipant?.setCameraEnabled(_isCameraEnabled);
      await _room.localParticipant?.setMicrophoneEnabled(_isMicEnabled);
      _isConnected = true;
      _isJoining = false;
      notifyListeners();
    } catch (e) {
      _isJoining = false;
      _isError = true;
      _errorMessage = e.toString();
      notifyListeners();
      print('Error connecting to room: $e');
    }
  }

  void _onRoomEvent() {
    notifyListeners();
  }

  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((event) async {
      if (event.reason != null) {
        print('Room disconnected: reason => ${event.reason}');
      }
      _isConnected = false;
      notifyListeners();
      // WidgetsBindingCompatible.instance?.addPostFrameCallback(
      //     (timeStamp) => Navigator.popUntil(context, (route) => route.isFirst));
    })
    ..on<ParticipantEvent>((event) {
      print('Participant event');
      // sort participants on many track events as noted in documentation linked above
      // _sortParticipants();
      _onRoomEvent();
    })
    ..on<RoomRecordingStatusChanged>((event) {
      // context.showRecordingStatusChangedDialog(event.activeRecording);
      _isRecording = !_isRecording;
      notifyListeners();
    })
    ..on<RoomAttemptReconnectEvent>((event) {
      print(
          'Attempting to reconnect ${event.attempt}/${event.maxAttemptsRetry}, '
          '(${event.nextRetryDelaysInMs}ms delay until next attempt)');
    })
    ..on<LocalTrackSubscribedEvent>((event) {
      print('Local track subscribed: ${event.trackSid}');
    })
    // ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
    // ..on<LocalTrackUnpublishedEvent>((_) => _sortParticipants())
    // ..on<TrackSubscribedEvent>((_) => _sortParticipants())
    // ..on<TrackUnsubscribedEvent>((_) => _sortParticipants())
    // ..on<TrackE2EEStateEvent>()
    ..on<ParticipantNameUpdatedEvent>((event) {
      print(
          'Participant name updated: ${event.participant.identity}, name => ${event.name}');
    })
    ..on<ParticipantMetadataUpdatedEvent>((event) {
      print(
          'Participant metadata updated: ${event.participant.identity}, metadata => ${event.metadata}');
    })
    ..on<RoomMetadataChangedEvent>((event) {
      print('Room metadata changed: ${event.metadata}');
    })
    ..on<DataReceivedEvent>((event) {
      String decoded = 'Failed to decode';
      try {
        decoded = utf8.decode(event.data);
      } catch (err) {
        print('Failed to decode: $err');
      }
      // context.showDataReceivedDialog(decoded);
    });

  void _onParticipantEvent(ParticipantEvent event) {
    if (event is TrackSubscribedEvent || event is TrackUnsubscribedEvent) {
      notifyListeners();
    }
  }

  void _sortParticipants() {
    List<ParticipantTrack> userMediaTracks = [];
    List<ParticipantTrack> screenTracks = [];
    for (var participant in _room.remoteParticipants.values) {
      for (var t in participant.videoTrackPublications) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: participant,
            type: ParticipantTrackType.kScreenShare,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(participant: participant));
        }
      }
    }
    // sort speakers for the grid
    userMediaTracks.sort((a, b) {
      // loudest speaker first
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        if (a.participant.audioLevel > b.participant.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.participant.joinedAt.millisecondsSinceEpoch -
          b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipantTracks =
        _room.localParticipant?.videoTrackPublications;
    if (localParticipantTracks != null) {
      for (var t in localParticipantTracks) {
        if (t.isScreenShare) {
          // if (lkPlatformIs(PlatformType.iOS)) {
          //   if (!_flagStartedReplayKit) {
          //     _flagStartedReplayKit = true;

          //     ReplayKitChannel.startReplayKit();
          //   }
          // }
          screenTracks.add(ParticipantTrack(
            participant: _room.localParticipant!,
            type: ParticipantTrackType.kScreenShare,
          ));
        } else {
          // if (lkPlatformIs(PlatformType.iOS)) {
          //   if (_flagStartedReplayKit) {
          //     _flagStartedReplayKit = false;

          //     ReplayKitChannel.closeReplayKit();
          //   }
          // }

          userMediaTracks
              .add(ParticipantTrack(participant: _room.localParticipant!));
        }
      }
    }
    participantTracks = [...screenTracks, ...userMediaTracks];
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
        bool hasCapturePermission = await Helper.requestCapturePermission();
        if (!hasCapturePermission) {
          return;
        }
        await requestBackgroundPermission();
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

  requestBackgroundPermission([bool isRetry = false]) async {
    // Required for android screenshare.
    try {
      bool hasPermissions = await FlutterBackground.hasPermissions;
      if (!isRetry) {
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Screen Sharing',
          notificationText: 'Call App is sharing the screen.',
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );
        hasPermissions =
            await FlutterBackground.initialize(androidConfig: androidConfig);
      }
      if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.enableBackgroundExecution();
      }
    } catch (e) {
      if (!isRetry) {
        return await Future<void>.delayed(const Duration(seconds: 1),
            () => requestBackgroundPermission(true));
      }
      print('could not publish video: $e');
    }
  }

  Participant? get activeSpeaker {
    return _room.activeSpeakers.isNotEmpty ? _room.activeSpeakers.first : null;
  }

  List<Participant> get participants {
    return [..._room.remoteParticipants.values, _room.localParticipant!];
  }

  VideoTrack? getVideoTrack(Participant participant) {
    // Check for an active screen share track
    final screenShareTrack = participant.videoTrackPublications.firstWhere(
      (track) => track.track?.source == TrackSource.screenShareVideo,
    );

    // Check for an active camera video track
    final cameraTrack = participant.videoTrackPublications.firstWhere(
      (track) => track.track?.source == TrackSource.camera,
    );

    // Return screen share if available, else camera
    return screenShareTrack.track as VideoTrack? ??
        cameraTrack.track as VideoTrack?;
  }

  void disconnect() async {
    _room.removeListener(_onRoomEvent);
    await _listener.dispose();
    _room.dispose();
    _isConnected = false;
    notifyListeners();
  }
}
