import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// 最基础的 [BaseHiveState]
abstract class BaseHiveState<T> {
  StreamController<T> get subject;

  /// 通过覆写[onCreate],可以实现在首次创建[subject]时设置初始数据[T]实例
  ///   但如果初始值不是固定值, 则需要通过[BaseHiveState.init]设置初始值[T]实例
  /// 注意: 一般情况下, 是在Widget的initState方法中调用 [put] 值进行初始化;
  StreamController<T> onCreate({T? initValue}) => (initValue != null)
      ? BehaviorSubject<T>.seeded(initValue)
      : BehaviorSubject<T>();

  BaseHiveState<T> put(T value) {
    subject.add(value);
    return this;
  }

  BaseHiveState<T> putError(Object value) {
    subject.addError(value);
    return this;
  }

  Stream<T> get stream => subject.stream;

  T get value => (subject as BehaviorSubject<T>).value;

  /// 如果没有初始值, 则[value]可能为null,使用[valueOrNull]避免抛出异常
  T? get valueOrNull => (subject as BehaviorSubject<T>).valueOrNull;

  /// ============== 以下是高级功能, 一般情况下无需使用 ==============

  /// 释放内存
  void dispose() {
    subject.close();
  }

  /// 合并多个[HiveState], 任意一个HiveState更新,都会产生新的event
  /// 返回值: List, 按顺序返回每一个Stream的最新的值; 由于每个Stream的类型可能不同, 所以类型为List<dynamic>
  CombineLatestStream<dynamic, List<dynamic>> combineStream(
          List<BaseHiveState>? combines) =>
      CombineLatestStream.list([stream, ...?combines?.map((_) => _.stream)]);
}
