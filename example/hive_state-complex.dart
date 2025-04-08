import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_state/hive_state.dart';

/// 1. MVVM.Model
class BarModel {
  String barContent;
  int page;

  /// constructor: new model
  BarModel({required this.barContent, required this.page});

  /// constructor: old model & update param
  BarModel.of(
    BarModel? old, {
    String? barContent,
    int? page,
  })  :

        /// new value | old value | init value
        barContent = barContent ?? old?.barContent ?? '',
        page = page ?? old?.page ?? -1;
}

/// 2. MVVM.ViewModel
/// FooState 自定义状态类
/// - `extends HiveState<BarModel>`: 使用[BarModel]类型的状态
class BarState extends HiveState<BarModel> {
  /// [mockFooAPI] 获取网络数据
  /// [update],[putError],[valueOrNull] 为[HiveState]的成员方法
  Future<void> fetchData() async {
    try {
      final data = await mockFooAPI(valueOrNull?.page ?? 0);
      // 更新状态,计数器+1
      update((old) => BarModel.of(
            old,
            barContent: data,
            page: old.page + 1,
          ));
    } catch (e) {
      // 捕获到异常
      putError(e);
    }
  }
}

/// ----

Future<void> main() async {
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

/// 3. MVVM.View
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo: 不在本地缓存数据')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              /// 使用时直接新建实例, 所有实例共享stream
              stream: BarState().stream,
              builder: (c, s) {
                if (s.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("App收到异常 ${s.error}")));
                }
                return ListTile(
                  title: Text(
                    "StreamBuilder: 监听数据",
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
            StreamBuilder(
              stream: BarState().stream,
              builder: (c, s) => Text('将要发送的参数: ${s.data?.page}'),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: BarState().fetchData,
        child: const Text('+'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
