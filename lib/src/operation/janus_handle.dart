import 'package:flutter/cupertino.dart';

/// JSEP（JavaScript Session Establishment Protocol，JavaScript会话建立协议），是一个信令控制协议。
/// 从JSEP完成的功能来看，JSEP相当于一个软化的信令控制协议，只能完成媒体链接的功能，
/// 在比较简单的web应用中完全可以胜任，在比较复杂的应用中需要和其他的模块或者信令相结合才能完成完整的应用。
/// 像用户查找，位置服务这些功能还需要一个完整的信令控制层。

///SIP是应用层的协议，用来建立改变和终结多媒体连接，如语音呼叫。 SIP也可以在已经存在的呼叫上新增加新的呼叫，实现多方会议。SIP的重点是通信双方连接的建立以及呼叫的控制，但是对其他需求来说扩展性不好

// 成功加入之后janus句柄处理
typedef void OnJoined(JanusHandle handle);

// 远程会话建立连接加入之后janus句柄处理
typedef void OnRemoteJsep(JanusHandle handle, Map<String, dynamic> jsep);

// 离开操作janus句柄处理
typedef void OnLeaving(JanusHandle handle);

// 被踢掉
typedef void OnKicked(JanusHandle handle);

class JanusHandle {

  int handleId;     // Janus句柄（处理＼操作数据的方法）Id

  int feedId;       // janus会话session_id  

  String display;   // 昵称显示

  OnJoined onJoined;

  OnRemoteJsep onRemoteJsep;

  OnLeaving onLeaving;

  OnKicked onKicked;

  // VideoRoomHandle videoRoomHandle;

  JanusHandle({@required this.handleId});

}