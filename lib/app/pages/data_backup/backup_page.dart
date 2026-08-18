import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/backup/backup_operation.dart';
import '../../models/backup/backup_history_record.dart';
import '../../models/backup/backup_record_counts.dart';
import '../../models/domain/backup_management_state.dart';
import '../../models/domain/backup_run_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';
import '../shell/main_shell_controller.dart';
import 'backup_import_logic.dart';
import 'backup_management_logic.dart';

/// 数据备份页面，保留真实导入导出流程并按 Figma 状态稿组织信息层级。
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        appBar: AppBar(
          backgroundColor: theme.appPageBackground,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Get.back<void>();
              } else {
                Get.find<MainShellController>().switchToSettings();
              }
            },
            tooltip: '返回',
            icon: const AppSvgIcon(AppIconAssets.backupBack, size: 24),
          ),
          title: Text(
            '数据备份',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Get.find<MainShellController>().switchToHome(),
              tooltip: '返回首页',
              icon: const AppSvgIcon(AppIconAssets.backupHome, size: 24),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: GetBuilder<BackupManagementLogic>(
            id: BackupManagementLogic.exportUpdateId,
            builder: (management) => GetBuilder<BackupManagementLogic>(
              id: BackupManagementLogic.historyUpdateId,
              builder: (history) => GetBuilder<BackupImportLogic>(
                id: BackupImportLogic.stateUpdateId,
                builder: (importLogic) => _BackupBody(
                  exportState: management.exportState,
                  historyState: history.historyState,
                  importState: importLogic.state,
                  onExport: management.exportAndShare,
                  onResetExport: management.resetExport,
                  onLoadHistory: management.loadHistory,
                  onPickImport: importLogic.pickAndPreview,
                  onConfirmImport: importLogic.confirm,
                  onRetryImport: importLogic.retry,
                  onCancelImport: importLogic.cancel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BackupBody extends StatelessWidget {
  const _BackupBody({
    required this.exportState,
    required this.historyState,
    required this.importState,
    required this.onExport,
    required this.onResetExport,
    required this.onLoadHistory,
    required this.onPickImport,
    required this.onConfirmImport,
    required this.onRetryImport,
    required this.onCancelImport,
  });

  final BackupExportRunState exportState;
  final BackupHistoryRunState historyState;
  final BackupRunState importState;
  final Future<void> Function() onExport;
  final VoidCallback onResetExport;
  final Future<void> Function() onLoadHistory;
  final Future<void> Function() onPickImport;
  final Future<void> Function(BackupImportMode mode) onConfirmImport;
  final Future<void> Function() onRetryImport;
  final Future<void> Function() onCancelImport;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onLoadHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          Text(
            '学习数据',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '导入或导出词库、学习记录和个性化设置。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).appTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _ExportCard(
            state: exportState,
            onExport: onExport,
            onReset: onResetExport,
          ),
          const SizedBox(height: 20),
          _ImportCard(
            state: importState,
            onPick: onPickImport,
            onConfirm: onConfirmImport,
            onRetry: onRetryImport,
            onCancel: onCancelImport,
          ),
          const SizedBox(height: 18),
          const _ImportWarning(),
          const SizedBox(height: 28),
          _HistorySection(state: historyState, onRetry: onLoadHistory),
        ],
      ),
    );
  }
}

final class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.state,
    required this.onExport,
    required this.onReset,
  });

  final BackupExportRunState state;
  final Future<void> Function() onExport;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final busy =
        state.phase == BackupExportPhase.exporting ||
        state.phase == BackupExportPhase.sharing;
    return _BackupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ActionTitle(
            asset: AppIconAssets.backupExport,
            title: '导出备份',
            description: '生成 .json 文件，可用于转移或恢复学习数据。',
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: busy ? null : onExport,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('导出备份'),
            ),
          ),
          if (state.phase == BackupExportPhase.completed ||
              state.phase == BackupExportPhase.dismissed) ...[
            const SizedBox(height: 10),
            Text(
              state.phase == BackupExportPhase.completed
                  ? '已生成 ${state.fileName ?? '备份文件'}'
                  : '分享已取消，保护副本仍保存在应用目录。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.manifest != null)
              Text(
                '包含 ${_recordCount(state.manifest!.recordCounts)} 条用户记录',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            TextButton(onPressed: onReset, child: const Text('清除结果')),
          ],
          if (state.errorCode != null) ...[
            const SizedBox(height: 10),
            _BackupError(message: _exportError(state.errorCode!)),
          ],
        ],
      ),
    );
  }
}

