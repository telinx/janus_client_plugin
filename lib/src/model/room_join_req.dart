// {
//         "request" : "join",
//         "ptype" : "Join",
//         "room" : <unique ID of the room to join>,
//         "id" : <unique ID to register for the Join; optional, will be chosen by the plugin if missing>,
//         "display" : "<display name for the Join; optional>",
//         "token" : "<invitation token, in case the room has an ACL; optional>"
// }


// {
//         "videoroom" : "joined",
//         "room" : <room ID>,
//         "description" : <description of the room, if available>,
//         "id" : <unique ID of the participant>,
//         "private_id" : <a different unique ID associated to the participant; meant to be private>,
//         "Joins" : [
//                 {
//                         "id" : <unique ID of active Join #1>,
//                         "display" : "<display name of active Join #1, if any>",
//                         "audio_codec" : "<audio codec used by active Join #1, if any>",
//                         "video_codec" : "<video codec used by active Join #1, if any>",
//                         "simulcast" : "<true if the Join uses simulcast (VP8 and H.264 only)>",
//                         "talking" : <true|false, whether the Join is talking or not (only if audio levels are used)>,
//                 },
//                 // Other active Joins
//         ],
//         "attendees" : [         // Only present when notify_joining is set to TRUE for rooms
//                 {
//                         "id" : <unique ID of attendee #1>,
//                         "display" : "<display name of attendee #1, if any>"
//                 },
//                 // Other attendees
//         ]
// }


/// https://janus.conf.meetecho.com/docs/videoroom.html
import 'package:flutter/material.dart';

class RoomJoinReq {

  String request;   // join 

  String ptype;     // publisher

  int room;

  String id;

  String display;

  String token;

  RoomJoinReq({
    this.request = 'join', 
    this.ptype = 'publisher', 
    this.room, 
    this.id,
    this.display, 
    this.token, 
  });


  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'request': this.request, 
      'ptype': this.ptype,
      'id': this.id,
      'display': this.display,
      'token': this.token,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }
}