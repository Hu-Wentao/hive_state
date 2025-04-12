library hive_state;

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

/// HiveState 使用全局变量+本地存储 管理全局单例状态, 适用于简单全局数据状态
/// [BaseHiveState] 核心基础功能
/// [UpdatableStateMx] 将暂存最新的数据
/// [HiveStateHiveBoxMx] 将状态持久化到本地
/// [LoggableMx] 打印putError的内容

/// 使用 with 混入本类, 以添加Hive持久化支持
/// 调用[dispose] 不会移除本地存储的数据
/// [onCreate] 设置的初始化数据仅在本地数据为null时生效
mixin HiveStateHiveBoxMx<T> on HiveState<T> {
  Box? get _box => Hive.box<String>(storage);

  /// 全局单例: box固定为String
  /// 整个App的所有HiveState继承类,只需要openBox一次;
  /// - 除非[HiveState].[storage]变量被修改
  FutureOr<Box<String>> openBox() async {
    if (Hive.isBoxOpen(storage)) {
      return Hive.box<String>(storage);
    } else {
      return await openHiveBox<String>(storage);
    }
  }

  /// 通过覆写本函数,实现
  Future<Box<E>> openHiveBox<E>(String name) => Hive.openBox<E>(
        name,
        encryptionCipher: null,
        crashRecovery: true,
        path: null,
        bytes: null,
        collection: null,
      );

  String toJson(T value);

  T fromJson(String value);

  @override
  StreamController<T> onCreate({T? initValue}) {
    final v = _box?.get(stateKey) ?? initValue;
    return super.onCreate(initValue: v);
  }

  /// 每次更新状态, 都将保存到box中
  @override
  BaseHiveState<T> put(T value) {
    _box?.put(stateKey, toJson(value));
    return super.put(value);
  }
}

///
/// 开箱即用的 HiveState基类
abstract class HiveState<T> extends BaseHiveState<T>
    with UpdatableStateMx<T>, LoggableMx<T> {
  /// 通过构造函数传入Model值, 相当于
  /// ` HiveState().put('some value'); `
  ///
  /// 一般在Page的[initState]函数中被调用, 也可以自己包装静态方法进行初始化(适用于需要API请求的情况)
  /// ```dart
  ///  @override
  ///  void initState() {
  ///    HiveState(value: 'this is initValue');
  ///    super.initState();
  ///  }
  /// ```
  HiveState({
    T? value,
    String instance = 'G',
  }) : super(instance: instance) {
    if (value != null) put(value);
  }
}

/// 使用[log] 打印异常信息
mixin LoggableMx<T> on BaseHiveState<T> {
  @override
  BaseHiveState<T> putError(Object e, [StackTrace? s]) {
    if (kDebugMode) log('$e\n$s', name: stateKey);
    return super.putError(e);
  }
}

/// 使用 [BehaviorSubject], 会暂存最新的数据, 增加 [update] 方法
mixin UpdatableStateMx<T> on BaseHiveState<T> {
  @override
  StreamController<T> onCreate({T? initValue}) => (initValue != null)
      ? BehaviorSubject<T>.seeded(initValue)
      : BehaviorSubject<T>();

  BaseHiveState<T> update(T Function(T old) update) => put(update(value));

  BaseHiveState<T> updateOrNull(T Function(T? old) update) =>
      put(update(valueOrNull));

  T get value => (ctrl as BehaviorSubject<T>).value;

  T? get valueOrNull => (ctrl as BehaviorSubject<T>).valueOrNull;
}

/// 最基础的 [BaseHiveState]
abstract class BaseHiveState<T> {
  /// 全局stream: <StateKey, StreamController>
  static final Map<String, StreamController> __globalCtrlMap = {};

  /// 全局缓存名称: 使用Hive将作为box名称
  /// 一般情况下, 无需覆写
  final String storage = 'HS'; //'HiveState';

  /// 一般情况下, 无需传参
  BaseHiveState({this.instance = 'G'}); // Global

  final String instance;

  String get stateKey => '$storage:$instance:$runtimeType';

  StreamController<T> get ctrl =>
      (__globalCtrlMap[stateKey] ??= onCreate()) as StreamController<T>;

  /// 通过覆写[onCreate],可以实现在首次创建[ctrl]时设置初始数据[T]
  /// 注意: 一般情况下, 是在Widget的initState方法中调用 [put] 值进行初始化;
  StreamController<T> onCreate({T? initValue}) => StreamController.broadcast();

  BaseHiveState<T> put(T value) {
    ctrl.add(value);
    return this;
  }

  BaseHiveState<T> putError(Object value) {
    ctrl.addError(value);
    return this;
  }

  Stream<T> get stream => ctrl.stream;

  /// 释放内存
  void dispose() {
    ctrl.close();
    __globalCtrlMap.remove(stateKey);
  }

  /// 合并多个[HiveState], 任意一个HiveState更新,都会产生新的event
  /// 返回值: List, 按顺序返回每一个Stream的最新的值; 由于每个Stream的类型可能不同, 所以类型为List<dynamic>
  CombineLatestStream<dynamic, List<dynamic>> combineStream(
          List<HiveState>? combines) =>
      CombineLatestStream.list([stream, ...?combines?.map((_) => _.stream)]);
}