final class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.state,
    required this.onPick,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
  });

  final BackupRunState state;
  final Future<void> Function() onPick;
  final Future<void> Function(BackupImportMode mode) onConfirm;
  final Future<void> Function() onRetry;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final busy =
        state.phase == BackupRunPhase.picking ||
        state.phase == BackupRunPhase.previewing ||
        state.phase == BackupRunPhase.importing;
    return _BackupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ActionTitle(
            asset: AppIconAssets.backupImport,
            title: '导入备份',
            description: '恢复时会合并可兼容的数据，并保留当前词库。',
          ),
          const SizedBox(height: 48),
          if (state.selectedFileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                state.selectedFileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (busy) ...[
            LinearProgressIndicator(value: state.progress?.fraction),
            const SizedBox(height: 8),
            Text(
              state.progress == null
                  ? '正在处理备份文件'
                  : _progressText(state.progress!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (state.preview != null &&
              state.phase == BackupRunPhase.awaitingConfirmation)
            _ImportPreview(
              state: state,
              onConfirm: onConfirm,
              onCancel: onCancel,
            ),
          if (state.report != null && state.phase == BackupRunPhase.completed)
            _ImportCompleted(report: state.report!),
          if (state.phase == BackupRunPhase.error) ...[
            _BackupError(message: _importError(state.errorCode)),
            Row(
              children: [
                TextButton(onPressed: onRetry, child: const Text('重试')),
                TextButton(onPressed: onCancel, child: const Text('取消')),
              ],
            ),
          ],
          if (state.phase == BackupRunPhase.idle ||
              state.phase == BackupRunPhase.error ||
              state.phase == BackupRunPhase.completed)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: busy ? null : onPick,
                child: const Text('选择备份文件'),
              ),
            ),
        ],
      ),
    );
  }
}

final class _ActionTitle extends StatelessWidget {
  const _ActionTitle({
    required this.asset,
    required this.title,
    required this.description,
  });

  final String asset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Center(
            child: AppSvgIcon(
              asset,
              size: 22,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).appTextSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ImportWarning extends StatelessWidget {
  const _ImportWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.appWarningSurface,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Text(
          '⚠ 导入前请确认备份文件来源可靠。',
          style: TextStyle(color: theme.appWarning, fontSize: 12),
        ),
      ),
    );
  }
}

final class _ImportPreview extends StatelessWidget {
  const _ImportPreview({
    required this.state,
    required this.onConfirm,
    required this.onCancel,
  });

  final BackupRunState state;
  final Future<void> Function(BackupImportMode mode) onConfirm;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final preview = state.preview!;
    final canImport = preview.canImport && !preview.isFutureFormat;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导入预览',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('包含 ${_recordCount(preview.recordCounts)} 条用户记录'),
          Text('当前数据 ${preview.existingRecordCount} 条'),
          Text(
            '冲突 ${preview.conflictCount} 条 · 拒绝 ${preview.rejectedRecordCount} 条',
          ),
          if (preview.isFutureFormat)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: _BackupError(message: '该备份来自更新版本，只能预览。'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: canImport
                      ? () => onConfirm(BackupImportMode.merge)
                      : null,
                  child: const Text('合并导入'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: canImport
                      ? () => _confirmOverwrite(
                          context,
                          preview.existingRecordCount,
                        )
                      : null,
                  child: const Text('覆盖恢复'),
                ),
              ),
            ],
          ),
          TextButton(onPressed: onCancel, child: const Text('取消预览')),
        ],
      ),
    );
  }

  Future<void> _confirmOverwrite(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认覆盖恢复？'),
        content: Text('将替换当前 $count 条用户数据。写入前会自动生成保护备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认覆盖'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onConfirm(BackupImportMode.overwrite);
    }
  }
}

