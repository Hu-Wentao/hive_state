import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:hive_state/src/base.dart';

/// 使用[log] 打印异常信息
mixin LoggableMx<T> on BaseHiveState<T> {
  log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String? name, // null will use 'stateKey'
    Zone? zone,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    dev.log(message,
        time: time,
        sequenceNumber: sequenceNumber,
        level: level,
        name: name ?? stateKey,
        zone: zone,
        error: error,
        stackTrace: stackTrace);
  }

  @override
  BaseHiveState<T> putError(Object e, [StackTrace? s]) {
    log('${valueToString(valueOrNull)}\n $e\n $s');
    return super.putError(e);
  }

  /// [putError]中, 将会打印model值[value]
  /// 覆写本函数, 返回需要打印的内容
  String valueToString(T? value) => '$value';
}
