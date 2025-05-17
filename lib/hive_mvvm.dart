library hive_state_mvvm;

export 'hive_state.dart';
export 'package:provider/provider.dart' show ReadContext, Provider;

import 'package:flutter/widgets.dart';
import 'package:hive_state/hive_state.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// HiveState-MVVM

class HsViewModelProvider<VM extends HiveState<M>, M> extends Provider<VM> {
  HsViewModelProvider({
    super.key,
    required super.create,
    super.dispose,
    super.lazy,
    super.builder,
    super.child,
  });

  static HsViewModelMultiProvider multi({
    Key? key,
    Function? create,
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

// typedef HsStreamBuilder<VM extends HiveState, T> = HsView<VM, T>;

typedef HsVmBuilder<VM, T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot, VM vm);

class HsView<VM extends HiveState, T> extends StatelessWidget {
  final HsVmBuilder<VM, T>? builder;
  final Widget Function(BuildContext context, VM vm, Object? e)? onError;
  final Widget Function(
    BuildContext context,
    AsyncSnapshot<T> snapshot,
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
        if (s.hasError && onError != null) onError!.call(c, vm, s.error);
        return onData?.call(
              c,
              s,
              vm,
              (s.hasError && onError == null) ? s.error : null,
            ) ??
            builder?.call(c, s, vm) ??
            (throw 'onData or builder must be not null');
      },
    );
  }
}
