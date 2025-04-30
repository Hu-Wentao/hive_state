library hive_state;

import 'base.dart';
import 'mixin/loggable.dart';
import 'mixin/updatable.dart';

export 'base.dart';
export 'package:hive_state/mixin/persistable.dart';
export 'package:hive_state/mixin/loggable.dart';
export 'package:hive_state/mixin/updatable.dart';

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
///   而应该在[T]value中存储, [instance] 代表[T]value的实例, 而非[HiveState]的实例
abstract class HiveState<T> extends BaseHiveState<T>
    with LoggableMx<T>, TryUpdatableMx<T> {}


