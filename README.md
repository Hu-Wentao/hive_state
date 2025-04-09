## Features
基于RxDart & HiveFlutter 实现的状态管理工具
使用全局变量+本地存储 管理全局单例状态, 适用于简单全局数据状态

- 适用于:
全局状态, 典型的如 '放置在App顶层的Provider状态'
- 不适用于:
通用状态, 如包装后的通过Widget树搜索状态的Widget, 请使用Provider等基于Widget的方案

## Getting started

run example:

```shell
# simple example: use String type model
flutter run example/hive_state.dart -d chrome
# complex example: use custom type model
flutter run example/hive_state-complex.dart -d chrome
# use `hive_flutter`, persistent API data example
flutter run example/hive_state-hive_box.dart -d chrome
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:hive_state/hive_state.dart';

/// 1. Define your state
/// 1. 定义状态
class FooState extends HiveState<String> {
  @override
  StreamController<String> onCreate({String? initValue}) =>
      super.onCreate(initValue: 'this is initial value');
}

/// 2. Update your state
/// 2. 更新状态数据/异常
/// ... callback, API, ...
onTap() {
  FooState().put('some data');
  // or
  FooState().putError('error info');
  // or 
  FooState().update((old) => 'new data with [$old]');
  // or
  FooState().updateOrNull((old) => 'new data with [$old]');
}

/// 3. Read Value
/// 3. 读取状态数据
/// ... UI2 ...
buildSimpleUI() {
  var v;
  v = FooState().value;
  // or
  v = FooState().valueOrNull;

  return Text("$v");
}

/// 4. Listen to your state
/// 4. 监听状态&异常数据变化
/// ... UI ...
class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // 监听异常1
    BarState().stream.listen((event) {}, onError: (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("App收到异常 $e")));
    });
    super.initState();
  }

  buildSomeUI() {
    return StreamBuilder(
      // 监听状态
      stream: FooState().stream,
      builder: (context, snapshot) {
        // 监听异常2
        if (snapshot.error != null) {
          return Text("ERROR: ${snapshot.error}");
        }
        return Text("${s.data}");
      },
    );
  }

}


/// 5. dispose
/// 如果该状态退出页面后不再使用,则可以清除
/// ... UI3 ...
class XxxPageState extends State<XxxPage> {
  dispose() {
    FooState().dispose();
    super.dispose();
  }
}

```

## Additional information

