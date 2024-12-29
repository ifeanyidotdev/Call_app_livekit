import 'dart:convert';
import 'dart:ffi';

import 'package:call_app_livekit/src/providers/live_kit_provider.dart';
import 'package:call_app_livekit/src/services/web_rtc_service.dart';
import 'package:call_app_livekit/src/widgets/no_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  static const routeName = '/call_screen';
  final String? callId;
  final String? username;
  final String? peerId;
  final Room room;
  final EventsListener<RoomEvent> listener;

  const CallScreen({
    super.key,
    required this.callId,
    required this.username,
    required this.peerId,
    required this.room,
    required this.listener,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  EventsListener<RoomEvent> get _listener => widget.listener;
  bool get fastConnection => widget.room.engine.fastConnectOptions != null;
  List<Participant> participants = [];

  @override
  void initState() {
    // _initialize();
    super.initState();
    widget.room.addListener(_onRoomDidUpdate);
    _setUpListeners();
    // _initializeRenderer();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  void _sortParticipants() {
    List<Participant> participants = [];
    participants.addAll(widget.room.remoteParticipants.values);
    // sort speakers for the grid
    participants.sort((a, b) {
      // loudest speaker first
      if (a.isSpeaking && b.isSpeaking) {
        if (a.audioLevel > b.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.hasVideo != b.hasVideo) {
        return a.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.joinedAt.millisecondsSinceEpoch -
          b.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipant = widget.room.localParticipant;
    if (localParticipant != null) {
      if (participants.length > 1) {
        participants.insert(1, localParticipant);
      } else {
        participants.add(localParticipant);
      }
    }
    setState(() {
      this.participants = participants;
    });
  }

  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((event) async {
      if (event.reason != null) {
        print('Room disconnected: reason => ${event.reason}');
        // WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) =>
        //     Navigator.popUntil(context, (route) => route.isFirst));
      }
      WidgetsBindingCompatible.instance
          ?.addPostFrameCallback((timeStamp) => context.pop());
    })
    ..on<ParticipantEvent>((event) {
      print('Participant event');
      // sort participants on many track events as noted in documentation linked above
      // _sortParticipants();
      _onRoomDidUpdate();
    })
    ..on<RoomRecordingStatusChanged>((event) {
      // context.showRecordingStatusChangedDialog(event.activeRecording);
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

  @override
  void dispose() {
    (() async {
      widget.room.removeListener(_onRoomDidUpdate);
      await _listener.dispose();
      await widget.room.dispose();
    })();
    super.dispose();
  }

  void _onRoomDidUpdate() {
    _sortParticipants();
  }

  @override
  Widget build(BuildContext context) {
    final liveKitController = Provider.of<LiveKitController>(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Meet'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: participants.length == 2
                      ? 0
                      : 2, // Adjust for larger grids
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                ),
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final videoTrack =
                      participant.videoTrackPublications.isNotEmpty
                          ? participant.videoTrackPublications.first.track
                          : null;
                  return SizedBox(
                    width: 300,
                    height: 300,
                    child: Card(
                      color: Colors.black12,
                      child: Stack(
                        children: [
                          Expanded(
                            flex: 1,
                            child: videoTrack != null
                                ? SizedBox(
                                    width: 250,
                                    height: 300,
                                    child: VideoTrackRenderer(
                                      videoTrack as VideoTrack,
                                      fit: RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitCover,
                                    ),
                                  )
                                : const NoVideoWidget(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  participant.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Icon(
                                  participant.isSpeaking
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: participant.isSpeaking
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(liveKitController.isMicEnabled
                      ? Icons.mic
                      : Icons.mic_off),
                  onPressed: liveKitController.toggleMic,
                ),
                IconButton(
                  icon: Icon(liveKitController.isCameraEnabled
                      ? Icons.videocam
                      : Icons.videocam_off),
                  onPressed: liveKitController.toggleCamera,
                ),
                IconButton(
                  icon: Icon(Icons.screen_share),
                  onPressed: liveKitController.startScreenShare,
                ),
                IconButton(
                  icon: Icon(Icons.call_end_outlined),
                  onPressed: () async {
                    liveKitController.disconnect();
                    if (!liveKitController.isConnected) {
                      context.pop();
                    }
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ],
        )
        // : Center(
        //     child: ElevatedButton(
        //       onPressed: () async {
        //         await liveKitController.connectToRoom("", "");
        //       },
        //       child: Text('Join Room'),
        //     ),
        //   ),
        );
  }
}
