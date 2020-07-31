// {
//         "request" : "join",
//         "ptype" : "subscriber",
//         "room" : <unique ID of the room to subscribe in>,
//         "feed" : <unique ID of the publisher to subscribe to; mandatory>,
//         "private_id" : <unique ID of the publisher that originated this request; optional, unless mandated by the room configuration>,
//         "close_pc" : <true|false, depending on whether or not the PeerConnection should be automatically closed when the publisher leaves; true by default>,
//         "audio" : <true|false, depending on whether or not audio should be relayed; true by default>,
//         "video" : <true|false, depending on whether or not video should be relayed; true by default>,
//         "data" : <true|false, depending on whether or not data should be relayed; true by default>,
//         "offer_audio" : <true|false; whether or not audio should be negotiated; true by default if the publisher has audio>,
//         "offer_video" : <true|false; whether or not video should be negotiated; true by default if the publisher has video>,
//         "offer_data" : <true|false; whether or not datachannels should be negotiated; true by default if the publisher has datachannels>,
//         "substream" : <substream to receive (0-2), in case simulcasting is enabled; optional>,
//         "temporal" : <temporal layers to receive (0-2), in case simulcasting is enabled; optional>,
//         "fallback" : <How much time (in us, default 250000) without receiving packets will make us drop to the substream below>,
//         "spatial_layer" : <spatial layer to receive (0-2), in case VP9-SVC is enabled; optional>,
//         "temporal_layer" : <temporal layers to receive (0-2), in case VP9-SVC is enabled; optional>
// }

class RoomSubscriberReq {

  String request;

  String ptype;

  int room;

  String feed;

  String privateId;

  bool closePC;

  bool audio;

  bool video;

  bool data;

  bool offerAudio;

  bool offerVideo;

  bool offerData;

  dynamic substream;

  dynamic temporal;

  dynamic fallback;

  dynamic spatialLayer;

  dynamic temporalLayer;

  RoomSubscriberReq({
    this.request = 'join', 
    this.ptype = 'subscriber', 
    this.room, 
    this.feed,
    this.privateId, 
    this.closePC,
    this.audio,
    this.video,
    this.data,
    this.offerAudio,
    this.offerVideo,
    this.offerData,
    this.substream,
    this.temporal,
    this.fallback,
    this.spatialLayer,
    this.temporalLayer,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'request': this.request, 
      'ptype': this.ptype,
      'room': this.room,
      'feed': this.feed,
      'private_id': this.privateId,
      'close_pc': this.closePC,
      'audio': this.audio,
      'video': this.video,
      'data': this.data,
      'offer_audio': this.offerAudio,
      'offer_video': this.offerVideo,
      'offer_data': this.offerData,
      'substream': this.substream,
      'temporal': this.temporal,
      'fallback': this.fallback,
      'spatial_layer': this.spatialLayer,
      'temporal_layer': this.temporalLayer,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

}