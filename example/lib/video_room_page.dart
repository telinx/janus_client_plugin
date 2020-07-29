

import 'package:flutter/material.dart';
import 'package:janus_client_plugin/janus_client_plugin.dart';
import 'package:flutter_webrtc/get_user_media.dart';
import 'package:flutter_webrtc/media_stream.dart';
import 'package:flutter_webrtc/rtc_peerconnection.dart';
import 'package:flutter_webrtc/rtc_session_description.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:random_string/random_string.dart';


class VideoRoomPage extends StatefulWidget {


  @override
  _VideoRoomPage createState() => _VideoRoomPage();
  
}

class _VideoRoomPage extends State<VideoRoomPage>{

  int room = 1234;
  // String url = 'wss://janus.onemandev.tech/websocket';
  String url = 'wss://janus.conf.meetecho.com/ws';
  bool withCredentials = false;
  String apiSecret = "SecureIt";
  String displayName = 'dumei';
  String pluginName = 'janus.plugin.videoroom';
  List<RTCIceServer> iceServers;
  // List<RTCIceServer> iceServers = <RTCIceServer>[
  //   RTCIceServer(
  //     url: "stun:40.85.216.95:3478",
  //     username: "onemandev",
  //     credential: "SecureIt"
  //   ),
  //   RTCIceServer(
  //     url: "turn:40.85.216.95:3478",
  //     username: "onemandev",
  //     credential: "SecureIt"
  //   )
  // ];

  JanusSignal _signal;

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream _localStream;

  String opaqueId = 'videoroomtest-${randomString(12)}';
  Map<int, JanusConnection> peerConnectionMap = <int, JanusConnection>{};
  RTCPeerConnection publisherPeerConnection;

  int selfHandleId = -1;

  int _mypvtid;

  @override
  void dispose() {

    this.peerConnectionMap?.forEach((key, jc) => jc.disConnect());
    this._localRenderer?.dispose();
    this._localStream?.dispose();
    this._signal?.disconnect();
    super.dispose();

  }

  @override
  void initState() {
    super.initState();
    this._signal = JanusSignal.getInstance(url: url, apiSecret: apiSecret, withCredentials: withCredentials);

    this._initRenderers();

     // 自定义janus回调event处理
    this.onMessage();
    /*
    * 1.连接websocket服务器，success
    * 2.janus　create session, success
    * 3.janus attach plugin,success
    * 4.janus videoroom join
    * 5.janus createOffer createAnswer
    * 6.janus　trickle ice
    */
    this.connect();
    this.createSessionAndAttach();
    
  }

  /// 初始化视图
  void _initRenderers() async{
    await this._localRenderer.initialize();
    this._localStream = await this.createStream();
    this._localRenderer.srcObject = this._localStream;
  }

  ///　janus信令event处理
  void onMessage() {
    this._signal.onMessage = (JanusHandle handle, Map plugin, Map jsep, JanusHandle feedHandle){
      String videoroom = plugin['videoroom'];
      if(videoroom == 'joined') {
        handle.onJoined(handle);
        this._mypvtid = plugin['private_id'];
      }

      List<dynamic> publishers = plugin['publishers'];
      if(publishers != null && publishers.length > 0) {
        publishers.forEach((publisher) {
          int feed = publisher['id'];
          String display = publisher['display'];
          this._signal.attach(
            plugin: this.pluginName, 
            opaqueId: this.opaqueId, 
            success: (Map<String, dynamic> data) {
              Map<String, dynamic> body = {
                "request": "join",
                'room': this.room,
                "ptype": "subscriber",
                'feed': feed
              };

              if(this._mypvtid != null) {
                body['private_id'] = this._mypvtid;
              }
              this._signal.joinRoom(
                data: data,
                body: body,
                feedId: feed,
                display: display,
                onRemoteJsep: (JanusHandle handle, Map<String, dynamic> jsep) {
                  // 订阅远程媒体，请求将远端流加入本地后，收到event回调执行onRemoteJsep
                  subscriberHandleRemoteJsep(handle, jsep);
                },
                onLeaving: (JanusHandle handle,){
                  // 移除远程媒体
                  this.peerConnectionMap[feed]?.disConnect();
                  this.peerConnectionMap.remove(feed);
                  setState(() {});
                }
              );
            },
            error: (Map<String, dynamic> data) {}
          );
        });
      }

      feedHandle?.onLeaving(feedHandle);
      // jsep：事件携带的sdp
      if(jsep != null) {
        handle.onRemoteJsep(handle, jsep);
      }
      return;
    };
  }

  /// 连接websocket服务器
  void connect() async{
    this._signal.connect();
  }

