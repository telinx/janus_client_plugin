# janus_client_plugin

A new flutter janus client plugin project.

## Sample
![sample](sample.jpeg "janus client sample")

## Tree
```
lib
├── janus_client_plugin.dart
└── src
    ├── ice_server.dart
    ├── model
    │   ├── room_attach_req.dart
    │   ├── room_join_req.dart
    │   ├── room_leave_req.dart
    │   ├── room_publish_req.dart
    │   ├── room_req.dart
    │   └── room_subscriber_req.dart
    ├── operation
    │   ├── janus_connection.dart
    │   ├── janus_handle.dart
    │   └── janus_transaction.dart
    └── signal
        └── janus_signal.dart
```

## Example 
```
  JanusSignal _signal;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream _localStream;
  Map<int, JanusConnection> peerConnectionMap = <int, JanusConnection>{};

  initState{
    this._signal = JanusSignal.getInstance(url: url, apiSecret: apiSecret, withCredentials: withCredentials);
    // set parameters
    this._signal...

    //init local renderer
    this._initRenderers();
  }

  /// 初始化视图
  void _initRenderers() async{
    await this._localRenderer.initialize();
    this._localStream = await this.createStream();
    this._localRenderer.srcObject = this._localStream;
    /*
    * 1.connect janus server，success
    * 2.janus create session, success
    * 3.janus attach plugin,success
    * 4.janus videoroom join
    * 5.janus createOffer createAnswer
    * 6.janus trickle ice
    */
    this.connect();
    this.createSessionAndAttach();
    setState(() {});
  }
  ...

  void dispose(){
    this.peerConnectionMap?.forEach((key, jc) => jc.disConnect());
    this._localRenderer?.dispose();
    this._localStream?.dispose();
    this._signal?.disconnect();
    this._signal = null;
  }
```