

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

  int room = 12345678;
  // String url = 'wss://janus.onemandev.tech/websocket';
  // String url = 'wss://janus.conf.meetecho.com/ws';
  String url = 'ws://192.168.1.4:8188/janus';
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
  void deactivate() {
    super.deactivate();
    this.peerConnectionMap?.forEach((key, jc) => jc.disConnect());
    this._localRenderer?.dispose();
    this._localStream?.dispose();
    this._signal?.disconnect();
  }

  @override
  void dispose() {
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

          // }
          debugPrint('stop1====>${this._signal.sessionId}==$feed==${this.displayName}===$display');
          if(this._signal.sessionId == feed && this.displayName == display){
            debugPrint('stop2====>${this._signal.sessionId}==$feed==${this.displayName}===$display');
            return;
          }

          
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
                  this.peerConnectionMap[handle.feedId]?.disConnect();
                  this.peerConnectionMap.remove(handle.feedId);
                  setState(() {});
                }
              );
            },
            error: (Map<String, dynamic> data) {}
          );
        });
      }

      if(feedHandle != null) {
        feedHandle.onLeaving(feedHandle);
      }
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
          success: (Map<String, dynamic> attachData) {
            // this.joinRoom(data);
            this.checkRoom(attachData);
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

  /// 检测房间，房间不在则创建
  void checkRoom(Map<String, dynamic> attachData){
    this._signal.videoRoomHandle(
      req: RoomReq(request: 'exists', room: this.room),
      success: (data){
        debugPrint('exists room=====>>>>>>$data');
        if(null != data['plugindata']['data'] &&  data['plugindata']['data']['exists']){
          this.joinRoom(attachData);
        }else {
          this._signal.videoRoomHandle(
            req: RoomReq(request: 'create', room: this.room, description: 'this is my room'),
            success: (data){
              debugPrint('create room=====>>>>>>$data');
              this.joinRoom(attachData);
            },
            error: (data){
              print('create room error========>$data');
            }
          );
        }
      },
      error: (data){
        print('find room error========>$data');
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
      'secret': '',
      'pin': ''
    };

    this._signal.joinRoom(
      data: data, 
      body: body, 
      display: this.displayName,
      onJoined: (handle){
        //　createOffer
        this.onPublisherJoined(handle);
      },
      onRemoteJsep: (handle, jsep){
        onPublisherRemoteJsep(handle, jsep);
      }
    );
  }

  /// 创建对等连接　关联媒体信息　发送sdp(createOffer)
  void onPublisherJoined(JanusHandle handle) async{
    this.selfHandleId = handle.handleId;
    this._localStream ??= await this.createStream();
    JanusConnection jc = await createJanusConnection(handle: handle);
    debugPrint('selfHandleId====>$selfHandleId');
    // createOffer
    Map body = {"request": "configure", "audio": true, "video": true};
    RTCSessionDescription sdp = await jc.createOffer();
    Map<String, dynamic> jsep = sdp.toMap();
    this._signal.sendMessage(
      handleId: handle.handleId,
      body: body,
      jsep: jsep
    );
  }

  /// 处理远程发布者接受到的远端媒体信息
  /// 创建对等链接　关联媒体数据　发生sdp(createOffer)
  void onPublisherRemoteJsep(JanusHandle handle, Map jsep){
    JanusConnection jc = this.peerConnectionMap[handle.feedId];
    jc.setRemoteDescription(jsep);
  }

  /// 观察者处理远端媒体信息
  void subscriberHandleRemoteJsep(JanusHandle handle, Map<String, dynamic> jsep) async {
    this._localStream ??= await this.createStream();
    JanusConnection jc = await createJanusConnection(handle: handle);
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
  Future<JanusConnection> createJanusConnection({@required JanusHandle handle}) async {
    
    JanusConnection jc = JanusConnection(handleId: handle.handleId, iceServers: iceServers, display: handle.display);
    debugPrint('创建对等连接===>${this.peerConnectionMap.length} ====${handle.handleId}');
    this.peerConnectionMap[handle.feedId] = jc;
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
      this._signal.trickleCandidata(handleId: handle.handleId, candidate: candidateMap);
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
      // child: Container(
      //   width: orientation == Orientation.portrait ? 90.0 : 120.0,
      //   height: orientation == Orientation.portrait ? 120.0 : 90.0,
      //   child: RTCVideoView(_localRenderer),
      //   decoration: new BoxDecoration(color: Colors.black54),
      // ),
      child: this._buildVideoWidget(orientation, _localRenderer, this.displayName),
    );
    views.add(localView);

    int ix = 1;
    int iy = 0;
    peerConnectionMap.forEach((key, value) {
      if (key != this._signal.sessionId) {
        Positioned v = Positioned(
          left: 20.0 + 120 * ix,
          top: 20.0 + (130.0 + 30.0) * iy,
          // child: Container(
          //   width: orientation == Orientation.portrait ? 90.0 : 120.0,
          //   height: orientation == Orientation.portrait ? 120.0 : 90.0,
          //   child: RTCVideoView(value.remoteRenderer),
          //   decoration: BoxDecoration(color: Colors.black54),
          // ),
          child: this._buildVideoWidget(orientation, value.remoteRenderer, value.display),
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

  Widget _buildVideoWidget(orientation, RTCVideoRenderer renderer, String display){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: orientation == Orientation.portrait ? 90.0 : 120.0,
          height: orientation == Orientation.portrait ? 120.0 : 90.0,
          child: RTCVideoView(renderer),
          decoration: BoxDecoration(color: Colors.black54),
        ),
        Container(
          alignment: Alignment.center,
          height: 30.0,
          child: Text('$display'),
        )
      ],
    );
  }
  

}