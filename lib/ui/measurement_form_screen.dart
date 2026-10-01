import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement_draft.dart';
import '../l10n/l10n.dart';
import '../services/seven_segment_recognizer.dart';

class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({
    required this.repository,
    this.recognition,
    this.measurement,
    this.initialDraft,
    this.returnDraft = false,
    super.key,
  });

  final MeasurementRepository repository;
  final RecognitionResult? recognition;
  final Measurement? measurement;
  final MeasurementDraft? initialDraft;
  final bool returnDraft;

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _systolic;
  late final TextEditingController _diastolic;
  late final TextEditingController _pulse;
  final _comment = TextEditingController();
  late DateTime _measuredAt;
  late MeasurementArm _arm;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final measurement = widget.measurement;
    _systolic = TextEditingController(
      text:
          measurement?.systolic.toString() ??
          widget.initialDraft?.systolic.toString() ??
          widget.recognition?.systolic?.toString() ??
          '',
    );
    _diastolic = TextEditingController(
      text:
          measurement?.diastolic.toString() ??
          widget.initialDraft?.diastolic.toString() ??
          widget.recognition?.diastolic?.toString() ??
          '',
    );
    _pulse = TextEditingController(
      text:
          measurement?.pulse.toString() ??
          widget.initialDraft?.pulse.toString() ??
          widget.recognition?.pulse?.toString() ??
          '',
    );
    _comment.text = measurement?.comment ?? widget.initialDraft?.comment ?? '';
    _measuredAt =
        (measurement?.measuredAt ??
                widget.initialDraft?.measuredAt ??
                DateTime.now())
            .toLocal();
    _arm = measurement != null
        ? MeasurementArm.fromCode(measurement.armSide)
        : widget.initialDraft?.arm ?? MeasurementArm.left;
  }

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _pulse.dispose();
    _comment.dispose();
    super.dispose();
  }

  String? _validate(String? value, int minimum, int maximum) {
    final l10n = context.l10n;
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      return l10n.integerRequired;
    }
    if (parsed < minimum || parsed > maximum) {
      return l10n.allowedRange(minimum, maximum);
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final comment = _comment.text.trim();
      final draft = MeasurementDraft(
        systolic: int.parse(_systolic.text),
        diastolic: int.parse(_diastolic.text),
        pulse: int.parse(_pulse.text),
        measuredAt: _measuredAt,
        arm: _arm,
        comment: comment.isEmpty ? null : comment,
      );
      if (widget.returnDraft) {
        if (mounted) Navigator.of(context).pop(draft);
        return;
      }
      final existing = widget.measurement;
      if (existing == null) {
        await widget.repository.add(draft);
      } else {
        await widget.repository.updateMeasurement(existing.id, draft);
      }
      if (mounted) {
        if (existing == null) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveFailed(error.toString()))),
      );
    }
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: context.l10n.measurementDate,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _measuredAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _measuredAt.hour,
        _measuredAt.minute,
      );
    });
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
      helpText: context.l10n.measurementTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _measuredAt = DateTime(
        _measuredAt.year,
        _measuredAt.month,
        _measuredAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.measurement != null
              ? l10n.editMeasurement
              : widget.recognition == null
              ? l10n.manualInput
              : l10n.checkValues,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (widget.recognition != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.recognition!.complete
                        ? l10n.recognizedComplete
                        : l10n.recognizedIncomplete,
                  ),
                ),
              _NumberField(
                controller: _systolic,
                label: 'SYS',
                unit: 'mmHg',
                validator: (value) => _validate(value, 40, 300),
              ),
              const SizedBox(height: 16),
              _NumberField(
                controller: _diastolic,
                label: 'DIA',
                unit: 'mmHg',
                validator: (value) => _validate(value, 20, 200),
              ),
              const SizedBox(height: 16),
              _NumberField(
                controller: _pulse,
                label: l10n.pulse,
                unit: '/min',
                validator: (value) => _validate(value, 25, 250),
              ),
              const SizedBox(height: 16),
              Text(l10n.arm, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<MeasurementArm>(
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment(
                    value: MeasurementArm.left,
                    label: const Text('L'),
                    tooltip: l10n.leftArm,
                  ),
                  ButtonSegment(
                    value: MeasurementArm.right,
                    label: const Text('R'),
                    tooltip: l10n.rightArm,
                  ),
                ],
                selected: {_arm},
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() => _arm = selection.first),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.measurementDateTime,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        MaterialLocalizations.of(context)
                            .formatCompactDate(_measuredAt),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _chooseTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        TimeOfDay.fromDateTime(_measuredAt).format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comment,
                minLines: 2,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.comment,
                  hintText: l10n.optional,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _saving
                  ? l10n.saving
                  : widget.measurement == null
                  ? l10n.saveMeasurement
                  : l10n.saveChanges,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final String unit;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      validator: validator,
      style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(labelText: label, suffixText: unit),
    );
  }
}
