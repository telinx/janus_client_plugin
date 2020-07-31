

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:janus_client_plugin/janus_client_plugin.dart';
import 'package:random_string/random_string.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../operation/janus_handle.dart';
import '../operation/janus_transaction.dart';

/// 1.客户端发送create创建一个Janus会话；
/// 2.Janus回复success返回Janus会话句柄；
/// 3.--客户端发送attach命令在Janus会话上attach指定插件；
/// 4.--Janus回复success返回插件的句柄；
/// 5.客户端给指定的插件发送message进行信令控制；
/// 6.Janus上的插件发送event通知事件给客户端；
/// 7.客户端收集candidate并通过trickle消息发送给插件绑定的ICE通道；
/// 8.Janus发送webrtcup通知ICE通道建立；
/// 9.客户端发送媒体数据；
/// 10.Janus发送media消息通知媒体数据的第一次到达；
/// 11.Janus进行媒体数据转发。

/// 1.websocket创建连接，keepAlive,预留处理回调信息handlemessage
/// 2.创建会话create，发送janus create，success接收数据
/// 3.attach关联插件
/// 4.attach关联成功，加入房间joinroom
/// 5.创建offer(janus = message)  onPublisherJoined
/// 6.创建answer（janus = message）subscriberHandleRemoteJsep
/// 7.发送ice，trickle
///

typedef Void OnMessage(JanusHandle handle, Map plugin, Map jsep, JanusHandle feedHandle);

/// janus信令处理
class JanusSignal {

  String _kJanus = 'janus';
  
  int _sessionId = -1;

  int _handleId = -1;

  // websocket服务器地址
  String _url;   

  // websocket服务器密钥
  String _apiSecret;

  // websocket服务器通讯token
  String _token;

  // 是否需要使用
  bool _withCredentials = false;

  // websocket信息回调处理
  OnMessage _onMessage;

  // websocket channel
  IOWebSocketChannel _channel;

  Stream<dynamic> _stream;

  WebSocketSink _sink;

  // 显示昵称
  String _display = 'janus';

  // keepalive时间
  int _refreshInterval = 20;

  // janus事务集合
  Map<dynamic, JanusTransaction> _transMap = <dynamic, JanusTransaction>{};

  // janus句柄集合
  Map<dynamic, JanusHandle> _handleMap = <dynamic, JanusHandle>{};

  // janus远程流集合
  Map<dynamic, JanusHandle> _feedMap = <dynamic, JanusHandle>{};

  JsonEncoder _encoder = JsonEncoder();
  
  JsonDecoder _decoder = JsonDecoder();

  get handleId => this._handleId;       // self handleId

  get sessionId => this._sessionId;     // self session

  set sessionId(int sessionId) => this._sessionId = sessionId;

  set url(String url) => this._url = url;

  set apiSecret(String apiSecret) => this._apiSecret = apiSecret;

  set token(String token) => this._token = token;

  set withCredentials(bool withCredentials) => this._withCredentials = withCredentials;

  set onMessage(OnMessage onMessage) => this._onMessage = onMessage;

  set display(String display) => this._display = display;

  set refreshInterval(int refreshInterval) => this._refreshInterval = refreshInterval;

  dynamic get _apiMap => this._withCredentials ? this._apiSecret != null ? {"apisecret": this._apiSecret} : {} : {};

  dynamic get _tokenMap => this._withCredentials ? this._token != null ? {"token": this._token} : {} : {};

  JanusSignal._();

  static JanusSignal _instance;
  /// 单例
  static JanusSignal getInstance({
    @required String url,
    String apiSecret,
    String token,
    bool withCredentials,
    String display,
    int refreshInterval = 20,
  }) {
    if (_instance == null) {
      _instance = JanusSignal._();
    }
    if(url != null) _instance.url = url;
    if(apiSecret != null) _instance.apiSecret = apiSecret;
    if(token != null) _instance.token = token;
    if(withCredentials != null) _instance.withCredentials = withCredentials;
    if(display != null) _instance.display = display;
    if(refreshInterval != null) _instance.refreshInterval = refreshInterval;
    
    return _instance;
  }

  
  /// 信令获得连接
  void connect(){
    debugPrint('janus connect===========>${this._url}');
    Iterable<String> it = ['janus-protocol'];
    this._channel = IOWebSocketChannel.connect(this._url, protocols: it);
    this._sink = this._channel.sink;
    // this._stream = this._channel.stream.asBroadcastStream();
    this._stream = this._channel.stream;
    this._stream.listen((message) {
      debugPrint('$_kJanus receieve: $message');
      this.handleMessage(this._decoder.convert(message));
    }).onDone(() {
      print('closed　by server');
    });
  }



  /// websocket断开链接
  void disconnect() {
    debugPrint('janus disconnect===========>${this._url}');
    this._sink.close();
  }

  /// 发送message给janus
  void sendMessage({
    @required int handleId,
    @required Map body, 
    Map jsep,
    String transaction 
  }){

    transaction ??= randomAlphaNumeric(12);
    Map<String, dynamic> msgMap = {
      "janus": "message",
      "body": body,
      "transaction": transaction,
      "session_id": this._sessionId,
      "handle_id": handleId
    };
    if(jsep != null){
      msgMap["jsep"] = jsep;
    }
    this.send(msgMap);

  }

  /// 公共消息发送
  void send(Map map) {
    debugPrint('janus client send=====>>>>>>$map');
    String json = this._encoder.convert(map);
    this._sink.add(json);

  }

