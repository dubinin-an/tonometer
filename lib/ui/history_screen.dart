import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/app_database.dart';
import '../data/measurement_repository.dart';
import '../data/reminder_repository.dart';
import '../data/tonometer_profile_repository.dart';
import '../l10n/l10n.dart';
import '../services/csv_export_service.dart';
import '../services/reminder_notification_service.dart';
import '../services/seven_segment_recognizer.dart';
import 'camera_screen.dart';
import 'history_chart.dart';
import 'history_filter_screen.dart';
import 'measurement_form_screen.dart';
import 'measurement_series_screen.dart';
import 'privacy_policy_screen.dart';
import 'reminders_screen.dart';
import 'tonometers_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.repository,
    required this.reminderRepository,
    required this.notifications,
    required this.recognizer,
    required this.csvExporter,
    required this.locale,
    required this.onLocaleChanged,
    this.tonometerProfiles,
    super.key,
  });

  final MeasurementRepository repository;
  final ReminderRepository reminderRepository;
  final ReminderNotificationService notifications;
  final SevenSegmentRecognizer recognizer;
  final CsvExportService csvExporter;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final TonometerProfileRepository? tonometerProfiles;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  var _showChart = false;
  var _newestFirst = true;
  var _filter = const HistoryFilter();
  final Map<DateTime, bool> _dayExpansionOverrides = {};
  bool? _allDaysExpanded;

  Future<void> _openFilter(BuildContext context) async {
    final result = await Navigator.of(context).push<HistoryFilter>(
      MaterialPageRoute(
        builder: (_) => HistoryFilterScreen(initialFilter: _filter),
      ),
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  void _toggleSort() => setState(() => _newestFirst = !_newestFirst);

  bool _isDayExpanded(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final overridden = _dayExpansionOverrides[day];
    if (overridden != null) return overridden;
    final now = DateTime.now();
    final isToday = day == DateTime(now.year, now.month, now.day);
    if (_allDaysExpanded == true) return true;
    return isToday;
  }

  void _toggleDay(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    setState(() => _dayExpansionOverrides[day] = !_isDayExpanded(day));
  }

  void _toggleAllDays() {
    setState(() {
      _allDaysExpanded = _allDaysExpanded != true;
      _dayExpansionOverrides.clear();
    });
  }

  Future<void> _openCamera(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          repository: widget.repository,
          recognizer: widget.recognizer,
        ),
      ),
    );
  }

  // Kept for the manually-entered measurement action when it is enabled.
  // ignore: unused_element
  Future<void> _openManual(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MeasurementFormScreen(repository: widget.repository),
      ),
    );
  }

  Future<void> _openSeries(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MeasurementSeriesScreen(
          repository: widget.repository,
          recognizer: widget.recognizer,
        ),
      ),
    );
  }

  Future<void> _convertToSeries(
    BuildContext context,
    Measurement measurement,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MeasurementSeriesScreen(
          repository: widget.repository,
          recognizer: widget.recognizer,
          initialMeasurements: [measurement],
        ),
      ),
    );
  }

  Future<void> _addMeasurementToSeries(
    BuildContext context,
    int seriesId,
  ) async {
    final measurements = await widget.repository.getSeriesMeasurements(
      seriesId,
    );
    if (!context.mounted) return;
    if (measurements.length >= 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.seriesHasMaximum)));
      return;
    }
    final comment = await widget.repository.getSeriesComment(seriesId);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MeasurementSeriesScreen(
          repository: widget.repository,
          recognizer: widget.recognizer,
          initialMeasurements: measurements,
          existingSeriesId: seriesId,
          initialComment: comment,
        ),
      ),
    );
  }

  Future<void> _openReminders(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RemindersScreen(
          repository: widget.reminderRepository,
          notifications: widget.notifications,
        ),
      ),
    );
  }

  Future<void> _openTonometers(BuildContext context) async {
    final profiles = widget.tonometerProfiles;
    if (profiles == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TonometersScreen(
          repository: profiles,
          measurementRepository: widget.repository,
          recognizer: widget.recognizer,
        ),
      ),
    );
  }

  Future<void> _openPrivacy(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _edit(BuildContext context, Measurement measurement) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MeasurementFormScreen(
          repository: widget.repository,
          measurement: measurement,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Measurement measurement) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteMeasurementTitle),
        content: Text(
          l10n.deleteMeasurementMessage(
            measurement.systolic,
            measurement.diastolic,
            measurement.pulse,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.doNotDelete),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.repository.deleteMeasurement(measurement.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteEntryFailed(error.toString()))),
      );
    }
  }

  Future<void> _deleteSeries(
    BuildContext context,
    int seriesId,
    int count,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSeriesTitle),
        content: Text(l10n.deleteSeriesMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.doNotDelete),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.repository.deleteSeries(seriesId);
  }

  Future<void> _export(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final measurements = await widget.repository.getAll();
      if (!context.mounted) return;
      if (measurements.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.nothingToExport)));
        return;
      }
      await widget.csvExporter.export(
        measurements,
        series: await widget.repository.getSeriesBackup(),
        shareTitle: l10n.csvShareTitle,
        subject: l10n.csvSubject,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(error.toString()))),
      );
    }
  }

  Future<void> _restoreCsv(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final backup = widget.csvExporter.decodeBytes(bytes);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.restoreMeasurementsTitle),
          content: Text(
            l10n.restoreMeasurementsMessage(
              backup.measurements.length,
              backup.seriesCount,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.restore),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.repository.restoreBackup(backup);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.restoreMeasurementsComplete(backup.measurements.length),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreMeasurementsFailed(error.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ExcludeSemantics(
              child: Image.asset(
                'assets/branding/tonometer_app_icon.png',
                width: 38,
                height: 38,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (!_showChart)
            IconButton(
              key: const ValueKey('toggle_all_days'),
              tooltip: _allDaysExpanded == true
                  ? l10n.collapseAllDays
                  : l10n.expandAllDays,
              onPressed: _toggleAllDays,
              icon: Icon(
                _allDaysExpanded == true
                    ? Icons.unfold_less
                    : Icons.unfold_more,
              ),
            ),
          IconButton(
            tooltip: _newestFirst ? l10n.sortOldestFirst : l10n.sortNewestFirst,
            onPressed: _toggleSort,
            icon: Icon(
              _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
          IconButton(
            tooltip: _showChart ? l10n.showTable : l10n.showChart,
            onPressed: () => setState(() => _showChart = !_showChart),
            icon: Icon(
              _showChart ? Icons.table_rows_outlined : Icons.show_chart,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.appMenu,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  _openFilter(context);
                case 'reminders':
                  _openReminders(context);
                case 'tonometers':
                  _openTonometers(context);
                case 'export':
                  _export(context);
                case 'restore_csv':
                  _restoreCsv(context);
                case 'privacy':
                  _openPrivacy(context);
                case 'ru' || 'en' || 'es':
                  widget.onLocaleChanged(Locale(value));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Badge(
                    isLabelVisible: _filter.isActive,
                    child: const Icon(Icons.filter_alt_outlined),
                  ),
                  title: Text(
                    _filter.isActive
                        ? l10n.changeActiveFilter
                        : l10n.filterData,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'reminders',
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.reminders),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (widget.tonometerProfiles != null)
                PopupMenuItem(
                  value: 'tonometers',
                  child: ListTile(
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: Text(l10n.tonometers),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: Text(l10n.exportCsv),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'restore_csv',
                child: ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text(l10n.restoreCsv),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'privacy',
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacy),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(enabled: false, child: Text(l10n.language)),
              _LanguageMenuEntry(
                currentLanguageCode: widget.locale.languageCode,
                choices: [
                  (code: 'ru', flag: '🇷🇺', label: l10n.russian),
                  (code: 'en', flag: '🇺🇸', label: l10n.english),
                  (code: 'es', flag: '🇪🇸', label: l10n.spanish),
                ],
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Measurement>>(
        stream: widget.repository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StatusMessage(
              icon: Icons.error_outline,
              title: l10n.historyOpenFailed,
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allMeasurements = snapshot.data!;
          if (allMeasurements.isEmpty) {
            return _StatusMessage(
              icon: Icons.monitor_heart_outlined,
              title: l10n.noMeasurements,
              detail: l10n.noMeasurementsDetail,
            );
          }
          final now = DateTime.now();
          final filtered = allMeasurements
              .where((item) => _filter.includes(item.measuredAt.toLocal(), now))
              .toList(growable: false);
          if (filtered.isEmpty) {
            return _FilteredEmptyState(
              onReset: () => setState(() => _filter = const HistoryFilter()),
            );
          }
          final tableMeasurements = [...filtered]
            ..sort(
              (left, right) => _newestFirst
                  ? right.measuredAt.compareTo(left.measuredAt)
                  : left.measuredAt.compareTo(right.measuredAt),
            );
          final chartMeasurements = [
            ...filtered,
          ]..sort((left, right) => right.measuredAt.compareTo(left.measuredAt));
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _showChart
                ? MeasurementHistoryChart(
                    key: const ValueKey('chart'),
                    measurements: chartMeasurements,
                  )
                : _HistoryTable(
                    key: const ValueKey('table'),
                    measurements: tableMeasurements,
                    onEdit: (measurement) => _edit(context, measurement),
                    onDelete: (measurement) => _delete(context, measurement),
                    onConvertToSeries: (measurement) =>
                        _convertToSeries(context, measurement),
                    onAddMeasurementToSeries: (seriesId) =>
                        _addMeasurementToSeries(context, seriesId),
                    onDeleteSeries: (seriesId, count) =>
                        _deleteSeries(context, seriesId, count),
                    isDayExpanded: _isDayExpanded,
                    onToggleDay: _toggleDay,
                  ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Padding(
          // Keep app actions visibly separate from Android navigation controls,
          // even on devices that report a very small bottom safe area.
          padding: const EdgeInsets.only(bottom: 32),
          child: Row(
            children: [
              FloatingActionButton(
                heroTag: 'start_measurement_series',
                tooltip: l10n.startSeries,
                shape: const CircleBorder(),
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                disabledElevation: 0,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer,
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onTertiaryContainer,
                onPressed: () => _openSeries(context),
                child: const Icon(Icons.playlist_add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openCamera(context),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.photograph),
                ),
              ),
              const SizedBox(width: 12),
              // FloatingActionButton(
              //   heroTag: 'manual_measurement',
              //   tooltip: 'Ввести измерение вручную',
              //   shape: const CircleBorder(),
              //   elevation: 0,
              //   focusElevation: 0,
              //   hoverElevation: 0,
              //   highlightElevation: 0,
              //   disabledElevation: 0,
              //   backgroundColor: Theme.of(context)
              //       .colorScheme
              //       .secondaryContainer,
              //   foregroundColor: Theme.of(context)
              //       .colorScheme
              //       .onSecondaryContainer,
              //   onPressed: () => _openManual(context),
              //   child: const Icon(Icons.back_hand_outlined),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({
    required this.measurements,
    required this.onEdit,
    required this.onDelete,
    required this.onConvertToSeries,
    required this.onAddMeasurementToSeries,
    required this.onDeleteSeries,
    required this.isDayExpanded,
    required this.onToggleDay,
    super.key,
  });

  final List<Measurement> measurements;
  final ValueChanged<Measurement> onEdit;
  final ValueChanged<Measurement> onDelete;
  final ValueChanged<Measurement> onConvertToSeries;
  final ValueChanged<int> onAddMeasurementToSeries;
  final void Function(int, int) onDeleteSeries;
  final bool Function(DateTime) isDayExpanded;
  final ValueChanged<DateTime> onToggleDay;

  @override
  Widget build(BuildContext context) {
    final dayGroups = _groupByDay(measurements);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: dayGroups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _MeasurementDayCard(
        group: dayGroups[index],
        expanded: isDayExpanded(dayGroups[index].date),
        onToggle: () => onToggleDay(dayGroups[index].date),
        onEdit: onEdit,
        onDelete: onDelete,
        onConvertToSeries: onConvertToSeries,
        onAddMeasurementToSeries: onAddMeasurementToSeries,
        onDeleteSeries: onDeleteSeries,
      ),
    );
  }
}

class _MeasurementDayCard extends StatelessWidget {
  const _MeasurementDayCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onConvertToSeries,
    required this.onAddMeasurementToSeries,
    required this.onDeleteSeries,
    required this.expanded,
    required this.onToggle,
  });
  final _DayGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Measurement> onEdit;
  final ValueChanged<Measurement> onDelete;
  final ValueChanged<Measurement> onConvertToSeries;
  final ValueChanged<int> onAddMeasurementToSeries;
  final void Function(int, int) onDeleteSeries;

  @override
  Widget build(BuildContext context) {
    final largeLayout = MediaQuery.textScalerOf(context).scale(16) >= 22;
    final l10n = context.l10n;
    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(group.date);
    final systolic = group.average((measurement) => measurement.systolic);
    final diastolic = group.average((measurement) => measurement.diastolic);
    final pulse = group.average((measurement) => measurement.pulse);
    return Card(
      key: ValueKey('day_${_dayKey(group.date)}'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 8, 8, expanded ? 8 : 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label:
                  '$dateLabel. ${l10n.measurementCount(group.measurements.length)}. '
                  '${l10n.average}: SYS $systolic, DIA $diastolic, '
                  '${l10n.pulse} $pulse.',
              child: InkWell(
                key: ValueKey('day_toggle_${_dayKey(group.date)}'),
                onTap: onToggle,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 6),
                  child: expanded
                      ? _ExpandedDayHeading(
                          dateLabel: dateLabel,
                          count: l10n.measurementCount(
                            group.measurements.length,
                          ),
                        )
                      : _CollapsedDaySummary(
                          dateLabel: dateLabel,
                          systolic: systolic,
                          diastolic: diastolic,
                          pulse: pulse,
                          pulseLabel: l10n.pulse,
                        ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: !expanded
                  ? const SizedBox.shrink()
                  : Column(
                      key: ValueKey('day_contents_${_dayKey(group.date)}'),
                      children: [
                        if (!largeLayout) const _TableHeader(),
                        _DayMeasurementRows(
                          measurements: group.measurements,
                          largeLayout: largeLayout,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onConvertToSeries: onConvertToSeries,
                          onAddMeasurementToSeries: onAddMeasurementToSeries,
                          onDeleteSeries: onDeleteSeries,
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

class _ExpandedDayHeading extends StatelessWidget {
  const _ExpandedDayHeading({required this.dateLabel, required this.count});

  final String dateLabel;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.keyboard_arrow_up, size: 28),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(count, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _CollapsedDaySummary extends StatelessWidget {
  const _CollapsedDaySummary({
    required this.dateLabel,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.pulseLabel,
  });

  final String dateLabel;
  final int systolic;
  final int diastolic;
  final int pulse;
  final String pulseLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.keyboard_arrow_down, size: 28),
        const SizedBox(width: 4),
        Expanded(
          flex: 18,
          child: Text(
            dateLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          flex: 7,
          child: _CollapsedAverageValue(label: 'SYS', value: systolic),
        ),
        Expanded(
          flex: 7,
          child: _CollapsedAverageValue(label: 'DIA', value: diastolic),
        ),
        Expanded(
          flex: 7,
          child: _CollapsedAverageValue(label: pulseLabel, value: pulse),
        ),
      ],
    );
  }
}

class _CollapsedAverageValue extends StatelessWidget {
  const _CollapsedAverageValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DayMeasurementRows extends StatelessWidget {
  const _DayMeasurementRows({
    required this.measurements,
    required this.largeLayout,
    required this.onEdit,
    required this.onDelete,
    required this.onConvertToSeries,
    required this.onAddMeasurementToSeries,
    required this.onDeleteSeries,
  });

  final List<Measurement> measurements;
  final bool largeLayout;
  final ValueChanged<Measurement> onEdit;
  final ValueChanged<Measurement> onDelete;
  final ValueChanged<Measurement> onConvertToSeries;
  final ValueChanged<int> onAddMeasurementToSeries;
  final void Function(int, int) onDeleteSeries;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final shownSeries = <int>{};
    for (final measurement in measurements) {
      final seriesId = measurement.seriesId;
      if (children.isNotEmpty) children.add(const Divider(height: 1));
      if (seriesId == null) {
        children.add(
          _MeasurementTableRow(
            measurement: measurement,
            largeLayout: largeLayout,
            onEdit: () => onEdit(measurement),
            onDelete: () => onDelete(measurement),
            onConvertToSeries: () => onConvertToSeries(measurement),
          ),
        );
        continue;
      }
      if (!shownSeries.add(seriesId)) {
        children.removeLast();
        continue;
      }
      final series =
          measurements.where((item) => item.seriesId == seriesId).toList()
            ..sort(
              (a, b) =>
                  (a.sequenceNumber ?? 0).compareTo(b.sequenceNumber ?? 0),
            );
      children.add(
        _SeriesBlock(
          key: ValueKey('series_$seriesId'),
          measurements: series,
          largeLayout: largeLayout,
          onEdit: onEdit,
          onDelete: onDelete,
          onAddMeasurement: () => onAddMeasurementToSeries(seriesId),
          onDeleteSeries: onDeleteSeries,
        ),
      );
    }
    return Column(children: children);
  }
}

class _SeriesBlock extends StatefulWidget {
  const _SeriesBlock({
    super.key,
    required this.measurements,
    required this.largeLayout,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMeasurement,
    required this.onDeleteSeries,
  });

  final List<Measurement> measurements;
  final bool largeLayout;
  final ValueChanged<Measurement> onEdit;
  final ValueChanged<Measurement> onDelete;
  final VoidCallback onAddMeasurement;
  final void Function(int, int) onDeleteSeries;

  @override
  State<_SeriesBlock> createState() => _SeriesBlockState();
}

class _SeriesBlockState extends State<_SeriesBlock> {
  bool _expanded = false;

  int _average(int Function(Measurement) value) =>
      (widget.measurements.fold<int>(0, (sum, item) => sum + value(item)) /
              widget.measurements.length)
          .round();

  void _toggle() => setState(() => _expanded = !_expanded);

  String get _lastMeasurementTime {
    final last = widget.measurements.reduce(
      (current, next) =>
          current.measuredAt.isAfter(next.measuredAt) ? current : next,
    );
    final date = last.measuredAt.toLocal();
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _seriesMenu() {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.seriesActions,
      onSelected: (value) {
        if (value == 'add') {
          widget.onAddMeasurement();
          return;
        }
        widget.onDeleteSeries(
          widget.measurements.first.seriesId!,
          widget.measurements.length,
        );
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'add',
          enabled: widget.measurements.length < 3,
          child: ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(l10n.addMeasurement),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteSeries),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    final l10n = context.l10n;
    final systolic = _average((m) => m.systolic);
    final diastolic = _average((m) => m.diastolic);
    final pulse = _average((m) => m.pulse);
    final valueStyle = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700);
    final label = l10n.seriesSemantics(
      _lastMeasurementTime,
      l10n.measurementCount(widget.measurements.length),
      systolic,
      diastolic,
      pulse,
      _expanded ? l10n.collapse : l10n.expand,
    );

    if (widget.largeLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _lastMeasurementTime,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const _ArmBadge(arm: 'S'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 20,
                        runSpacing: 6,
                        children: [
                          _CompactValue(label: 'SYS', value: systolic),
                          _CompactValue(label: 'DIA', value: diastolic),
                          _CompactValue(label: l10n.pulse, value: pulse),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _seriesMenu(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 12,
                      child: Text(
                        _lastMeasurementTime,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text('$systolic', style: valueStyle),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text('$diastolic', style: valueStyle),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text('$pulse', style: valueStyle),
                    ),
                    const _ArmBadge(arm: 'S'),
                  ],
                ),
              ),
            ),
          ),
        ),
        _seriesMenu(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.tertiary, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(6, 8, 2, 6),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _summary(context),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: !_expanded
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const Divider(height: 1),
                      for (
                        var index = 0;
                        index < widget.measurements.length;
                        index++
                      ) ...[
                        if (index > 0) const Divider(height: 1),
                        _MeasurementTableRow(
                          measurement: widget.measurements[index],
                          largeLayout: widget.largeLayout,
                          canDelete: false,
                          onEdit: () =>
                              widget.onEdit(widget.measurements[index]),
                          onDelete: () =>
                              widget.onDelete(widget.measurements[index]),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

enum _MeasurementAction { edit, convertToSeries, delete }

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 3),
      child: Row(
        children: [
          Expanded(flex: 12, child: Text(l10n.time, style: style)),
          Expanded(flex: 10, child: Text('SYS', style: style)),
          Expanded(flex: 10, child: Text('DIA', style: style)),
          Expanded(flex: 10, child: Text(l10n.pulse, style: style)),
          const SizedBox(width: 32),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MeasurementTableRow extends StatefulWidget {
  const _MeasurementTableRow({
    required this.measurement,
    required this.largeLayout,
    required this.onEdit,
    required this.onDelete,
    this.onConvertToSeries,
    this.canDelete = true,
  });

  final Measurement measurement;
  final bool largeLayout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onConvertToSeries;
  final bool canDelete;

  @override
  State<_MeasurementTableRow> createState() => _MeasurementTableRowState();
}

class _MeasurementTableRowState extends State<_MeasurementTableRow> {
  bool _commentVisible = false;

  @override
  void didUpdateWidget(covariant _MeasurementTableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measurement.id != widget.measurement.id) {
      _commentVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final measurement = widget.measurement;
    final comment = measurement.comment?.trim();
    final hasComment = comment != null && comment.isNotEmpty;
    final date = measurement.measuredAt.toLocal();
    final time =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final valueStyle = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700);
    final semantics = StringBuffer(
      l10n.measurementSemantics(
        time,
        measurement.systolic,
        measurement.diastolic,
        measurement.pulse,
        measurement.armSide == 'R' ? l10n.rightArm : l10n.leftArm,
      ),
    );
    if (hasComment) {
      semantics
        ..write(' ${l10n.hasComment} ')
        ..write(_commentVisible ? l10n.hideComment : l10n.showComment);
    }
    return Semantics(
      button: hasComment,
      label: semantics.toString(),
      child: InkWell(
        onTap: hasComment
            ? () => setState(() => _commentVisible = !_commentVisible)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.largeLayout)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        time,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _MeasurementMenu(
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onConvertToSeries: widget.onConvertToSeries,
                      canDelete: widget.canDelete,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      flex: 12,
                      child: Text(
                        time,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text('${measurement.systolic}', style: valueStyle),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        '${measurement.diastolic}',
                        style: valueStyle,
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text('${measurement.pulse}', style: valueStyle),
                    ),
                    _RowBadges(
                      arm: measurement.armSide,
                      hasComment: hasComment,
                    ),
                    _MeasurementMenu(
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onConvertToSeries: widget.onConvertToSeries,
                      canDelete: widget.canDelete,
                    ),
                  ],
                ),
              if (widget.largeLayout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 6,
                    children: [
                      _CompactValue(label: 'SYS', value: measurement.systolic),
                      _CompactValue(label: 'DIA', value: measurement.diastolic),
                      _CompactValue(
                        label: l10n.pulse,
                        value: measurement.pulse,
                      ),
                      _RowBadges(
                        arm: measurement.armSide,
                        hasComment: hasComment,
                      ),
                    ],
                  ),
                ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: _commentVisible && hasComment
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 48, 5),
                        child: Text(comment),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowBadges extends StatelessWidget {
  const _RowBadges({required this.arm, required this.hasComment});

  final String arm;
  final bool hasComment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArmBadge(arm: arm),
        if (hasComment) ...[
          const SizedBox(width: 3),
          const _ArmBadge(arm: 'i'),
        ],
      ],
    );
  }
}

class _ArmBadge extends StatelessWidget {
  const _ArmBadge({required this.arm});

  final String arm;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 0.75,
          ),
        ),
        child: Text(
          arm,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MeasurementMenu extends StatelessWidget {
  const _MeasurementMenu({
    required this.onEdit,
    required this.onDelete,
    this.onConvertToSeries,
    this.canDelete = true,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onConvertToSeries;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_MeasurementAction>(
      tooltip: l10n.measurementActions,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _MeasurementAction.edit:
            return onEdit();
          case _MeasurementAction.convertToSeries:
            return onConvertToSeries?.call();
          case _MeasurementAction.delete:
            return onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MeasurementAction.edit,
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.edit),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (onConvertToSeries != null)
          PopupMenuItem(
            value: _MeasurementAction.convertToSeries,
            child: ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l10n.convertToSeries),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (canDelete)
          PopupMenuItem(
            value: _MeasurementAction.delete,
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.delete),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

class _CompactValue extends StatelessWidget {
  const _CompactValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$label '),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

List<_DayGroup> _groupByDay(List<Measurement> measurements) {
  final groups = <_DayGroup>[];
  for (final measurement in measurements) {
    final local = measurement.measuredAt.toLocal();
    final date = DateTime(local.year, local.month, local.day);
    if (groups.isEmpty || groups.last.date != date) {
      groups.add(_DayGroup(date, [measurement]));
    } else {
      groups.last.measurements.add(measurement);
    }
  }
  return groups;
}

class _DayGroup {
  const _DayGroup(this.date, this.measurements);

  final DateTime date;
  final List<Measurement> measurements;

  int average(int Function(Measurement) value) =>
      (measurements.fold<int>(0, (sum, item) => sum + value(item)) /
              measurements.length)
          .round();
}

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _LanguageMenuEntry extends PopupMenuEntry<String> {
  const _LanguageMenuEntry({
    required this.currentLanguageCode,
    required this.choices,
  });

  final String currentLanguageCode;
  final List<({String code, String flag, String label})> choices;

  @override
  double get height => 64;

  @override
  bool represents(String? value) => choices.any((item) => item.code == value);

  @override
  State<_LanguageMenuEntry> createState() => _LanguageMenuEntryState();
}

class _LanguageMenuEntryState extends State<_LanguageMenuEntry> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final choice in widget.choices)
            Tooltip(
              message: choice.label,
              child: Semantics(
                button: true,
                selected: widget.currentLanguageCode == choice.code,
                label: choice.label,
                child: ExcludeSemantics(
                  child: InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () => Navigator.of(context).pop(choice.code),
                    child: Container(
                      width: 56,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.currentLanguageCode == choice.code
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        choice.flag,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.noMeasurementsForFilter,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: Text(l10n.resetFilter),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
