## Features
基于RxDart & HiveFlutter 实现的状态管理工具
使用全局变量+本地存储 管理全局单例状态, 适用于简单全局数据状态

- 适用于:
全局状态, 典型的如 '放置在App顶层的Provider状态'
- 不适用于:
通用状态, 特别是包装后的Widget, 一般不适用于全局单例状态, 请使用Provider等基于Widget的方案

## Getting started

run example:

```shell
# simple example
flutter run example/hive_state -d chrome
# use `hive_flutter`, persistent API data example
flutter run example/hive_state-hive_box.dart -d chrome
```

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
