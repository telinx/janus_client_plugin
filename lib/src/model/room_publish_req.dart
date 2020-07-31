// {
//         "request" : "publish",
//         "audio" : <true|false, depending on whether or not audio should be relayed; true by default>,
//         "video" : <true|false, depending on whether or not video should be relayed; true by default>,
//         "data" : <true|false, depending on whether or not data should be relayed; true by default>,
//         "audiocodec" : "<audio codec to prefer among the negotiated ones; optional>",
//         "videocodec" : "<video codec to prefer among the negotiated ones; optional>",
//         "bitrate" : <bitrate cap to return via REMB; optional, overrides the global room value if present>,
//         "record" : <true|false, whether this publisher should be recorded or not; optional>,
//         "filename" : "<if recording, the base path/file to use for the recording files; optional>",
//         "display" : "<new display name to use in the room; optional>",
//         "audio_level_average" : "<if provided, overrided the room audio_level_average for this user; optional>",
//         "audio_active_packets" : "<if provided, overrided the room audio_active_packets for this user; optional>"
// }

// {
//         "videoroom" : "event",
//         "configured" : "ok"
// }

// {
//         "videoroom" : "event",
//         "room" : <room ID>,
//         "publishers" : [
//                 {
//                         "id" : <unique ID of the new publisher>,
//                         "display" : "<display name of the new publisher, if any>",
//                         "audio_codec" : "<audio codec used the new publisher, if any>",
//                         "video_codec" : "<video codec used by the new publisher, if any>",
//                         "simulcast" : "<true if the publisher uses simulcast (VP8 and H.264 only)>",
//                         "talking" : <true|false, whether the publisher is talking or not (only if audio levels are used)>,
//                 }
//         ]
// }


// {
//         "request" : "publish",
//         "audio" : <true|false, depending on whether or not audio should be relayed; true by default>,
//         "video" : <true|false, depending on whether or not video should be relayed; true by default>,
//         "data" : <true|false, depending on whether or not data should be relayed; true by default>,
//         "audiocodec" : "<audio codec to prefer among the negotiated ones; optional>",
//         "videocodec" : "<video codec to prefer among the negotiated ones; optional>",
//         "bitrate" : <bitrate cap to return via REMB; optional, overrides the global room value if present>,
//         "record" : <true|false, whether this publisher should be recorded or not; optional>,
//         "filename" : "<if recording, the base path/file to use for the recording files; optional>",
//         "display" : "<new display name to use in the room; optional>",
//         "audio_level_average" : "<if provided, overrided the room audio_level_average for this user; optional>",
//         "audio_active_packets" : "<if provided, overrided the room audio_active_packets for this user; optional>"
// }
import 'package:flutter/cupertino.dart';

class RoomPublishReq {
  String request;   // publish unpublish configure
  bool audio;
  bool video;
  bool data;
  dynamic audiocodec;
  dynamic videocodec;
  dynamic bitrate;
  bool record;
  dynamic filename;
  String display;
  dynamic audioLevelAverage;
  dynamic audioActivePackets; 

  RoomPublishReq({
    this.request = 'publish',   
    this.audio,
    this.video,
    this.data,
    this.audiocodec,
    this.videocodec,
    this.bitrate,
    this.record,
    this.filename,
    this.display,
    this.audioActivePackets,
    this.audioLevelAverage,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map =  {
      'request': this.request, 
      'audio': this.audio,
      'video': this.video,
      'data': this.data,
      'audiocodec': this.audiocodec,
      'videocodec': this.videocodec,
      'bitrate': this.bitrate,
      'record': this.record,
      'filename': this.filename,
      'display': this.display,
      'audio_level_average': this.audioActivePackets,
      'audio_active_packets': this.audioLevelAverage,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

}