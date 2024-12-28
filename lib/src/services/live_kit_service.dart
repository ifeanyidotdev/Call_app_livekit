import 'package:livekit_client/livekit_client.dart';

class LiveKitService {
  late final LiveKitClient _client;
  Room? _room;

  LiveKitService(String url, String token) {
    _client = LiveKitClient();
  }
}
