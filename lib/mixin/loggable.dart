import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_state/base.dart';

/// 使用[log] 打印异常信息
mixin LoggableMx<T> on BaseHiveState<T> {
  @override
  BaseHiveState<T> putError(Object e, [StackTrace? s]) {
    if (kDebugMode) {
      log(
        '${valueToString(valueOrNull)}\n'
        '$e\n'
        '$s',
        name: stateKey,
      );
    }
    return super.putError(e);
  }

  /// [putError]中, 将会打印model值[value]
  /// 覆写本函数, 返回需要打印的内容
  String valueToString(T? value) => '$value';
}
