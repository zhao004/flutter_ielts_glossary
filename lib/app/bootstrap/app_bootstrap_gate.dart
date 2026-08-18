import 'dart:async';

import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'application_bootstrap_service.dart';

typedef AppDependenciesInitializer =
    Future<AppDependencies> Function({
      ApplicationBootstrapProgressCallback? onProgress,
    });
typedef InitializedAppBuilder = Widget Function(AppDependencies dependencies);

/// 在根应用启动前展示本地数据初始化状态，并允许失败后安全重试。
class AppBootstrapGate extends StatefulWidget {
  const AppBootstrapGate({
    required this.initialize,
    required this.appBuilder,
    super.key,
  });

  final AppDependenciesInitializer initialize;
  final InitializedAppBuilder appBuilder;

  @override
  State<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends State<AppBootstrapGate> {
  AppDependencies? _dependencies;
  Object? _error;
  ApplicationBootstrapProgress? _progress;
  var _attempt = 0;
  var _recovering = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize(showLoading: false));
  }

  @override
  void dispose() {
    _attempt++;
    final dependencies = _dependencies;
    if (dependencies != null) {
      unawaited(dependencies.close());
    }
    super.dispose();
  }

  Future<void> _initialize({required bool showLoading}) async {
    final attempt = ++_attempt;
    if (showLoading && mounted) {
      setState(() {
        _error = null;
        _progress = null;
      });
    }
    try {
      final dependencies = await widget.initialize(
        onProgress: (progress) {
          if (!mounted || attempt != _attempt) {
            return;
          }
          setState(() {
            _progress = progress;
          });
        },
      );
      if (!mounted || attempt != _attempt) {
        await dependencies.close();
        return;
      }
      setState(() {
        _dependencies = dependencies;
        _error = null;
        _progress = null;
      });
    } on Object catch (error) {
      if (!mounted || attempt != _attempt) {
        return;
      }
      setState(() {
        _error = error;
        _progress = null;
      });
    }
  }

  Future<void> _recover(
    ApplicationBootstrapRecoveryAction recoveryAction,
  ) async {
    if (_recovering || !mounted) {
      return;
    }
    setState(() {
      _recovering = true;
      _error = null;
    });
    try {
      await recoveryAction();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _recovering = false;
          _error = error;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _recovering = false;
    });
    await _initialize(showLoading: false);
  }

  Future<void> _confirmRecovery(
    BuildContext context,
    ApplicationBootstrapRecoveryAction recoveryAction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重建学习数据？'),
        content: const Text(
          '应用会先备份旧用户数据库，再创建新的空学习数据。只读词库不会受到影响，原有学习记录需要从备份中恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('备份并重建'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      unawaited(_recover(recoveryAction));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies != null) {
      return widget.appBuilder(dependencies);
    }
    return MaterialApp(
      title: '雅思词汇库',
      debugShowCheckedModeBanner: false,
      home: _BootstrapStatusPage(
        failed: _error != null,
        progress: _progress,
        onRetry: () => unawaited(_initialize(showLoading: true)),
        recovering: _recovering,
        onRecover:
            _error is ApplicationBootstrapException &&
                (_error as ApplicationBootstrapException).recoveryAction != null
            ? (context) => _confirmRecovery(
                context,
                (_error as ApplicationBootstrapException).recoveryAction!,
              )
            : null,
      ),
    );
  }
}

class _BootstrapStatusPage extends StatelessWidget {
  const _BootstrapStatusPage({
    required this.failed,
    required this.progress,
    required this.onRetry,
    required this.recovering,
    required this.onRecover,
  });

  final bool failed;
  final ApplicationBootstrapProgress? progress;
  final VoidCallback onRetry;
  final bool recovering;
  final Future<void> Function(BuildContext context)? onRecover;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = progress?.fraction;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: failed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                          semanticLabel: '初始化失败',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onRecover == null ? '本地词库暂时不可用' : '本地学习数据需要重建',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          onRecover == null
                              ? '请检查应用数据后重试。'
                              : '旧用户数据库会先备份到应用私有目录，词库不会被删除。',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: recovering ? null : onRetry,
                          icon: recovering
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(recovering ? '正在重建' : '重试'),
                        ),
                        if (onRecover != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: recovering
                                ? null
                                : () => onRecover!(context),
                            icon: const Icon(Icons.restore_page_outlined),
                            label: const Text('备份并重建学习数据'),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(value: fraction),
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _progressLabel(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (fraction != null) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(value: fraction),
                          const SizedBox(height: 8),
                          Text('${(fraction * 100).round()}%'),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _progressLabel() {
    return switch (progress?.stage) {
      ApplicationBootstrapStage.installingContent => '正在准备本地词库',
      ApplicationBootstrapStage.openingContentDatabase => '正在打开本地词库',
      ApplicationBootstrapStage.openingUserDatabase => '正在打开学习数据',
      ApplicationBootstrapStage.creatingRepositories => '正在准备应用功能',
      null => '正在准备本地词库',
    };
  }
}
