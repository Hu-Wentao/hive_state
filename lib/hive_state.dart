library hive_state;

import 'dart:async';

import 'src/base.dart';
import 'src/mixin/loggable.dart';
import 'src/mixin/updatable.dart';

export 'src/base.dart';
export 'package:hive_state/src/mixin/persistable.dart';
export 'package:hive_state/src/mixin/loggable.dart';
export 'package:hive_state/src/mixin/updatable.dart';

/// HiveState
/// --- Basic mixin ---
/// [BaseHiveState] 核心基础功能: 使用Stream传递数据
/// [TryUpdatableMx] 提供 [update] 方法, 自动捕获异常
/// [LoggableMx] 打印[putError]的异常于StackTrace

///
/// 开箱即用的 HiveState基类
///
/// 注意:
/// - 不要在[HiveState]内部存储任何状态数据:
///   而应该在[T]value中存储, [tag] 代表[T]value(Model)的实例, 而非[HiveState] (ViewModel)的实例
abstract class HiveState<T> extends BaseHiveState<T>
    with LoggableMx<T>, TryUpdatableMx<T> {
  StreamController<T>? _subject;

  @override
  StreamController<T> get subject => _subject ??= onCreate();

  @override
  void dispose() {
    _subject?.close();
  }

  @override
  StreamController<T> onCreate({T? initValue}) =>
      super.onCreate(initValue: this.initValue);

  /// [initValue] 初始值
  /// 如果不想设置初始值, 请return null;
  /// 如果要需要异步初始化, 请return null, 并覆写[onCreate] 函数
  T? get initValue;
}