  /// janus create
  /// janus attach
  /// join room
  void createSessionAndAttach() {
    this._signal.createSession(
      success: (Map<String, dynamic> data) {
        this._signal.attach(
          plugin: 'janus.plugin.videoroom',
          opaqueId: opaqueId,
          success: (Map<String, dynamic> data) {
            this.joinRoom(data);
          },
          error: (Map<String, dynamic> data) {
            debugPrint('join room failed...');
          }
        );
      },
      error: (Map<String, dynamic> data){
        debugPrint('createSession failed...');
      }
    );
  }

  /// 加入房间
  void joinRoom(Map<String, dynamic> data){
    Map<String, dynamic> body ={
      "request": "join",
      "room": this.room,
      "ptype": "publisher",
      "display": this.displayName,
    };

    this._signal.joinRoom(
      data: data, 
      body: body, 
      onJoined: (handle){
        //　createOffer
        this.onPublisherJoined(handle.handleId);
      },
      onRemoteJsep: (handle, jsep){
        onPublisherRemoteJsep(handle.handleId, jsep);
      }
    );
  }

  /// 创建对等连接　关联媒体信息　发送sdp(createOffer)
  void onPublisherJoined(int handleId) async{
    this._localStream ??= await this.createStream();
    JanusConnection jc = await createJanusConnection(handleId: handleId);
    selfHandleId = handleId;

    // createOffer
    Map body = {"request": "configure", "audio": true, "video": true};
    RTCSessionDescription sdp = await jc.createOffer();
    Map<String, dynamic> jsep = sdp.toMap();
    this._signal.sendMessage(
      handleId: handleId,
      body: body,
      jsep: jsep
    );
  }

  /// 处理远程发布者接受到的远端媒体信息
  /// 创建对等链接　关联媒体数据　发生sdp(createOffer)
  void onPublisherRemoteJsep(int handleId, Map jsep){
    JanusConnection jc = this.peerConnectionMap[handleId];
    jc.setRemoteDescription(jsep);
  }

  /// 观察者处理远端媒体信息
  void subscriberHandleRemoteJsep(JanusHandle handle, Map<String, dynamic> jsep) async {
    this._localStream ??= await this.createStream();
    JanusConnection jc = await createJanusConnection(handleId: handle.handleId);
    jc.setRemoteDescription(jsep);

    RTCSessionDescription sdp = await jc.createAnswer();
    Map body = {"request": "start", "room": this.room};
    this._signal.sendMessage(
      handleId: handle.handleId,
      body: body,
      jsep: sdp.toMap()
    );
  }

  /// 创建对等连接
  Future<JanusConnection> createJanusConnection({@required int handleId}) async {
    
    JanusConnection jc = JanusConnection(handleId: handleId, iceServers: iceServers);
    this.peerConnectionMap[handleId] = jc;
    await jc.initConnection();
    
    jc.addLocalStream(this._localStream);
    jc.onAddStream = (connection, stream){
      if(stream.getVideoTracks().length > 0){
        connection.remoteStream = stream;
        connection.remoteRenderer.srcObject = stream;
        setState(() {});
      }
    };
    jc.onIceCandidate = (connection,  candidate){
      Map candidateMap = candidate != null ? candidate.toMap() : {"completed": true}; 
      this._signal.trickleCandidata(handleId: handleId, candidate: candidateMap);
    };

    return jc;

  }


  /// 创建本地流
  Future<MediaStream> createStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    MediaStream stream = await navigator.getUserMedia(mediaConstraints);
    return stream;
  }


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Room"),
      ),
      body: OrientationBuilder(builder: (context, orientation) {
        return Container(
          child: Stack(
            children: _generateVideoView(orientation),
          ),
        );
      }),
    );
  }

  List<Widget> _generateVideoView(orientation) {
    List<Widget> views = List();
    Positioned localView = Positioned(
      left: 20.0,
      top: 20.0,
      child: Container(
        width: orientation == Orientation.portrait ? 90.0 : 120.0,
        height: orientation == Orientation.portrait ? 120.0 : 90.0,
        child: RTCVideoView(_localRenderer),
        decoration: new BoxDecoration(color: Colors.black54),
      ),
    );
    views.add(localView);

    int ix = 1;
    int iy = 0;
    peerConnectionMap.forEach((key, value) {
      if (key != selfHandleId) {
        Positioned v = Positioned(
          left: 20.0 + 120 * ix,
          top: 20.0 + 130 * iy,
          child: Container(
            width: orientation == Orientation.portrait ? 90.0 : 120.0,
            height: orientation == Orientation.portrait ? 120.0 : 90.0,
            child: RTCVideoView(value.remoteRenderer),
            decoration: BoxDecoration(color: Colors.black54),
          ),
        );
        ix += 1;
        if (ix == 3) {
          ix = 0;
          iy += 1;
        }
        views.add(v);
      }
    });

    return views;
  }

  
  

}