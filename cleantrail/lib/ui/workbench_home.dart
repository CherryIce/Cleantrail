import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../domain/data_project.dart';
import '../state/workbench_controller.dart';

class WorkbenchHome extends StatelessWidget {
  const WorkbenchHome({
    required this.controller,
    required this.onLocaleChanged,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final project = controller.project;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Row(
              children: [
                const _AppMark(),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    context.s.appName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => onLocaleChanged(
                  context.s.isChinese ? const Locale('en') : const Locale('zh'),
                ),
                child: Text(context.s.get('language')),
              ),
              IconButton(
                tooltip: context.s.get('privacy'),
                onPressed: () => _showPrivacy(context),
                icon: const Icon(Icons.privacy_tip_outlined),
              ),
              if (project != null)
                PopupMenuButton<String>(
                  tooltip: context.s.get('project'),
                  onSelected: (value) async {
                    if (value == 'new') {
                      await _confirmNewFile(context);
                    } else if (value == 'remove' && context.mounted) {
                      await _confirmClear(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'new',
                      child: Text(context.s.get('newFile')),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(context.s.get('remove')),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (controller.busy) const LinearProgressIndicator(),
                if (controller.errorCode != null)
                  MaterialBanner(
                    content: Text(context.s.get(controller.errorCode!)),
                    leading: const Icon(Icons.error_outline),
                    actions: [
                      TextButton(
                        onPressed: controller.dismissError,
                        child: Text(context.s.get('close')),
                      ),
                    ],
                  ),
                Expanded(
                  child: project == null
                      ? _EmptyWorkspace(
                          busy: controller.busy,
                          onImport: controller.importCsv,
                          onSample: controller.loadSample,
                        )
                      : _ProjectDashboard(controller: controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.get('deleteConfirmTitle')),
        content: Text(context.s.get('deleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s.get('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.s.get('remove')),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clear();
  }

  Future<void> _confirmNewFile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.get('newFileConfirmTitle')),
        content: Text(context.s.get('newFileConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.s.get('continueImport')),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.importCsv();
  }

  Future<void> _showPrivacy(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.s.get('privacy'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      context.s.get('privacyBody'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.s.get('close')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'CleanTrail',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 3, height: 22, color: colors.onPrimary),
            Container(width: 22, height: 3, color: colors.onPrimary),
            Icon(Icons.check, size: 18, color: colors.secondaryContainer),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace({
    required this.busy,
    required this.onImport,
    required this.onSample,
  });

  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onSample;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.s.get('emptyTitle'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.s.get('emptyBody'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.s.get('howItWorks'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _TrailStep(text: context.s.get('step1')),
                      _TrailStep(text: context.s.get('step2')),
                      _TrailStep(text: context.s.get('step3'), last: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: busy ? null : onImport,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(context.s.get('importCsv')),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : onSample,
                child: Text(context.s.get('trySample')),
              ),
              const SizedBox(height: 12),
              Text(
                context.s.get('privacyPromise'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailStep extends StatelessWidget {
  const _TrailStep({required this.text, this.last = false});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!last)
              Container(width: 2, height: 30, color: color.withAlpha(70)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ProjectDashboard extends StatelessWidget {
  const _ProjectDashboard({required this.controller});

  final WorkbenchController controller;

  @override
  Widget build(BuildContext context) {
    final project = controller.project!;
    return CustomScrollView(
      key: const Key('project-dashboard'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 42),
          sliver: SliverList.list(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProjectHeader(project: project),
                      const SizedBox(height: 18),
                      _ScoreCard(project: project),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: context.s.get('reviewQueue'),
                        trailing: controller.canUndo
                            ? TextButton.icon(
                                onPressed: controller.undo,
                                icon: const Icon(Icons.undo, size: 18),
                                label: Text(context.s.get('undo')),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      if (project.openIssues.isEmpty)
                        _AllClearCard(project: project)
                      else
                        _IssueQueue(
                          issues: project.openIssues,
                          project: project,
                          onTap: (issue) => _showIssue(context, issue),
                        ),
                      const SizedBox(height: 18),
                      _SectionHeader(title: context.s.get('preview')),
                      const SizedBox(height: 10),
                      _NumericPreview(project: project),
                      const SizedBox(height: 12),
                      _TablePreview(project: project),
                      const SizedBox(height: 28),
                      _ExportCard(
                        project: project,
                        busy: controller.busy,
                        onExport: (origin) => controller.export(
                          chinese: context.s.isChinese,
                          shareOrigin: origin,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.s.get('offlineFooter'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showIssue(BuildContext context, DataIssue issue) async {
    final project = controller.project!;
    final input = TextEditingController(text: issue.suggestion ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          4,
          22,
          22 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _issueTitle(sheetContext, issue.kind),
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(_issueBody(sheetContext, issue.kind)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      '${sheetContext.s.get('row')} ${_rowNumber(issue)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      issue.columnIndex == null
                          ? '—'
                          : _displayHeader(
                              sheetContext,
                              project,
                              issue.columnIndex!,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ValueBlock(
                label: sheetContext.s.get('original'),
                value: issue.originalValue.isEmpty ? '—' : issue.originalValue,
              ),
              if (issue.kind != IssueKind.duplicateRow) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: input,
                  autofocus: issue.suggestion == null,
                  decoration: InputDecoration(
                    labelText: issue.suggestion == null
                        ? sheetContext.s.get('replacementHint')
                        : sheetContext.s.get('suggested'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(sheetContext);
                  await controller.resolveIssue(
                    issue.id,
                    replacement: issue.kind == IssueKind.duplicateRow
                        ? null
                        : input.text,
                  );
                  if (sheetContext.mounted && controller.errorCode == null) {
                    navigator.pop();
                  }
                },
                child: Text(
                  issue.kind == IssueKind.duplicateRow
                      ? sheetContext.s.get('removeDuplicate')
                      : issue.suggestion == null
                      ? sheetContext.s.get('apply')
                      : sheetContext.s.get('applySuggestion'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(sheetContext);
                  await controller.resolveIssue(issue.id, ignore: true);
                  if (sheetContext.mounted) navigator.pop();
                },
                child: Text(sheetContext.s.get('keepOriginal')),
              ),
            ],
          ),
        ),
      ),
    );
    input.dispose();
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});
  final DataProject project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.s.get('project').toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          project.fileName,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '${project.records.length} ${context.s.get('rows')} · '
          '${project.headers.length} ${context.s.get('columns')} · '
          '${project.openIssues.length} ${context.s.get('openIssues')}',
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.project});
  final DataProject project;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Semantics(
              label: '${context.s.get('qualityScore')} ${project.qualityScore}',
              child: SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: project.qualityScore / 100,
                      strokeWidth: 9,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                    Text(
                      '${project.qualityScore}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s.get('qualityScore'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${project.fixedCount} ${context.s.get('fixed')} · '
                    '${project.ignoredCount} ${context.s.get('kept')}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.s.get('sourceProtected'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.project,
    required this.onTap,
  });

  final DataIssue issue;
  final DataProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _issueIcon(issue.kind),
                  color: colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _issueTitle(context, issue.kind),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.s.get('row')} ${_rowNumber(issue)} · '
                      '${issue.columnIndex == null ? '—' : _displayHeader(context, project, issue.columnIndex!)}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueQueue extends StatelessWidget {
  const _IssueQueue({
    required this.issues,
    required this.project,
    required this.onTap,
  });

  final List<DataIssue> issues;
  final DataProject project;
  final ValueChanged<DataIssue> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: math.min(600, math.max(94, issues.length * 86)).toDouble(),
    child: ListView.separated(
      primary: false,
      itemCount: issues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final issue = issues[index];
        return _IssueCard(
          issue: issue,
          project: project,
          onTap: () => onTap(issue),
        );
      },
    ),
  );
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard({required this.project});
  final DataProject project;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.s.get('allClear'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(context.s.get('allClearBody')),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 5),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _TablePreview extends StatelessWidget {
  const _TablePreview({required this.project});
  final DataProject project;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(5, project.records.length);
    final rangeLabel = context.s
        .get('previewRows')
        .replaceAll('{shown}', '$shown')
        .replaceAll('{total}', '${project.records.length}');
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                rangeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: DataTable(
                  columns: List.generate(
                    project.headers.length,
                    (index) => DataColumn(
                      label: Text(_displayHeader(context, project, index)),
                    ),
                  ),
                  rows: project.records.take(5).map((row) {
                    return DataRow(
                      cells: row.values
                          .map(
                            (value) =>
                                DataCell(Text(value.isEmpty ? '—' : value)),
                          )
                          .toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericPreview extends StatelessWidget {
  const _NumericPreview({required this.project});
  final DataProject project;

  @override
  Widget build(BuildContext context) {
    var column = -1;
    var values = <double>[];
    for (var index = 0; index < project.headers.length; index++) {
      final candidate = project.records
          .map((row) => double.tryParse(row.values[index].trim()))
          .whereType<double>()
          .where((value) => value.isFinite)
          .toList();
      if (candidate.length >= 2) {
        column = index;
        values = candidate;
        break;
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              column < 0
                  ? context.s.get('chartTitle')
                  : _displayHeader(context, project, column),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (column < 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Center(child: Text(context.s.get('chartEmpty'))),
              )
            else
              Semantics(
                image: true,
                label: _chartSemantics(context, project, column, values),
                child: SizedBox(
                  height: 130,
                  child: CustomPaint(
                    painter: _LinePreviewPainter(
                      values: values,
                      color: Theme.of(context).colorScheme.primary,
                      grid: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              context.s.get('beforeAfter'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePreviewPainter extends CustomPainter {
  const _LinePreviewPainter({
    required this.values,
    required this.color,
    required this.grid,
  });
  final List<double> values;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = grid;
    for (var step = 0; step < 4; step++) {
      final y = size.height * step / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - ((values[index] - minValue) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LinePreviewPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.project,
    required this.busy,
    required this.onExport,
  });
  final DataProject project;
  final bool busy;
  final ValueChanged<Rect> onExport;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.s.get('export'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(context.s.get('exportNote')),
          if (project.openIssues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.s.get('exportDraftNote'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () {
                    final box = context.findRenderObject() as RenderBox;
                    final origin = box.localToGlobal(Offset.zero) & box.size;
                    onExport(origin);
                  },
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(context.s.get('export')),
          ),
        ],
      ),
    ),
  );
}

String _issueTitle(BuildContext context, IssueKind kind) => switch (kind) {
  IssueKind.missingValue => context.s.get('missingValue'),
  IssueKind.duplicateRow => context.s.get('duplicateRow'),
  IssueKind.surroundingWhitespace => context.s.get('surroundingWhitespace'),
  IssueKind.inconsistentType => context.s.get('inconsistentType'),
  IssueKind.inconsistentDate => context.s.get('inconsistentDate'),
};

String _issueBody(BuildContext context, IssueKind kind) => switch (kind) {
  IssueKind.missingValue => context.s.get('missingValueBody'),
  IssueKind.duplicateRow => context.s.get('duplicateRowBody'),
  IssueKind.surroundingWhitespace => context.s.get('surroundingWhitespaceBody'),
  IssueKind.inconsistentType => context.s.get('inconsistentTypeBody'),
  IssueKind.inconsistentDate => context.s.get('inconsistentDateBody'),
};

IconData _issueIcon(IssueKind kind) => switch (kind) {
  IssueKind.missingValue => Icons.hourglass_empty,
  IssueKind.duplicateRow => Icons.copy_all_outlined,
  IssueKind.surroundingWhitespace => Icons.space_bar,
  IssueKind.inconsistentType => Icons.data_object,
  IssueKind.inconsistentDate => Icons.calendar_month_outlined,
};

String _rowNumber(DataIssue issue) => issue.rowId.replaceFirst('row-', '');

String _displayHeader(BuildContext context, DataProject project, int column) {
  final header = project.headers[column];
  return header.trim().isEmpty
      ? '${context.s.get('column')} ${column + 1}'
      : header;
}

String _chartSemantics(
  BuildContext context,
  DataProject project,
  int column,
  List<double> values,
) {
  final minimum = values.reduce(math.min);
  final maximum = values.reduce(math.max);
  final name = _displayHeader(context, project, column);
  return context.s.isChinese
      ? '$name：${values.length} 个有限数值，最小值 $minimum，最大值 $maximum'
      : '$name: ${values.length} finite values, minimum $minimum, maximum $maximum';
}
