import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// 最基础的 [BaseHiveState]
abstract class BaseHiveState<T> {
  /// 全局stream: <StateKey, StreamController>
  static final Map<String, StreamController> __globalCtrlMap = {};

  /// 全局缓存名称: 使用Hive将作为box名称, 一般情况下, 无需覆写
  final String storage;

  /// 默认实例名称, 一般无需更改
  final String instance;

  /// 一般情况下, 无需传值
  /// [storage] 全局存储名称: 使用[HiveBoxMx]时,会影响box的名称; 一般无需更改
  /// [instance] 对象实例名称: [BaseHiveState]是单例模式,如果需要多个实例,请传入其他值;否则用默认值;
  const BaseHiveState({this.storage = 'HS', this.instance = 'G'});

  ///
  /// [forceInit] 强制初始化: init默认只在[BaseHiveState]尚未注册时生效,传true代表强制刷新初始值
  /// 一般在Page的[initState]函数中被调用, 也可以自己包装静态方法进行初始化(适用于需要API请求的情况)
  /// ```dart
  ///  @override
  ///  void initState() {
  ///    HiveState.init('this is initValue',
  ///      forceInit: true, // 如果已有初始值, 通过forceInit可以进行覆盖
  ///    );
  ///    super.initState();
  ///  }
  /// ```
  BaseHiveState.init(
    T initialValue, {
    bool forceInit = false,
    this.storage = 'HS',
    this.instance = 'G',
  }) {
    if (forceInit || __globalCtrlMap[stateKey] == null) put(initialValue);
  }

  /// 使用默认值时,状态的key将是"HS:G:$runtimeType"
  String get stateKey => '$storage:$instance:$runtimeType';

  StreamController<T> get ctrl =>
      (__globalCtrlMap[stateKey] ??= onCreate()) as StreamController<T>;

  /// 通过覆写[onCreate],可以实现在首次创建[ctrl]时设置初始数据[T]实例
  ///   但如果初始值不是固定值, 则需要通过[BaseHiveState.init]设置初始值[T]实例
  /// 注意: 一般情况下, 是在Widget的initState方法中调用 [put] 值进行初始化;
  StreamController<T> onCreate({T? initValue}) => (initValue != null)
      ? BehaviorSubject<T>.seeded(initValue)
      : BehaviorSubject<T>();

  BaseHiveState<T> put(T value) {
    ctrl.add(value);
    return this;
  }

  BaseHiveState<T> putError(Object value) {
    ctrl.addError(value);
    return this;
  }

  Stream<T> get stream => ctrl.stream;

  T get value => (ctrl as BehaviorSubject<T>).value;

  /// 如果没有初始值, 则[value]可能为null,使用[valueOrNull]避免抛出异常
  T? get valueOrNull => (ctrl as BehaviorSubject<T>).valueOrNull;

  /// ============== 以下是高级功能, 一般情况下无需使用 ==============

  /// 释放内存
  void dispose() {
    _removeCtrlBy(stateKey);
  }

  /// 释放指定[stateKey]的全局内存
  static _removeCtrlBy(String stateKey) =>
      __globalCtrlMap.remove(stateKey)?.close();

  /// 合并多个[HiveState], 任意一个HiveState更新,都会产生新的event
  /// 返回值: List, 按顺序返回每一个Stream的最新的值; 由于每个Stream的类型可能不同, 所以类型为List<dynamic>
  CombineLatestStream<dynamic, List<dynamic>> combineStream(
          List<BaseHiveState>? combines) =>
      CombineLatestStream.list([stream, ...?combines?.map((_) => _.stream)]);
}
