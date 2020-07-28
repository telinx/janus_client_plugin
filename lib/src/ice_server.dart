import 'package:flutter/material.dart';

class RTCIceServer {
  String username;
  String credential;
  String url;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  RTCIceServer({
    @required this.username,
    @required this.credential,
    @required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RTCIceServer &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          credential == other.credential &&
          url == other.url);

  @override
  int get hashCode => username.hashCode ^ credential.hashCode ^ url.hashCode;

  @override
  String toString() {
    return 'RTCIceServer{' +
        ' username: $username,' +
        ' credential: $credential,' +
        ' url: $url,' +
        '}';
  }

  RTCIceServer copyWith({
    String username,
    String credential,
    String url,
  }) {
    return new RTCIceServer(
      username: username ?? this.username,
      credential: credential ?? this.credential,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': this.username,
      'credential': this.credential,
      'url': this.url,
    };
  }

  factory RTCIceServer.fromMap(Map<String, dynamic> map) {
    return new RTCIceServer(
      username: map['username'] as String,
      credential: map['credential'] as String,
      url: map['url'] as String,
    );
  }

//</editor-fold>
}