  /// 创建会话
  void createSession({@required TransactionSuccess success, @required TransactionError error}){
    String transaction = randomAlphaNumeric(12);
    JanusTransaction jt = JanusTransaction(tid: transaction);

    jt.success = (Map data){
      debugPrint('createSession seuccess');
      this.sessionId = data['data']['id'];
      // this.keepAlive();
      success(data);
    };
    jt.error = error;

    this._transMap[transaction] = jt;
    Map<String, dynamic> createMap = {
      'janus': 'create',
      'transaction': transaction,
      ...this._apiMap,
      ...this._tokenMap,
    };
    this.send(createMap);
  }

  /// attach关联janus插件
  void attach({
    @required String plugin,
    @required String opaqueId,
    @required TransactionSuccess success,
    @required TransactionError error,
  }){
    String transaction = randomAlphaNumeric(12);
    JanusTransaction jt = JanusTransaction(tid: transaction);

    jt.success =  (data){
      this._handleId = data['data']['id'];
      debugPrint('janus attach success=====data: $data======>handleId: ${this._handleId}');
      this._handleMap[this._handleId] = JanusHandle(handleId: this._handleId);
      success(data);
    } ;
    jt.error = error;
    _transMap[transaction] = jt;

    Map<String, dynamic> attachMap = {
      "janus": "attach",
      "plugin": plugin,
      "transaction": transaction,
      "session_id": this._sessionId,
      "opaque_id": opaqueId
    };
    this.send(attachMap);
  }

  ///　加入房间
  void joinRoom({
    @required Map<String, dynamic> data,
    @required Map<String, dynamic> body,
    String display,
    int feedId,
    OnJoined onJoined,
    OnRemoteJsep onRemoteJsep,
    OnLeaving onLeaving,
  }) {
    dynamic senderSessionId = data['data']['id']; // sessionId
    JanusHandle handle = this._handleMap[senderSessionId] ?? JanusHandle(handleId: senderSessionId);
    handle.onJoined = onJoined;
    handle.onRemoteJsep = onRemoteJsep;
    handle.onLeaving = onLeaving;
    handle.display = display ?? this._display;

    // 设置handle的session_id,　不是远程的session_id就是自己的session_id
    if(feedId != null){                 
      handle.feedId = feedId;
      this._feedMap[feedId] = handle;
    } else{
      handle.feedId = this.sessionId;
    }
    
    this._handleMap[handle.handleId] = handle;
    this.sendMessage(body: body, handleId: handle.handleId);
  }

  ///　发送ice给janus
  void trickleCandidata({
    @required int handleId, 
    @required Map<String, dynamic> candidate,
  }){
     Map trickleMap = {
      "janus": "trickle",
      "candidate": candidate,
      "transaction": randomNumeric(12),
      "session_id": this._sessionId,
      "handle_id": handleId,
    };
    this.send(trickleMap);
  }

  /// 心跳
  void keepAlive(){

    Map<String, dynamic> aliveMap = {
      'janus': 'keepalive',
      'session_id': this._sessionId,
      ...this._apiMap,
      ...this._tokenMap,
    };
    Timer.periodic(Duration(seconds: this._refreshInterval), (timer) { 
      aliveMap['transaction'] = randomNumeric(12);
      this.send(aliveMap);
    });
    
  }

  /// 处理janus服务器返回消息
  void handleMessage(Map<dynamic, dynamic> message) {
    String janus = message[this._kJanus];
    debugPrint('$_kJanus handleMessage $janus');
    switch(janus){
      case 'success': {
        String transaction = message['transaction'];
        JanusTransaction jt = this._transMap[transaction];
        if(null != jt && jt.success != null) {
          jt.success(message);
        }
        _transMap.remove(transaction);
      }
      break;

      case 'error': {
        String transaction = message['transaction'];
        JanusTransaction jt = this._transMap[transaction];
        if(null != jt && jt.error != null) {
          jt.error(message);
        }
        _transMap.remove(transaction);
      }
      break;

      case 'ack': {
      }
      break;

      case 'event': {
        Map<String, dynamic> plugin = message['plugindata']['data'];
        
        // 创建房间成功　失败执行方法
        String transaction = message['transaction'];
        JanusTransaction jt = this._transMap[transaction];
        if(null != plugin && null != jt){
          if(null != plugin['error']){
            debugPrint('$_kJanus handleMessage event error====>: ${plugin['error']}');
            jt.error(plugin);
          }else{
            jt?.success(plugin);
          }
          this._transMap.remove(transaction);
        }
        

        JanusHandle handle = this._handleMap[message['sender']];
        
        JanusHandle feedHandle;
        if(plugin['leaving'] != null){  // 有人离开
          feedHandle = this._feedMap[plugin['leaving']];
        }
        this._onMessage(handle, plugin, message["jsep"], feedHandle);

        if(plugin['leaving'] != null){  // 有人离开,移除handle
          this._feedMap.remove(plugin['leaving']);
          this._handleMap.remove(message['sender']);
        }
      }
      break;

      case 'detached': {  // 插件从Janus会话detach的通知，释放了一个插件句柄
        debugPrint('$_kJanus handleMessage detached: $message');
        JanusHandle handle = this._handleMap[message['sender']];
        handle?.onLeaving(handle);
      }
      break;

      default: {
        debugPrint('$_kJanus handleMessage defalut: $message');
        JanusHandle handle = this._handleMap[message['sender']];
        if(handle == null){
          print('missing handle');
        }
      }
    }

  }

  /// 房间创建销毁等逻辑
  void videoRoomHandle({ 
    @required RoomReq req, 
    @required TransactionSuccess success, 
    @required TransactionError error
  }){
    JanusHandle handle = this._handleMap[this._handleId];
    String transaction = randomAlphaNumeric(12);
    JanusTransaction jt = JanusTransaction(tid: transaction);
    jt.success = success;
    jt.error = error;
    this._transMap[transaction] = jt;
    this.sendMessage(handleId: handle.handleId, body: req.toMap(), transaction: transaction);
  }

}