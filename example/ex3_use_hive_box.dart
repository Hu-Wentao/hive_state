import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_state/hive_state.dart';

/// ----

/// 修改[HiveBoxMx]的openHiveBox方法:
/// - 本例演示自定义加密算法.
/// - 通过覆写方法, 可以替换Hive实现, 例如改用 SharedPreference
/// 注意添加泛型 [T]
mixin MyCipherMx<T> on HiveBoxMx<T> {
  @override
  Future<Box<E>> openHiveBox<E>(String name) => Hive.openBox<E>(
        name,
        encryptionCipher: null, // 自定义加密算法
      );
}

/// FooState 自定义状态类
/// - `extends HiveState<String>`: 使用[String]类型的状态
/// - `with HiveStateHiveBoxMx`: 使用[HiveBoxMx]通过Hive持久化状态
/// - `MyCipherMx`: 混入 [MyCipherMx], 覆写[openHiveBox], 自定义加密算法
class FooState extends HiveState<String> with HiveBoxMx, MyCipherMx {
  // 基本类型, 无需转换
  @override
  String fromJson(String value) => value;

  // 基本类型, 无需转换
  @override
  String toJson(String value) => value;

  @override
  String? get initValue => null;
}

/// ----

Future<void> main() async {
  await Hive.initFlutter();
  // await Hive.openBox<String>(kBoxState);
  // await Hive.openBox<String>(BaseHiveState.boxName);
  await FooState().openBox(); // 任意‘HiveStateHiveBoxMx’实现类,只需要openBox一次
  runApp(const MaterialApp(
    title: 'HiveState:Global Demo',
    home: MyHomePage(),
  ));
}

/// 模拟API请求
/// [times]: 模拟API传参
Future<String> mockFooAPI(int times) async {
  debugPrint("API received: $times");
  if (times > 4 && times % 2 == 0) throw "Error: 请求频繁! ($times)";
  await Future.delayed(const Duration(seconds: 1));
  return "mockFooAPI-Resp: Req data with [$times], at [${DateTime.now()}]";
}

// const kBoxState = 'kBoxState';
// const kMockFooData = 'kMockFooData';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  /// fetchData 函数: 请求API, 并将数据存入Hive
  /// 在调用[mockFooAPI]之前, 可以进行防抖/节流操作
  Future<void> _fetchData() async {
    try {
      final data = await mockFooAPI(_counter);
      // Hive.box<String>(kBoxState).put(kMockFooData, data);
      FooState().put(data);
    } catch (e) {
      FooState().putError(e);
    }

    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo: 存储API数据到本地')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              /// 使用时直接新建实例, 所有实例共享stream
              stream: FooState().stream,
              builder: (c, s) {
                if (s.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("App收到异常 ${s.error}")));
                }
                return ListTile(
                  title: Text(
                    "StreamBuilder: 数据",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    'Data Value: ${s.data}\n',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  /// 展示异常警告
                  trailing: s.error != null
                      ? const Text('ERROR', style: TextStyle(color: Colors.red))
                      : null,
                );
              },
            ),
            Text('将要发送的参数: $_counter'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        child: const Text('+'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
