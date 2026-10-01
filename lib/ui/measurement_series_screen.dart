import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement_draft.dart';
import '../l10n/l10n.dart';
import '../services/seven_segment_recognizer.dart';
import 'camera_screen.dart';
import 'measurement_form_screen.dart';

class MeasurementSeriesScreen extends StatefulWidget {
  const MeasurementSeriesScreen({
    required this.repository,
    required this.recognizer,
    this.initialMeasurements = const [],
    this.existingSeriesId,
    this.initialComment,
    super.key,
  });

  final MeasurementRepository repository;
  final SevenSegmentRecognizer recognizer;
  final List<Measurement> initialMeasurements;
  final int? existingSeriesId;
  final String? initialComment;

  @override
  State<MeasurementSeriesScreen> createState() =>
      _MeasurementSeriesScreenState();
}

class _MeasurementSeriesScreenState extends State<MeasurementSeriesScreen> {
  late final TextEditingController _comment;
  final _drafts = <MeasurementDraft>[];
  var _saving = false;

  int get _measurementCount =>
      widget.initialMeasurements.length + _drafts.length;

  List<MeasurementDraft> get _allDrafts => [
    ...widget.initialMeasurements.map(_draftFromMeasurement),
    ..._drafts,
  ];

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController(text: widget.initialComment);
  }

  Future<void> _photograph() async {
    if (_measurementCount >= 3) return;
    final draft = await Navigator.of(context).push<MeasurementDraft>(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          repository: widget.repository,
          recognizer: widget.recognizer,
          returnDraft: true,
        ),
      ),
    );
    if (draft != null && mounted) setState(() => _drafts.add(draft));
  }

  Future<void> _manual() async {
    if (_measurementCount >= 3) return;
    final draft = await Navigator.of(context).push<MeasurementDraft>(
      MaterialPageRoute(
        builder: (_) => MeasurementFormScreen(
          repository: widget.repository,
          returnDraft: true,
        ),
      ),
    );
    if (draft != null && mounted) setState(() => _drafts.add(draft));
  }

  Future<void> _edit(int index) async {
    final draft = await Navigator.of(context).push<MeasurementDraft>(
      MaterialPageRoute(
        builder: (_) => MeasurementFormScreen(
          repository: widget.repository,
          initialDraft: _drafts[index],
          returnDraft: true,
        ),
      ),
    );
    if (draft != null && mounted) setState(() => _drafts[index] = draft);
  }

  Future<void> _finish() async {
    if (_measurementCount < 2 || _saving) return;
    if (widget.initialMeasurements.isNotEmpty && _drafts.isEmpty) return;
    setState(() => _saving = true);
    try {
      final comment = _comment.text.trim();
      final normalizedComment = comment.isEmpty ? null : comment;
      if (widget.existingSeriesId != null) {
        await widget.repository.appendToSeries(
          widget.existingSeriesId!,
          _drafts,
          comment: normalizedComment,
        );
      } else if (widget.initialMeasurements.isNotEmpty) {
        await widget.repository.createSeriesFromMeasurement(
          widget.initialMeasurements.single.id,
          _drafts,
          comment: normalizedComment,
        );
      } else {
        await widget.repository.addSeries(_drafts, comment: normalizedComment);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.seriesSaveFailed(error.toString())),
        ),
      );
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final complete = _measurementCount >= 3;
    final canFinish =
        _measurementCount >= 2 &&
        (widget.initialMeasurements.isEmpty || _drafts.isNotEmpty);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.measurementSeries)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Text(
              complete
                  ? l10n.seriesReady
                  : l10n.measurementOfThree(_measurementCount + 1),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _measurementCount == 0
                  ? l10n.makeFirstMeasurement
                  : complete
                  ? l10n.reviewAndSaveSeries
                  : l10n.nextOrFinishSeries,
            ),
            const SizedBox(height: 16),
            for (
              var index = 0;
              index < widget.initialMeasurements.length;
              index++
            ) ...[
              _DraftCard(
                number: index + 1,
                draft: _draftFromMeasurement(widget.initialMeasurements[index]),
              ),
              const SizedBox(height: 10),
            ],
            for (var index = 0; index < _drafts.length; index++) ...[
              _DraftCard(
                number: widget.initialMeasurements.length + index + 1,
                draft: _drafts[index],
                onEdit: () => _edit(index),
                onDelete: () => setState(() => _drafts.removeAt(index)),
              ),
              const SizedBox(height: 10),
            ],
            if (_measurementCount > 0) ...[
              _AverageCard(drafts: _allDrafts),
              const SizedBox(height: 16),
              TextField(
                controller: _comment,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.seriesComment,
                  hintText: l10n.optional,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!complete)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _photograph,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          _drafts.isEmpty && widget.initialMeasurements.isEmpty
                              ? l10n.photograph
                              : l10n.nextMeasurement,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      heroTag: 'series_manual_measurement',
                      tooltip: l10n.manualEntry,
                      shape: const CircleBorder(),
                      elevation: 0,
                      focusElevation: 0,
                      hoverElevation: 0,
                      highlightElevation: 0,
                      disabledElevation: 0,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                      onPressed: _saving ? null : _manual,
                      child: const Icon(Icons.back_hand_outlined),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _saving || !canFinish ? null : _finish,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? l10n.saving : l10n.finishSeries),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.number,
    required this.draft,
    this.onEdit,
    this.onDelete,
  });

  final int number;
  final MeasurementDraft draft;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = TimeOfDay.fromDateTime(draft.measuredAt).format(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        title: Text(l10n.measurementNumberTime(number, time)),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              '${draft.systolic}   ${draft.diastolic}   ${draft.pulse}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: Text(
                draft.arm.code,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        trailing: onEdit == null || onDelete == null
            ? null
            : PopupMenuButton<String>(
                tooltip: l10n.measurementActions,
                onSelected: (value) =>
                    value == 'edit' ? onEdit!() : onDelete!(),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
      ),
    );
  }
}

MeasurementDraft _draftFromMeasurement(Measurement measurement) {
  return MeasurementDraft(
    systolic: measurement.systolic,
    diastolic: measurement.diastolic,
    pulse: measurement.pulse,
    measuredAt: measurement.measuredAt,
    arm: MeasurementArm.fromCode(measurement.armSide),
    comment: measurement.comment,
  );
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.drafts});

  final List<MeasurementDraft> drafts;

  int _average(int Function(MeasurementDraft) value) =>
      (drafts.fold<int>(0, (sum, item) => sum + value(item)) / drafts.length)
          .round();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.average,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${_average((d) => d.systolic)}   '
              '${_average((d) => d.diastolic)}   '
              '${_average((d) => d.pulse)}',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
