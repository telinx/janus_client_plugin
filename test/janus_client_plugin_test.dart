// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:janus_client_plugin/janus_client_plugin.dart';

// void main() {
//   const MethodChannel channel = MethodChannel('janus_client_plugin');

//   TestWidgetsFlutterBinding.ensureInitialized();

//   setUp(() {
//     channel.setMockMethodCallHandler((MethodCall methodCall) async {
//       return '42';
//     });
//   });

//   tearDown(() {
//     channel.setMockMethodCallHandler(null);
//   });

//   test('getPlatformVersion', () async {
//     expect(await JanusClientPlugin.platformVersion, '42');
//   });
// }
