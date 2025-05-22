import 'dart:async';

import 'package:hive_state/hive_mvvm.dart';

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

// -------------------
class BookLibModel {
  List<String>? books;

  BookLibModel({
    this.books,
  });
  @override
  String toString() => 'BookLibModel{books: $books}';
}

class BookLibViewModel extends HsViewModel<BookLibModel> {
  @override
  final BookLibModel initValue;
  final UserViewModel vmUser;

  BookLibViewModel(this.initValue, {required this.vmUser}) {
    // 监听用户变化
    _listenUser = vmUser.stream.listen((d) {
      updateBookIds(userId: d.chosenUserId);
    });
  }

  late StreamSubscription _listenUser;

  @override
  dispose() {
    _listenUser.cancel();
    super.dispose();
  }

  _fetchBookIds(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    return ['book-1($userId)', 'book-2($userId)', 'book-3($userId)'];
  }

  updateBookIds({required String userId}) async {
    update((old) {
      final resp = _fetchBookIds(userId);
      return old..books = resp;
    });
  }
}

main() {
  final vmGlobalUser = UserViewModel(
      initValue: UserModel(
    chosenUserId: 'user-111',
  ));

  final vmGlobalBookLib = BookLibViewModel(
    BookLibModel(),
    vmUser: vmGlobalUser,
  );

  print('vmGlobalUser#1: ${vmGlobalBookLib.value}');

  vmGlobalUser.chosenUser('user-222');

  print('vmGlobalUser#2: ${vmGlobalBookLib.value}');
}
