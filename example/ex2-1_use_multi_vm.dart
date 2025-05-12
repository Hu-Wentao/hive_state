import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_state/hive_state.dart';

/// 本示例 ViewModel依赖用法
class CategoryModel {
  // data
  List<String> categories;

  // state
  String? chosenCategory;

  CategoryModel({this.categories = const [], this.chosenCategory});
}

class CategoryViewModel extends HiveState<CategoryModel> {
  @override
  CategoryModel? get initValue => null;

  init() {
    _fetch();
  }

  _fetch() async => await update((old) {
        // 模拟API请求
        return old..categories = ['A', 'B', 'C'];
      });

  chosen(int idx) {
    update((old) {
      return old..chosenCategory = old.categories[idx];
    });
  }
}

/// 1. MVVM.Model
///   Model 只包括数据转换逻辑,值对象逻辑
///   虽然VM是全局可访问的, 但是不要从Model中访问其他VM以及其他VM的数据
class ArticleListModel {
  List<String> data;

  /// constructor: new model
  ArticleListModel({required this.data});
}

/// 2. MVVM.ViewModel
/// ViewModel 包括主要业务逻辑: 数据加载, 处理, 转换...
///   VM的方法只返回 void 或 Stream, UI根据Model或Stream刷新
///     void 用于各类widget的 onTap函数
///     Stream 用于StreamBuilder
///   VM内部可以访问其他VM的数据(其他VM的M中的数据)
/// FooState 自定义状态类
/// - `extends HiveState<MyArticleModel>`: 使用[ArticleListModel]类型的状态
class MyArticleViewModel extends HiveState<ArticleListModel> {
  /// VM不可以存储Model数据,但是可以存储其他VM, 以及其他Repository
  final CategoryViewModel vmCategory;

  /// 一般情况下HiveState的Model是全局唯一的.如果有必要,可以使用tag来区分不同的Model实例
  /// [tag]允许你在同一个App中使用多个不同的实例
  MyArticleViewModel({required this.vmCategory, String? tag}) : super(tag: tag);

  /// 2.0: 创建数据请求函数, API, 数据库, 设备...
  /// 模拟API请求
  Future<List<String>> _fetchChosenCategoryArticles() async {
    final chosen = vmCategory.valueOrNull?.chosenCategory;
    await Future.delayed(const Duration(seconds: 1));
    return [
      'Article1: [$chosen] some content',
      'Article2: [$chosen] some content'
    ];
  }

  /// 2.1.A: 通过[initValue]快速设置初始值
  @override
  ArticleListModel? get initValue => ArticleListModel(data: []);

  /// 2.1.B: 初始化方法: 手动显式初始化模型数据
  /// 使用[updateOrNull]方法, 允许在没有初始值([initValue]==null)的情况下进行[update]
  /// 也可以在这里调用[updateDate]方法
  Future<void> init() async {
    await refresh();
  }

  /// 2.2: VM Biz logic method
  /// 2.2: VM 业务逻辑
  /// [_fetchChosenCategoryArticles] 获取网络数据
  /// [vmCategory] 外部依赖
  /// [update],[putError],[valueOrNull] 为[HiveState]的成员方法
  /// 使用[update] 自动捕获异常

  refresh() async {
    return update((old) async {
      return old..data = await _fetchChosenCategoryArticles();
    });
  }
}

/// ----

Future<void> main() async {
  runApp(const MaterialApp(
    title: 'HiveState:Global Demo',
    home: MyHomePage(),
  ));
}

/// 3. MVVM.View
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final vm = MyArticleViewModel(
    vmCategory: CategoryViewModel(),
  );

  @override
  void initState() {
    vm.init(); // 初始化

    // 监听报错方式2
    vm.stream.listen((event) {}, onError: (e) {
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
              stream: vm.stream,
              builder: (c, s) {
                if (s.hasError) {
                  // 监听异常方式1
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text("App收到异常 ${s.error}")));
                }
                return ListView.builder(
                  itemBuilder: (c, i) {
                    final value = s.data?.data.elementAtOrNull(i);
                    if (value == null) return null;
                    return ListTile(
                      title: Text(
                        "StreamBuilder: 监听数据",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      /// 展示异常警告
                      trailing: s.error != null
                          ? const Text('ERROR',
                              style: TextStyle(color: Colors.red))
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.refresh,
        child: const Text('+'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
