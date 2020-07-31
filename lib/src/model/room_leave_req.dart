import 'package:flutter/material.dart';


// {
//         "request" : "leave"
// }

// {
//         "videoroom" : "event",
//         "leaving" : "ok"
// }

// {
//         "videoroom" : "event",
//         "room" : <room ID>,
//         "leaving : <unique ID of the participant who left>
// }

class RoomLeaveReq {

  String request;   // join leave

  RoomLeaveReq({
   this.request = 'leave', 
  });

  Map<String, dynamic> toMap() {
    return {
      'request': this.request, 
    };
  }
}