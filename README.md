# Repo rename and move to [FlowR](https://github.com/Hu-Wentao/flowr)
2025-6-8

## Features

基于RxDart 实现的MVVM状态管理工具

- ViewModel与BuildContext 完全解偶, 可以独立Flutter进行测试.
- Stream级联刷新, 逐层传递.

## Getting started

run example:

```shell
# simple example: reactive viewmodel
flutter run example/ex1_simple.dart
```

## Usage

```dart
/// Model
class UserModel {
  String chosenUserId;

  UserModel({
    required this.chosenUserId,
  });
  @override
  String toString() => 'UserModel{chosenUserId: $chosenUserId}';
}

/// ViewModel
class UserViewModel extends HsViewModel<UserModel> {
  @override
  final UserModel initValue;

  UserViewModel({required this.initValue});

  chosenUser(String userId) async {
    update((old) {
      return old..chosenUserId = userId;
    });
  }
}

main(){
  /// create
  final vmGlobalUser = UserViewModel(
      initValue: UserModel(
        chosenUserId: 'user-111',
      ));

  /// use
  vmGlobalUser.chosenUser('user-222');
}
```
