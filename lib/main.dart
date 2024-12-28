import 'package:call_app_livekit/src/config/router.dart';
import 'package:call_app_livekit/src/providers/live_kit_provider.dart';
import 'package:call_app_livekit/src/services/signaling_service.dart';
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:provider/provider.dart';

Future<void> _initializeAndroidAudioSettings() async {
  WidgetsFlutterBinding.ensureInitialized();
  await webrtc.WebRTC.initialize(options: {
    'androidAudioConfiguration': webrtc.AndroidAudioConfiguration.media.toMap()
  });
  webrtc.Helper.setAndroidAudioConfiguration(
    webrtc.AndroidAudioConfiguration.media,
  );
}

void main() async {
  await _initializeAndroidAudioSettings();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SignalingServiceProvider(),
        ),
        ChangeNotifierProvider(create: (_) => LiveKitController())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
