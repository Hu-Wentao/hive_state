
import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_state/hive_state.dart';

/// 使用 with 混入本类, 以添加Hive持久化支持
/// 调用[dispose] 不会移除本地存储的数据
/// [onCreate] 设置的初始化数据仅在本地数据为null时生效
mixin HiveBoxMx<T> on HiveState<T> {
  String get storage;

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
    final v = _box?.get(storage) ?? initValue;
    return super.onCreate(initValue: v);
  }

  /// 每次更新状态, 都将保存到box中
  @override
  BaseHiveState<T> put(T value) {
    _box?.put(storage, toJson(value));
    return super.put(value);
  }
}
