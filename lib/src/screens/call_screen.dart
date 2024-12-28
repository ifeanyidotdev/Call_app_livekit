import 'package:call_app_livekit/src/providers/live_kit_provider.dart';
import 'package:call_app_livekit/src/services/web_rtc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  static const routeName = '/call_screen';
  final String? callId;
  final String? username;
  final String? peerId;

  const CallScreen(
      {super.key,
      required this.callId,
      required this.username,
      required this.peerId});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  WebRtcService? _webRtcService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  bool _isInitializing = true;

  @override
  void initState() {
    // _initialize();
    super.initState();
    // _initializeRenderer();
  }

  void _initializeRenderer() async {
    await _localRenderer.initialize();
    MediaStream stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localRenderer.srcObject = stream;
  }

  Future<void> _initialize() async {
    setState(() => _isInitializing = true);

    print("INITIALIZING");
    // await _localRenderer.initialize();
    // await _webRtcService.initializeLocalStream();
    try {
      _webRtcService = WebRtcService(
        username: widget.username ?? "",
        callId: widget.callId ?? "",
        peerId: widget.peerId ?? "",
      );
      _webRtcService?.onLocalStreamUpdate = _updateUI;
      _webRtcService?.onRemoteStreamUpdate = _updateUI;
      _webRtcService?.initialize();
    } catch (e) {
      print("ERROR ${e.toString()}");
    }
    // _webRtcService.onLocalStream = (stream) {
    //   setState(() {
    //     _localRenderer.srcObject = stream;
    //     print("DONE HERE");
    //   });
    // };
    // Handle remote stream
    // _webRtcService.onRemoteStream = (remoteStream) async {
    //   // if (!_remoteRenderers.containsKey(remoteSocketId)) {
    //   //   final renderer = RTCVideoRenderer();
    //   //   await renderer.initialize();
    //   //   renderer.srcObject = stream;
    //   //   setState(() {
    //   //     _remoteRenderers[remoteSocketId] = renderer;
    //   //   });
    //   // }
    //   setState(() {
    //     for (var entry in remoteStream.entries) {
    //       if (!_remoteRenderers.containsKey(entry.key)) {
    //         final renderer = RTCVideoRenderer();
    //         renderer.initialize();
    //         renderer.srcObject = entry.value;
    //         _remoteRenderers[entry.key] = renderer;
    //       }
    //     }
    //   });
    // };
    setState(() => _isInitializing = false);
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _localRenderer.dispose();
    _remoteRenderers.values.forEach((renderer) => renderer.dispose());
    _webRtcService?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveKitController = Provider.of<LiveKitController>(context);

    return Scaffold(
      appBar: AppBar(title: Text('LiveKit Meet')),
      body: liveKitController.isConnected
          ? Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Text('You are connected to the room'),
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
                      onPressed: liveKitController.disconnect,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            )
          : Center(
              child: ElevatedButton(
                onPressed: () async {
                  await liveKitController.connectToRoom("", "");
                },
                child: Text('Join Room'),
              ),
            ),
    );

    // if (_isInitializing) {
    //   return Scaffold(
    //     appBar: AppBar(title: Text("Group Call")),
    //     body: Center(
    //       child: CircularProgressIndicator(),
    //     ),
    //   );
    // }

    // if (_webRtcService == null) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text("Group Call")),
    //     body: const Center(
    //       child: Text(
    //         "Failed to initialize the call. Please try again.",
    //         style: TextStyle(fontSize: 18),
    //         textAlign: TextAlign.center,
    //       ),
    //     ),
    //   );
    // }
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('${widget.callId}'),
    //   ),
    //   body: SafeArea(
    //     child: Column(
    //       children: [
    //         Expanded(
    //           child: GridView.builder(
    //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //               crossAxisCount: 2,
    //             ),
    //             itemCount: _webRtcService!.getRemoteRenderers().length,
    //             itemBuilder: (context, index) {
    //               return RTCVideoView(
    //                 _webRtcService!.getRemoteRenderers()[index],
    //                 objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    //               );
    //             },
    //           ),
    //         ),
    //         SizedBox(
    //             height: 200,
    //             child: RTCVideoView(_webRtcService!.localRenderer)),
    //         // ElevatedButton(
    //         //   onPressed: () {
    //         //     _webRtcService.startCall(widget.callId ?? "");
    //         //   },
    //         //   child: const Text('Start Call'),
    //         // ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
