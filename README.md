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
# simple example
flutter run example/hive_state -d chrome
# use `hive_flutter`, persistent API data example
flutter run example/hive_state-hive_box.dart -d chrome
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:hive_state/hive_state.dart';

/// 1. Define your state
class FooState extends HiveState<String> {}

/// 2. Update your state
/// ... callback, API, ...
onTap() {
  FooState().put('some data');
  // or
  FooState().putError('error info');
}

/// 3. Listen to your state
/// ... UI ...
StreamBuilder(
  stream: FooState().stream,
  builder: (context, snapshot) {
    if(snapshot.error !=null){
      return Text("ERROR: ${snapshot.error}");
    } 
    return Text("${s.data}");
  },
)
```

## Additional information

