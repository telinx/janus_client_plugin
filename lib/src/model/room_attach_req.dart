// {
//         "videoroom" : "attached",
//         "room" : <room ID>,
//         "feed" : <publisher ID>,
//         "display" : "<the display name of the publisher, if any>"
// }

import 'package:flutter/material.dart';

class RoomAttachReq {

  String videoroom;

  int room;

  dynamic feed;

  String display;

  RoomAttachReq({
    this.videoroom = 'attach', 
    @required this.room, 
    this.feed, 
    this.display,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'videoroom': this.videoroom, 
      'room': this.room,
      'feed': this.feed,
      'display': this.display,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

}