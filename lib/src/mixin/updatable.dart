import 'dart:async';

import 'package:hive_state/src/base.dart';
import 'package:hive_state/src/mixin/loggable.dart';

/// 添加[update]方法, 自动捕获异常
mixin TryUpdatableMx<T> on BaseHiveState<T>, LoggableMx<T> {
  /// 执行一个异步操作, 并更新状态
  /// 不建议对本方法进行二次包装, 因此返回值强制为 void
  Future<void> update(FutureOr<T> Function(T old) update) async {
    try {
      final data = await update(value);
      put(data);
    } catch (e, s) {
      putError(e, s);
    }
  }

  /// 'use tryUpdate: 不建议将初始值设为null,带来额外的null检查步骤'
  /// 本函数建议只用于 init数据场景下
  Future<void> updateOrNull(FutureOr<T> Function(T? old) update) async {
    try {
      final data = await update(valueOrNull);
      put(data);
    } catch (e, s) {
      putError(e, s);
    }
  }
}
