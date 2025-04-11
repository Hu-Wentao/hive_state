library hive_state;

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

typedef HSModel = Object;

/// 默认使用[HiveState], 包含常用功能
typedef HSViewModel<T extends HSModel> = HiveState<T>;

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
  put(T value) {
    _box?.put(stateKey, toJson(value));
    return super.put(value);
  }
}

///
/// 开箱即用的 HiveState基类
abstract class HiveState<T> extends BaseHiveState<T>
    with UpdatableStateMx<T>, LoggableMx<T> {}

/// 使用[log] 打印异常信息
mixin LoggableMx<T> on BaseHiveState<T> {
  @override
  void putError(Object value) {
    if (kDebugMode) log('$value', name: stateKey);
    super.putError(value);
  }
}

/// 使用 [BehaviorSubject], 会暂存最新的数据, 增加 [update] 方法
mixin UpdatableStateMx<T> on BaseHiveState<T> {
  @override
  StreamController<T> onCreate({T? initValue}) => (initValue != null)
      ? BehaviorSubject<T>.seeded(initValue)
      : BehaviorSubject<T>();

  void update(T Function(T old) update) => put(update(value));

  void updateOrNull(T Function(T? old) update) => put(update(valueOrNull));

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

  // 默认前缀 "HS:G",将被用于从全局搜索 stream
  String get stateKey => '$storage:$instance:$runtimeType';

  StreamController<T> get ctrl =>
      (__globalCtrlMap[stateKey] ??= onCreate()) as StreamController<T>;

  StreamController<T> onCreate() => StreamController.broadcast();

  void put(T value) => ctrl.add(value);

  void putError(Object value) => ctrl.addError(value);

  Stream<T> get stream => ctrl.stream;

  /// ============== 以下是高级功能, 一般情况下无需使用 ==============

  /// 释放内存
  /// 没有必要主动释放全局状态, 因为移除全局状态意味着App退出;
  /// 除非需要控制单页面的状态, 并且手动管理初始化与释放
  void dispose() {
    ctrl.close();
    __globalCtrlMap.remove(stateKey);
  }

  /// 合并多个[HiveState], 任意一个HiveState更新,都会产生新的event
  /// 返回值: List, 按顺序返回每一个Stream的最新的值; 由于每个Stream的类型可能不同, 所以类型为List<dynamic>
  CombineLatestStream<dynamic, List<dynamic>> combineStream(
          List<HiveState>? combines) =>
      CombineLatestStream.list([stream, ...?combines?.map((_) => _.stream)]);

  /// 从全局查询状态,将使用默认的前缀参数;
  /// 不适用于已经自定义[storage]和[instance]的情况
  static Stream<M> _streamBy<M>(Type vm) {
    // todo try catch
    return __globalCtrlMap['HS:G:$vm']?.stream as Stream<M>;
  }
}

///
class HiveStateView<M extends Object, VM extends BaseHiveState<M>>
    extends StatelessWidget {
  final AsyncWidgetBuilder<VM> builder;

  const HiveStateView({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<M>(
        stream: BaseHiveState._streamBy<M>(VM),
        builder: (context, snapshot) {
          return const Placeholder();
        });
  }
}

/// 页面View, 可以自动管理 页面级别状态
class HiveStatePageView<M extends Object, VM extends BaseHiveState<M>>
    extends StatefulWidget {
  /// 页面关闭时释放状态
  final bool releaseStateOnDispose;
  const HiveStatePageView({super.key, this.releaseStateOnDispose = true});

  @override
  State<HiveStatePageView> createState() => _HiveStatePageViewState();
}

class _HiveStatePageViewState extends State<HiveStatePageView> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
