import 'dart:async';

import 'package:hive_state/src/base.dart';
import 'package:hive_state/src/mixin/loggable.dart';

/// 添加[update]方法, 自动捕获异常
mixin TryUpdatableMx<T> on BaseHiveState<T>, LoggableMx<T> {
  /// 执行一个异步操作, 并更新状态
  /// 不建议对本方法进行二次包装, 因此返回值强制为 void
  Future<void> update(
    FutureOr<T> Function(T old) update, {
    Function(Object e, StackTrace s)? onError,
  }) =>
      updateOrNull((old) => update(old as T), onError: onError);

  /// if State init value is `null`, you can use [updateOrNull]
  Future<void> updateOrNull(
    FutureOr<T> Function(T? old) update, {
    Function(Object e, StackTrace s)? onError,
  }) async {
    try {
      final data = await update(valueOrNull);
      put(data);
    } catch (e, s) {
      onError?.call(e, s);
      if (onError == null) putError(e, s);
    }
  }
}
