import 'package:call_app_livekit/src/screens/call_screen.dart';
import 'package:call_app_livekit/src/screens/landing_handler.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingHandler(),
    ),
    GoRoute(
      path: '/call_screen',
      builder: (context, state) {
        final param = state.extra as Map<String, String>;
        return CallScreen(
          callId: param['callId'],
          username: param['username'],
          peerId: param['peerId'],
        );
      },
    ),
  ],
);