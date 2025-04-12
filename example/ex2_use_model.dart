import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_state/hive_state.dart';

/// 1. MVVM.Model
///   Model 只包括数据转换逻辑,值对象逻辑
///   虽然VM是全局可访问的, 但是不要从Model中访问其他VM以及其他VM的数据
class MyArticleModel {
  String barContent;
  int page;

  /// constructor: new model
  MyArticleModel({required this.barContent, required this.page});

  /// constructor: old model & update param
  MyArticleModel.of(
    MyArticleModel? old, {
    String? barContent,
    int? page,
  })  :

        /// new value | old value | init value
        barContent = barContent ?? old?.barContent ?? '',
        page = page ?? old?.page ?? -1;
}

/// 2. MVVM.ViewModel
/// ViewModel 包括主要业务逻辑: 数据加载, 处理, 转换...
///   VM的方法只返回 void 或 Stream, UI根据Model或Stream刷新
///     void 用于各类widget的 onTap函数
///     Stream 用于StreamBuilder
///   VM内部可以访问其他VM的数据(其他VM的M中的数据)
/// FooState 自定义状态类
/// - `extends HiveState<MyArticleModel>`: 使用[MyArticleModel]类型的状态
class MyArticleState extends HiveState<MyArticleModel> {
  /// 2.1 SET Init Value
  /// 设置初始值, 否则[update]函数将会在没有初始值时报错
  @override
  StreamController<MyArticleModel> onCreate({MyArticleModel? initValue}) =>
      super.onCreate(initValue: MyArticleModel(barContent: '', page: 0));

  /// 2.2 MV Biz logic method
  /// 2.2 MV 业务逻辑
  /// [mockFooAPI] 获取网络数据
  /// [update],[putError],[valueOrNull] 为[HiveState]的成员方法
  Future<void> fetchData() async {
    try {
      final data = await mockFooAPI(valueOrNull?.page ?? 0);
      // 更新状态,计数器+1
      update((old) => MyArticleModel.of(
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
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // 监听报错方式2
    MyArticleState().stream.listen((event) {}, onError: (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("App收到异常 $e")));
    });
    super.initState();
  }

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
              stream: MyArticleState().stream,
              builder: (c, s) {
                if (s.hasError) {
                  // 监听异常方式1
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text("App收到异常 ${s.error}")));
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
              stream: MyArticleState().stream,
              builder: (c, s) => Text('将要发送的参数: ${s.data?.page}'),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: MyArticleState().fetchData,
        child: const Text('+'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
