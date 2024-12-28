import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as Io;

class WebRtcService {
  late Io.Socket _socket;
  // RTCPeerConnection instances
  final Map<String, RTCPeerConnection> _peerConnections = {};

  // Media stream
  late MediaStream _localStream;

  final Map<String, MediaStream> _remoteStreams = {};

  // Initialize local renderer
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  final String peerId;
  final String username;
  final String callId;

  WebRtcService({
    required this.peerId,
    required this.username,
    required this.callId,
  });

  // Event callbacks
  Function()? onRemoteStreamUpdate;
  Function()? onLocalStreamUpdate;
  Function(String)? onParticipantLeft;

  void initialize() {
    _socket = Io.io(
      // 'http://10.0.2.2:3000',
      // 'http://127.0.0.1:3000',
      "https://local.cloudnotte.com",
      Io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .build(),
    );
    _socket.onConnect((_) {
      _socket.emit("join-group-call",
          {"username": username, "peerId": peerId, "callID": callId});
    });

    _socket.on('new-participant', (data) {
      final newPeerId = data['peerId'];
      _createOffer(newPeerId);
      print('New participant: ${data['peerId']}');
    });

    _socket.on('joined-group-call', (data) async {
      // final remoteSocketId = data['peerId'];
      final participants = data['participants'] as List<dynamic>;
      print("participants: $participants");
      for (var participant in participants) {
        print("LOOPING PARTICIPANTS");
        _createOffer(participant as String);
      }
      print('join call ${data}');
    });

    _socket.on('leave-group-call', (data) {
      final remoteSocketId = data['socketID'];
      print('Participant left: $remoteSocketId');
      _peerConnections[remoteSocketId]?.close();
      _peerConnections.remove(remoteSocketId);
      _removeRemoteStream(remoteSocketId);
      onParticipantLeft?.call(remoteSocketId);
      _socket.disconnect();
    });

    _socket.on('offer', (data) async {
      final remotePeerId = data['peerId'];
      final offer = data['offer'];
      final description = RTCSessionDescription(offer['sdp'], 'offer');
      await _createAnswer(remotePeerId, description);
      print("OFFER RECEIVED $data");
    });

    _socket.on('answer', (data) async {
      final remotePeerId = data['peerId'];
      final answer = data['answer'];
      _peerConnections[remotePeerId]?.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], "answer"));
      print("ANSWER RECEIVED $data");
    });

    _socket.on('candidate', (data) async {
      final remotePeerId = data['peerId'];
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      // if (_peerConnections[remotePeerId] != null) {
      //   print("No peer connection found for $remotePeerId");
      // }
      // _peerConnections[remotePeerId]?.addCandidate(candidate);

      if (_peerConnections.containsKey(remotePeerId)) {
        _peerConnections[remotePeerId]?.addCandidate(candidate);
      } else {
        print(
            "Peer connection not found for $remotePeerId. Queueing candidate.");
        await Future.delayed(const Duration(seconds: 1), () {
          _peerConnections[remotePeerId]?.addCandidate(candidate);
        });
      }
      print("CANDIDATE ADDED");
    });
    _socket.onDisconnect((data) {
      print("DISCONNECTED");
    });

    initializeLocalStream();
  }

  void dispose() {
    _socket.disconnect();
    // _localStream.dispose();
    _peerConnections.values.forEach((pc) => pc.close());
    _peerConnections.clear();
    localRenderer.dispose();
    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    _socket.dispose();
  }

  void _addRemoteStream(String remotePeerID, MediaStream stream) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    renderer.srcObject = stream;
    _remoteRenderers[remotePeerID] = renderer;
    _remoteStreams[remotePeerID] = stream;
    onRemoteStreamUpdate?.call();
  }

  void _removeRemoteStream(String remotePeerID) {
    if (_remoteRenderers.containsKey(peerId)) {
      _remoteRenderers[remotePeerID]?.dispose();
      _remoteRenderers.remove(remotePeerID);
      onRemoteStreamUpdate?.call();
    }
  }

  // Initialize local media stream
  // Future<void> initializeLocalStream({bool isScreenSharing = false}) async {
  //   await localRenderer.initialize();
  //   _localStream = await navigator.mediaDevices.getUserMedia({
  //     'audio': true,
  //     'video': true,
  //   });
  //   localRenderer.srcObject = _localStream;
  //   onLocalStreamUpdate?.call();
  // }
  Future<void> initializeLocalStream({bool isScreenSharing = false}) async {
    try {
      await localRenderer.initialize();
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });
      localRenderer.srcObject = _localStream;
      print("Local stream initialized.");
      onLocalStreamUpdate?.call();
    } catch (e) {
      print("Error initializing local stream: $e");
    }
  }

  MediaStream get localStream => _localStream;

  // Create a new peer connection
  Future<RTCPeerConnection> _createPeerConnection(String remoteSocketId) async {
    if (_peerConnections.containsKey(remoteSocketId)) {
      print("Peer connection already exists for $remoteSocketId");
      return _peerConnections[remoteSocketId] as RTCPeerConnection;
    }
    try {
      final config = <String, dynamic>{
        "bundlePolicy": "balanced",
        'iceServers': [
          {
            'urls': [
              'stun:stun4.l.google.com:19302',
              "stun:stun1.l.google.com:19302"
            ]
          },
          {
            'urls': [
              'stun:stun2.l.google.com:19302',
              "stun:stun3.l.google.com:19302"
            ]
          },
        ],
        "sdpSemantics": "unified-plan"
      };

      final peerConnection = await createPeerConnection(config);
      print("PeerConnection created for $remoteSocketId.");

      _peerConnections[remoteSocketId] = peerConnection;

      // Add state logging
      peerConnection.onSignalingState = (state) {
        print("Signaling state for $remoteSocketId: $state");
      };

      peerConnection.onIceConnectionState = (state) {
        print("ICE connection state for $remoteSocketId: $state");
      };

      peerConnection.onConnectionState = (state) {
        print("Peer connection state for $remoteSocketId: $state");
      };
      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        _socket.emit('candidate', {
          "targetId": remoteSocketId,
          'type': 'candidate',
          'candidate': candidate.toMap(),
          'peerId': peerId,
          "callID": callId,
        });
        print('Candidate emitted: ${{
          'callID': callId,
          'peerId': peerId,
          'targetId': remoteSocketId,
          'candidate': candidate.toMap(),
        }}');
      };

      peerConnection.onTrack = (RTCTrackEvent event) {
        print("Received track for $remoteSocketId.");
        if (event.streams.isNotEmpty) {
          // _remoteStreams[remoteSocketId] = event.streams[0];
          _addRemoteStream(remoteSocketId, event.streams[0]);
          // onRemoteStreamUpdate?.call();
        }
      };
      // Store the connection
      // _peerConnections[remoteSocketId] = peerConnection;
      debugPrint("CREATE CONNECTION");
      return peerConnection;
    } catch (e) {
      print("Error creating peer connection: $e");
      rethrow;
    }
  }

  //Create Offer
  Future<void> _createOffer(String remotePeerId) async {
    try {
      final peerConnection = await _createPeerConnection(remotePeerId);

      // Only create an offer if in a stable state
      if (peerConnection.signalingState !=
          RTCSignalingState.RTCSignalingStateStable) {
        print("Cannot create offer in state: ${peerConnection.signalingState}");
        return;
      }

      final offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      _socket.emit('offer', {
        'callID': callId,
        'peerId': peerId,
        'targetId': remotePeerId,
        'offer': offer.toMap(),
      });
      print('Offer emitted: ${{
        'callID': callId,
        'peerId': peerId,
        'targetId': remotePeerId,
        'offer': offer.toMap(),
      }}');
    } catch (error) {
      print("CREATE OFFER ERROR: $error");
    }
  }

  // Future<void> _createAnswer(
  //     String remotePeerId, RTCSessionDescription offer) async {
  //   final peerConnection = await _createPeerConnection(remotePeerId);
  //   // Avoid setting remote description in the wrong state
  //   if (peerConnection.signalingState == 'have-local-offer') {
  //     print(
  //         "Delaying setting remote description due to signaling state: ${peerConnection.signalingState}");
  //     // await peerConnection.setLocalDescription(); // Rollback
  //     // return;
  //   }
  //   await peerConnection.setRemoteDescription(offer);
  //   final answer = await peerConnection.createAnswer();
  //   await peerConnection.setLocalDescription(answer);

  //   _socket.emit('answer', {
  //     'callID': callId,
  //     'peerId': peerId,
  //     'targetId': remotePeerId,
  //     'answer': answer.toMap(),
  //   });
  //   print('Answer emitted: ${{
  //     'callID': callId,
  //     'peerId': peerId,
  //     'targetId': remotePeerId,
  //     'answer': answer.toMap(),
  //   }}');
  // }
  Future<void> _createAnswer(
      String remotePeerId, RTCSessionDescription offer) async {
    try {
      final peerConnection = await _createPeerConnection(remotePeerId);
      if (peerConnection.signalingState !=
          RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
        print(
            "Cannot set remote description in state: ${peerConnection.signalingState}");
        return;
      }
      await peerConnection.setRemoteDescription(offer);

      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      print("Created answer: ${answer.toMap()}");
      _socket.emit('answer', {
        'callID': callId,
        'peerId': peerId,
        'targetId': remotePeerId,
        'answer': answer.toMap(),
      });
    } catch (error) {
      print("Error creating answer: $error");
    }
  }

  List<RTCVideoRenderer> getRemoteRenderers() {
    return _remoteRenderers.values.toList();
  }

  // Start a call by creating an offer
  Future<void> startCall(String remoteSocketId) async {
    try {
      final connection = await _createPeerConnection(remoteSocketId);

      final offer = await connection.createOffer();
      await connection.setLocalDescription(offer);

      _socket.emit('offer', {
        'type': 'offer',
        'offer': offer.toMap(),
        'targetId': remoteSocketId,
        'peerId': peerId,
        'callID': remoteSocketId,
      });
      _peerConnections[remoteSocketId] = connection;
    } catch (error) {
      print("START CALL ERROR ${error.toString()}");
    }
  }
}