final class _ImportCompleted extends StatelessWidget {
  const _ImportCompleted({required this.report});

  final BackupImportReport report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '${report.mode == BackupImportMode.merge ? '合并' : '覆盖'}完成：'
        '导入 ${_recordCount(report.importedCounts)} 条，'
        '跳过 ${_recordCount(report.skippedCounts)} 条。',
      ),
    );
  }
}

final class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.state, required this.onRetry});

  final BackupHistoryRunState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近备份',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _BackupCard(
          child: switch (state.phase) {
            BackupHistoryPhase.loading => const LinearProgressIndicator(),
            BackupHistoryPhase.empty => const Text('还没有备份操作记录。'),
            BackupHistoryPhase.error => Row(
              children: [
                const Expanded(child: Text('最近备份加载失败。')),
                TextButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ),
            _ => Column(
              children: [
                for (var index = 0; index < state.records.length; index++) ...[
                  _HistoryRow(record: state.records[index]),
                  if (index != state.records.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          },
        ),
      ],
    );
  }
}

final class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final BackupHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final type = switch (record.type) {
      'export' => '手动导出',
      'protection' => '本机备份',
      'import' => '导入恢复',
      'reset' => '清除前备份',
      _ => record.type,
    };
    final time = record.occurredAt.toLocal();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: record.result == 'success'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).appError,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${time.year}/${_two(time.month)}/${_two(time.day)} · '
                  '${record.fileName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.appCardSurface,
      elevation: isDark ? 0 : 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: theme.appBorder),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

final class _BackupError extends StatelessWidget {
  const _BackupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: TextStyle(color: Theme.of(context).appError));
  }
}

String _progressText(BackupProgress progress) {
  final label = switch (progress.stage) {
    BackupProgressStage.picking => '正在复制备份文件',
    BackupProgressStage.decoding => '正在校验备份压缩包',
    BackupProgressStage.analyzing => '正在分析内容冲突',
    BackupProgressStage.protecting => '正在生成保护备份',
    BackupProgressStage.writing => '正在写入学习数据',
    BackupProgressStage.completed => '备份操作完成',
  };
  return progress.fraction == null
      ? label
      : '$label ${(progress.fraction! * 100).round()}%';
}

String _exportError(String code) => switch (code) {
  BackupExportErrorCodes.exportFailed => '备份导出失败，请重试。',
  BackupExportErrorCodes.shareFailed => '分享备份失败，请重试。',
  BackupExportErrorCodes.shareUnavailable => '当前平台没有可用的分享能力。',
  _ => '备份导出失败，请重试。',
};

String _importError(String? code) => switch (code) {
  BackupRunErrorCodes.pickFailed => '选择备份文件失败。',
  BackupRunErrorCodes.previewFailed => '备份预检失败，文件可能已损坏。',
  BackupRunErrorCodes.importFailed => '备份导入失败，原有数据未被覆盖。',
  BackupRunErrorCodes.futureVersion => '备份来自更新版本，只能预览。',
  _ => '备份操作失败，请重试。',
};

int _recordCount(BackupRecordCounts counts) {
  return counts.userWordStates +
      counts.favoriteWords +
      counts.favoriteSentences +
      counts.practiceSessions +
      counts.practiceAnswers +
      counts.learningEvents +
      counts.appSettings;
}

String _two(int value) => value.toString().padLeft(2, '0');
