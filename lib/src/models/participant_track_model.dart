import 'package:livekit_client/livekit_client.dart';

enum ParticipantTrackType { kUserMedia, kScreenShare }

class ParticipantTrack {
  final Participant participant;
  final ParticipantTrackType type;

  ParticipantTrack({
    required this.participant,
    this.type = ParticipantTrackType.kUserMedia,
  });
}
