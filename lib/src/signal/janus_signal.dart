

import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';

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
/// 2.创建会话，发送janus create，success接收数据
/// 3.attach关联插件
/// 4.attach关联成功，加入房间joinroom
/// 5.创建offer(janus = message)  onPublisherJoined
/// 6.创建answer（janus = message）subscriberHandleRemoteJsep
/// 7.发送ice，trickle
///

typedef Void OnMessage(JanusHandle handle, Map msg, Map jsep, JanusHandle feedHandle);

/// janus信令处理
class JanusSignal {

  String _kJanus = 'janus';
  
  int sessionId = -1;

  // websocket服务器地址
  String url;                     

  // websocket信息回调处理
  OnMessage onMessage;

  // websocket channel
  IOWebSocketChannel _channel;

  // janus事务集合
  Map<dynamic, JanusTransaction> _transMap = <dynamic, JanusTransaction>{};

  // janus句柄集合
  Map<dynamic, JanusHandle> _handleMap = <dynamic, JanusHandle>{};

  // janus远程流集合
  Map<dynamic, JanusHandle> _feedMap = <dynamic, JanusHandle>{};

  JsonEncoder _encoder = JsonEncoder();
  
  JsonDecoder _decoder = JsonDecoder();
  
  factory JanusSignal() => _getInstance();

  static JanusSignal get instance => _getInstance();

  static JanusSignal _instance;

  JanusSignal._internal() {/**/}

  /// 单例
  static JanusSignal _getInstance() {
    if (_instance == null) {
      _instance = JanusSignal._internal();
    }
    return _instance;
  }

  
  /// 信令获得连接
  void connect({@required String url}){

  }


  /// websocket断开链接
  void disconnect() {
    this._channel.sink.close();
  }

  /// 发送message给janus
  void sendMessage({Map body, Map jsep, int handleId,}){

  }

  /// 公共消息发送
  void send(Map map) {


  }

  /// 创建会话
  void createSession({TransactionSuccess success, TransactionError error}){

  }

  /// attach关联janus插件
  void attach({
    String plugin,
    String opaqueId,
    TransactionSuccess success,
    TransactionError error,
  }){

  }

  ///　加入房间
  void joinRoom({
    Map<String, dynamic> data,
    Map body,
    OnJoined onJoined,
    OnRemoteJsep onRemoteJsep,
    OnLeaving onLeaving,
    int feedId,
    String display,
  }) {

  }

  ///　发送ice给janus
  void trickleCandidata({int handleId,Map<String, dynamic> candidata,}){

  }

  /// 心跳
  void keepAlive(){

  }

  /// 处理janus服务器返回消息
  void handleMessage(Map<dynamic, dynamic> message) {

  }

}