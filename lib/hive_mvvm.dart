library hive_state_mvvm;

export 'hive_state.dart';
export 'package:provider/provider.dart' show ReadContext, Provider;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_state/hive_state.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// HiveState-MVVM

/// 1. Model [HsModel]
typedef HsModel = Object;

/// 2. View [HsView]
// typedef HsStreamBuilder<VM extends HsViewModel, T> = HsView<VM, T>;

typedef HsVmBuilder<VM, T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot, VM vm);

class HsView<VM extends HsViewModel, T> extends StatelessWidget {
  final HsVmBuilder<VM, T>? builder;
  final Widget Function(BuildContext context, VM vm, Object? e)? onError;
  final Widget Function(
    BuildContext context,
    T? s,
    VM vm,
    Object? _, // if onError is null and has error
  )? onData;
  final Stream<T> Function(VM vm)? stream;

  const HsView({
    super.key,
    this.builder,
    this.onError,
    required this.onData,
    this.stream,
  });

  const HsView.builder({
    super.key,
    required this.builder,
    this.onError,
    this.onData,
    this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VM>();
    return StreamBuilder<T>(
      stream: (stream?.call(vm) ?? vm.stream) as Stream<T>,
      builder: (c, s) {
        if (onError != null && s.hasError) {
          return onError!.call(c, vm, s.error);
        } else if (onData != null) {
          return onData!.call(
            c,
            s.data,
            vm,
            (s.hasError && onError == null) ? s.error : null,
          );
        } else {
          return builder?.call(c, s, vm) ??
              (throw 'onData or builder must be not null');
        }
      },
    );
  }
}

/// 3. ViewModel [HsViewModel]
abstract class HsViewModel<M extends HsModel> extends HiveState<M>
    with DiagnosticableTreeMixin {
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<M?>(
      'value',
      valueOrNull,
      description: 'current Model value',
    ));
  }
}

/// 4. Provider
/// - auto dispose [HsViewModel]
class HsViewModelProvider<VM extends HsViewModel<M>, M extends HsModel>
    extends Provider<VM> {
  HsViewModelProvider(
    Create<VM> create, {
    Key? key,
    Dispose<VM>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          dispose: (_, vm) {
            dispose?.call(_, vm);
            vm.dispose();
          },
          child: child,
        );

  static HsViewModelMultiProvider multi(
    Function? create, {
    Key? key,
    required List<SingleChildWidget> providers,
    TransitionBuilder? builder,
    Widget? child,
  }) =>
      HsViewModelMultiProvider(
        key: key,
        providers: [
          create?.call(),
          ...providers,
        ],
        builder: builder,
        child: child,
      );
}

class HsViewModelMultiProvider extends MultiProvider {
  HsViewModelMultiProvider({
    super.key,
    required super.providers,
    super.builder,
    super.child,
  });
}

extension HsViewModelX<VM extends HsViewModel> on HsViewModel {
  toProvider({
    Key? key,
    Function(VM vm)? onCreated,
    Dispose<VM>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) =>
      HsViewModelProvider(
        (context) {
          final vm = this as VM;
          onCreated?.call(vm);
          return vm;
        },
        key: key,
        dispose: (_, vm) {
          dispose?.call(_, vm);
          vm.dispose();
        },
        lazy: lazy,
        child: child,
      );
}
