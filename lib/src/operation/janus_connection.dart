import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/webrtc.dart';

import '../ice_server.dart';

/// 将流加入之后的执行
typedef void OnAddStreamCallback(JanusConnection connection, MediaStream stream);

/// ice发送之后的执行
typedef void OnIceCandidateCallback(JanusConnection connection, RTCIceCandidate candidate);


const Map<String, dynamic> _config = {
  'mandatory': {},
  'optional': [
    {'DtlsSrtpKeyAgreement': true},
  ],
};

const Map<String, dynamic> _constraints = {
  'mandatory': {
    'OfferToReceiveAudio': true,
    'OfferToReceiveVideo': true,
  },
  'optional': [],
};

const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'url': 'turn:turn.al.mancangyun:3478',
        'username': 'root',
        'credential': 'mypasswd'
      },
    ]
  };

/// webrtc步骤
/// 1. 获得本地媒体
/// 2. 创建对等连接
/// 3. 关联媒体和数据
/// 4. 交换会话描述 createOffer createAnswer sdp

/// janus连接对象
class JanusConnection {

  int handleId;                   // janus句柄ID

  String display;                 // 昵称

  RTCPeerConnection _connection;  // 当前peer连接对象

  RTCVideoRenderer remoteRenderer;  // 远程媒体数据渲染器

  MediaStream remoteStream;  // 远程媒体数据渲染器

  List<RTCIceServer> iceServers;

  OnAddStreamCallback onAddStream;

  OnIceCandidateCallback onIceCandidate;


  JanusConnection({@required this.handleId, this.iceServers, this.display}) {
    this.remoteRenderer = RTCVideoRenderer();
    this.remoteRenderer.mirror = true;
  }

  /// init连接，init远程媒体数据渲染器
  Future<void> initConnection() async{
    await this.remoteRenderer.initialize();
    await createConnection();
  }

  void disConnect(){
    debugPrint('JanusConnection disConnect===$display====$handleId');
    this._connection.close();
    this.remoteStream?.dispose();
    this.remoteRenderer?.dispose();
  }

  /// 设置本地会话描述添加到RTCPeerConnection
  Future<RTCSessionDescription> createOffer({Map<String, dynamic> constraints = _constraints}) async {
    RTCSessionDescription sdp = await this._connection.createOffer(constraints);
    this._connection.setLocalDescription(sdp);
    return sdp;
  }

  /// 将远程会话描述添加到RTCPeerConnection
  RTCSessionDescription setRemoteDescription(Map<String, dynamic> jsep){
    RTCSessionDescription sdp = RTCSessionDescription(jsep['sdp'], jsep['type']);
    this._connection.setRemoteDescription(sdp);
    return sdp;
  }

  /// 将本地流添加到RTCPeerConnection
  void addLocalStream(MediaStream localStream) {
    this._connection.addStream(localStream);
  }

  /// 回复sdp
  Future<RTCSessionDescription> createAnswer({Map<String, dynamic> constraints = _constraints}) async {
    RTCSessionDescription sdp = await this._connection.createAnswer(constraints);
    // 通过setLocalDescription想浏览器通知会话描述，并将其发送之远程对等端，从而发起呼叫
    this._connection.setLocalDescription(sdp);
    return sdp;
  }

  Future createConnection() async{

    Map<String, dynamic> configuration = _iceServers;
    if(null != this.iceServers && this.iceServers.length > 0){
      configuration = {'iceServers': this.iceServers.map((e) => e.toMap()).toList(),};
    }
    this._connection = await createPeerConnection(configuration,_config);
    // ice加入后处理
    this._connection.onIceCandidate = (candidate) => this.onIceCandidate(this, candidate);
    // stream add后处理
    this._connection.onAddStream = (stream) => this.onAddStream(this, stream);
    // stream remove后处理
    this._connection.onRemoveStream = (stream) {};
    // channel　数据传输处理
    this._connection.onDataChannel = (channel) {};

    return this._connection;

  }

}