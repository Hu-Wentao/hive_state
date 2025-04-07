library hive_state;

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

/// 使用 with 混入本类, 以添加Hive持久化支持
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
  StreamController<T> onCreateCtrl() {
    final v = _box?.get(stateKey);
    if (v != null) return super.onCreateCtrl()..add(v);
    return super.onCreateCtrl();
  }

  /// 每次更新状态, 都将保存到box中
  @override
  put(T value) {
    _box?.put(stateKey, toJson(value));
    return super.put(value);
  }
}

/// HiveState 使用全局变量+本地存储 管理全局单例状态, 适用于简单全局数据状态
/// - 适用于:
/// 全局状态, 典型的如 '放置在App顶层的Provider状态'
/// - 不适用于:
/// 通用状态, 特别是包装后的Widget, 一般不适用于全局单例状态, 请使用Provider等基于Widget的方案
///
/// 基础类
abstract class HiveState<T> {
  /// 全局stream
  static final Map<String, StreamController> __globalCtrlMap = {};

  /// 全局缓存名称: 使用Hive将作为box名称 HSG
  /// 一般情况下, 无需覆写
  final String storage = 'HiveState:Global';

  /// [useBox]: 是否使用Box将数据缓存到本地
  HiveState({this.instanceName = 'singleton'});

  final String instanceName; //  => '$boxName:singleton'; //默认全局单例

  String get stateKey => '$storage:$runtimeType:$instanceName';

  StreamController<T> get ctrl =>
      (__globalCtrlMap[stateKey] ??= onCreateCtrl()) as StreamController<T>;

  StreamController<T> onCreateCtrl() => BehaviorSubject(); // 暂存最新的数据

  void put(T value) => ctrl.add(value);

  void putError(Object value) => ctrl.addError(value);

  Stream<T> get stream => ctrl.stream;

  /// 合并多个[HiveState], 任意一个HiveState更新,都会产生新的event
  /// 返回值: List, 按顺序返回每一个Stream的最新的值; 由于每个Stream的类型可能不同, 所以类型为List<dynamic>
  CombineLatestStream<dynamic, List<dynamic>> combineStream(
          List<HiveState>? combines) =>
      CombineLatestStream.list([stream, ...?combines?.map((_) => _.stream)]);
}
