
import 'package:flutter/cupertino.dart';

typedef void TransactionSuccess(Map<String, dynamic> data);
typedef void TransactionError(Map<String, dynamic> data);
typedef void TransactionDestoryed();

/// Janus事务，事务的概念可以参考SIP协议，可以理解为一问一答这样一个交互的过程，用事务ID来标识。
class JanusTransaction {

  String tid;                         // 事务ＩＤ

  TransactionSuccess success;         // 事务成功之后的执行方法

  TransactionError error;             // 事务失败之后的执行方法

  TransactionDestoryed destoryed;     //　事务销毁之后的执行
  
  JanusTransaction({@required this.tid});

}