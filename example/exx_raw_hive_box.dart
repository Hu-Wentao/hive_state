import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(kBoxState);
  runApp(const MaterialApp(
    title: 'Hive State Demo',
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

const kBoxState = 'kBoxState';
const kMockFooData = 'kMockFooData';

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
      Hive.box<String>(kBoxState).put(kMockFooData, data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("App收到异常 $e")));
      }
    }

    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hive State Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              /// 监听正常数据
              // stream: Hive.box<String>(kBoxState).watch(key: kMockFooData),
              /// 监听正常数据以及异常数据(监听 kMockFooData结尾的key; err:开头代表异常信息)
              stream: Hive.box<String>(kBoxState)
                  .watch()
                  .where((event) => '${event.key}'.endsWith(kMockFooData)),
              builder: (c, s) {
                return ListTile(
                  title: Text(
                    "StreamBuilder: 监听数据",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    'Data Key: ${s.data?.key}\n'
                    'Data Value: ${s.data?.value}\n',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
            Text('将要发送的参数: $_counter'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        child: const Icon(Icons.refresh_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
