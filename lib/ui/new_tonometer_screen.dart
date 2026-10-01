import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/measurement_repository.dart';
import '../data/tonometer_profile_repository.dart';
import '../domain/tonometer_profile.dart';
import '../l10n/l10n.dart';
import '../services/seven_segment_recognizer.dart';
import '../services/tonometer_profile_calibration.dart';
import 'camera_screen.dart';

class NewTonometerScreen extends StatefulWidget {
  const NewTonometerScreen({
    required this.repository,
    required this.measurementRepository,
    required this.recognizer,
    this.existingProfileId,
    super.key,
  });

  final TonometerProfileRepository repository;
  final MeasurementRepository measurementRepository;
  final SevenSegmentRecognizer recognizer;
  final String? existingProfileId;

  @override
  State<NewTonometerScreen> createState() => _NewTonometerScreenState();
}

class _NewTonometerScreenState extends State<NewTonometerScreen> {
  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _pulse = TextEditingController();
  TonometerCalibrationDraft? _calibration;
  List<(double, double)> _lcdCorners = const [];
  List<NormalizedRegion> _regions = const [];
  Uint8List? _blackWhiteLcd;
  final _tests = <RecognitionResult>[];
  var _busy = false;
  var _saved = false;
  var _regionsConfirmed = false;
  String? _profileId;

  bool get _editing => widget.existingProfileId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _busy = true);
    try {
      final id = widget.existingProfileId!;
      final bundle = await widget.repository.load(id);
      final json = jsonDecode(bundle.json) as Map<String, dynamic>;
      final device = json['device'] as Map<String, dynamic>? ?? const {};
      final reference = json['calibrationReference'] as Map<String, dynamic>;
      final quadrilateral =
          reference['innerLcdQuadrilateral'] as Map<String, dynamic>;
      (double, double) point(String key) {
        final value = quadrilateral[key] as Map<String, dynamic>;
        return ((value['x'] as num).toDouble(), (value['y'] as num).toDouble());
      }

      final corners = [
        point('topLeft'),
        point('topRight'),
        point('bottomRight'),
        point('bottomLeft'),
      ];
      final calibration = await prepareTonometerCalibrationFromCorners(
        bundle.referenceBytes,
        corners,
      );
      final blackWhite = await widget.recognizer.buildBlackWhitePreview(
        calibration.rectifiedLcd,
      );
      final regions = <NormalizedRegion>[];
      for (final rawField in json['fields'] as List<dynamic>) {
        final field = rawField as Map<String, dynamic>;
        final rect = field['rect'] as Map<String, dynamic>;
        regions.add(
          NormalizedRegion(
            x: (rect['x'] as num).toDouble(),
            y: (rect['y'] as num).toDouble(),
            width: (rect['width'] as num).toDouble(),
            height: (rect['height'] as num).toDouble(),
          ),
        );
      }
      final expected = reference['expectedValues'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _profileId = id;
        _name.text = json['name'] as String;
        _manufacturer.text = device['manufacturer'] as String? ?? '';
        _model.text = device['model'] as String? ?? '';
        _sys.text = '${expected['systolic']}';
        _dia.text = '${expected['diastolic']}';
        _pulse.text = '${expected['pulse']}';
        _calibration = calibration;
        _lcdCorners = corners;
        _regions = regions;
        _blackWhiteLcd = blackWhite;
        _regionsConfirmed = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileOpenFailed(error.toString())),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _manufacturer,
      _model,
      _sys,
      _dia,
      _pulse,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Uint8List?> _takePhoto() => Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => const CameraScreen.calibration()),
  );

  Future<void> _captureReference() async {
    if (_name.text.trim().isEmpty || _busy) {
      if (_name.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.enterTonometerName)),
        );
      }
      return;
    }
    final photo = await _takePhoto();
    if (photo == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final calibration = await prepareTonometerCalibration(photo);
      if (!mounted) return;
      setState(() {
        _calibration = calibration;
        _lcdCorners = calibration.lcdCorners;
        _regions = const [];
        _blackWhiteLcd = null;
        _regionsConfirmed = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.lcdDetectionFailed(error.toString())),
        ),
      );
    }
  }

  Future<void> _confirmLcd() async {
    final calibration = _calibration;
    if (calibration == null || _lcdCorners.length != 4 || _busy) return;
    setState(() => _busy = true);
    try {
      final rectified = await prepareTonometerCalibrationFromCorners(
        calibration.sourcePhoto,
        _lcdCorners,
      );
      final blackWhite = await widget.recognizer.buildBlackWhitePreview(
        rectified.rectifiedLcd,
      );
      if (!mounted) return;
      setState(() {
        _calibration = rectified;
        _lcdCorners = rectified.lcdCorners;
        _regions = rectified.suggestedRegions;
        _blackWhiteLcd = blackWhite;
        _regionsConfirmed = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.lcdRectificationFailed(error.toString())),
        ),
      );
    }
  }

  Future<void> _save() async {
    final calibration = _calibration;
    final values = [
      int.tryParse(_sys.text),
      int.tryParse(_dia.text),
      int.tryParse(_pulse.text),
    ];
    if (calibration == null || values.any((value) => value == null) || _busy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterReferenceValues)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final slug = _name.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final id =
          _profileId ??
          '${slug.isEmpty ? 'tonometer' : slug}-${DateTime.now().millisecondsSinceEpoch}';
      final profile = buildTonometerProfile(
        id: id,
        name: _name.text.trim(),
        manufacturer: _manufacturer.text,
        model: _model.text,
        calibration: calibration,
        regions: _regions,
        systolic: values[0]!,
        diastolic: values[1]!,
        pulse: values[2]!,
      );
      await widget.repository.saveCustom(
        profile: profile,
        referenceBytes: calibration.sourcePhoto,
      );
      if (mounted) {
        setState(() {
          _profileId = id;
          _busy = false;
          _saved = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileSaveFailed(error.toString())),
        ),
      );
    }
  }

  Future<void> _testPhoto() async {
    if (_busy) return;
    final photo = await _takePhoto();
    if (photo == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await widget.recognizer.recognize(photo);
      if (!mounted) return;
      setState(() {
        _tests.add(result);
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.testRecognitionFailed(error.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? context.l10n.editTonometer : context.l10n.addTonometer,
        ),
      ),
      body: SafeArea(
        child: _busy && _calibration == null
            ? const Center(child: CircularProgressIndicator())
            : _saved
            ? _buildTesting()
            : _buildCalibration(),
      ),
    );
  }

  Widget _buildCalibration() {
    final calibration = _calibration;
    final l10n = context.l10n;
    if (calibration != null && _blackWhiteLcd == null) {
      return _buildLcdCornerEditorStep(calibration);
    }
    if (calibration != null && _blackWhiteLcd != null && !_regionsConfirmed) {
      return _buildRegionEditorStep(calibration);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(_editing ? l10n.editTonometerIntro : l10n.newTonometerIntro),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.tonometerName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manufacturer,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.manufacturerOptional),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _model,
          decoration: InputDecoration(labelText: l10n.modelOptional),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _captureReference,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_camera_outlined),
          label: Text(
            calibration == null
                ? l10n.takeReferencePhoto
                : l10n.retakeReferencePhoto,
          ),
        ),
        if (calibration != null &&
            _blackWhiteLcd != null &&
            _regionsConfirmed) ...[
          const SizedBox(height: 20),
          Text(
            l10n.markReadingsOnPreparedLcd,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => setState(() => _regionsConfirmed = false),
            icon: const Icon(Icons.tune),
            label: Text(l10n.editReadingRegions),
          ),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _blackWhiteLcd = null;
                    _regions = const [];
                    _regionsConfirmed = false;
                  }),
            icon: const Icon(Icons.crop_free),
            label: Text(l10n.changeLcdCorners),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.referenceReadings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(controller: _sys, label: 'SYS'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(controller: _dia, label: 'DIA'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(controller: _pulse, label: l10n.pulse),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.saveAndTestProfile),
          ),
        ],
      ],
    );
  }

  Widget _buildLcdCornerEditorStep(TonometerCalibrationDraft calibration) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            l10n.checkDetectedLcd,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(l10n.adjustLcdCorners),
          const SizedBox(height: 8),
          Expanded(
            child: _LcdCornerEditor(
              image: calibration.sourcePhoto,
              imageWidth: calibration.sourceWidth,
              imageHeight: calibration.sourceHeight,
              corners: _lcdCorners,
              onChanged: (corners) => setState(() => _lcdCorners = corners),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirmLcd,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.crop_rotate),
              label: Text(l10n.cropAndAlignLcd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionEditorStep(TonometerCalibrationDraft calibration) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            l10n.markReadingsOnPreparedLcd,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(l10n.adjustMeasurementRegions),
          const SizedBox(height: 8),
          Expanded(
            child: _RegionEditor(
              image: _blackWhiteLcd!,
              aspectRatio:
                  calibration.canonicalWidth / calibration.canonicalHeight,
              regions: _regions,
              onChanged: (regions) => setState(() => _regions = regions),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _regionsConfirmed = true),
              icon: const Icon(Icons.check),
              label: Text(l10n.continueToReferenceValues),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTesting() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Icon(
          Icons.fact_check_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.testNewTonometer,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(l10n.testPhotoRequest, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        for (var index = 0; index < _tests.length; index++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(
                '${_tests[index].systolic ?? '—'} / ${_tests[index].diastolic ?? '—'}   ${_tests[index].pulse ?? '—'}',
              ),
              subtitle: Text(
                _tests[index].complete
                    ? l10n.recognitionComplete
                    : l10n.recognitionNeedsAdjustment,
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _testPhoto,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(l10n.takeTestPhoto(_tests.length + 1)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _saved = false;
                  _tests.clear();
                }),
          icon: const Icon(Icons.tune),
          label: Text(l10n.adjustProfile),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _tests.length < 3
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(l10n.finishSetup),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _LcdCornerEditor extends StatefulWidget {
  const _LcdCornerEditor({
    required this.image,
    required this.imageWidth,
    required this.imageHeight,
    required this.corners,
    required this.onChanged,
  });

  final Uint8List image;
  final int imageWidth;
  final int imageHeight;
  final List<(double, double)> corners;
  final ValueChanged<List<(double, double)>> onChanged;

  @override
  State<_LcdCornerEditor> createState() => _LcdCornerEditorState();
}

class _LcdCornerEditorState extends State<_LcdCornerEditor> {
  int _activeCorner = 0;

  Offset _displayPoint((double, double) point, Size size) => Offset(
    point.$1 / widget.imageWidth * size.width,
    point.$2 / widget.imageHeight * size.height,
  );

  void _start(DragStartDetails details, Size size) {
    var closest = 0;
    var distance = double.infinity;
    for (var index = 0; index < widget.corners.length; index++) {
      final current =
          (_displayPoint(widget.corners[index], size) - details.localPosition)
              .distance;
      if (current < distance) {
        closest = index;
        distance = current;
      }
    }
    setState(() => _activeCorner = closest);
  }

  void _update(DragUpdateDetails details, Size size) {
    final index = _activeCorner;
    final current = widget.corners[index];
    var x = current.$1 + details.delta.dx / size.width * widget.imageWidth;
    var y = current.$2 + details.delta.dy / size.height * widget.imageHeight;
    final right = index == 1 || index == 2;
    final bottom = index >= 2;
    x = x.clamp(
      right ? widget.imageWidth * 0.30 : 0,
      right ? widget.imageWidth.toDouble() : widget.imageWidth * 0.70,
    );
    y = y.clamp(
      bottom ? widget.imageHeight * 0.30 : 0,
      bottom ? widget.imageHeight.toDouble() : widget.imageHeight * 0.70,
    );
    final corners = [...widget.corners];
    corners[index] = (x.toDouble(), y.toDouble());
    widget.onChanged(corners);
  }

  void _nudge(int horizontal, int vertical) {
    final step = math.max(
      1.0,
      math.min(widget.imageWidth, widget.imageHeight) * 0.0025,
    );
    final index = _activeCorner;
    final current = widget.corners[index];
    final right = index == 1 || index == 2;
    final bottom = index >= 2;
    final x = (current.$1 + horizontal * step).clamp(
      right ? widget.imageWidth * 0.30 : 0,
      right ? widget.imageWidth.toDouble() : widget.imageWidth * 0.70,
    );
    final y = (current.$2 + vertical * step).clamp(
      bottom ? widget.imageHeight * 0.30 : 0,
      bottom ? widget.imageHeight.toDouble() : widget.imageHeight * 0.70,
    );
    final corners = [...widget.corners];
    corners[index] = (x.toDouble(), y.toDouble());
    widget.onChanged(corners);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final viewportHeight = constraints.maxHeight;
              final contentWidth = viewportWidth * 1.2;
              final contentHeight =
                  contentWidth * widget.imageHeight / widget.imageWidth;
              final imageSize = Size(contentWidth, contentHeight);
              final focus = _displayPoint(
                widget.corners[_activeCorner],
                imageSize,
              );
              final left = contentWidth <= viewportWidth
                  ? (viewportWidth - contentWidth) / 2
                  : (viewportWidth / 2 - focus.dx).clamp(
                      viewportWidth - contentWidth,
                      0.0,
                    );
              final top = contentHeight <= viewportHeight
                  ? (viewportHeight - contentHeight) / 2
                  : (viewportHeight / 2 - focus.dy).clamp(
                      viewportHeight - contentHeight,
                      0.0,
                    );
              return ClipRect(
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      left: left.toDouble(),
                      top: top.toDouble(),
                      width: contentWidth,
                      height: contentHeight,
                      child: GestureDetector(
                        onPanStart: (details) => _start(details, imageSize),
                        onPanUpdate: (details) => _update(details, imageSize),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(widget.image, fit: BoxFit.fill),
                            CustomPaint(
                              painter: _LcdCornersPainter(
                                points: [
                                  for (final point in widget.corners)
                                    _displayPoint(point, imageSize),
                                ],
                                active: _activeCorner,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.selectedCorner),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (var index = 0; index < 4; index++)
              ChoiceChip(
                selected: _activeCorner == index,
                onSelected: (_) => setState(() => _activeCorner = index),
                label: Text(const ['↖', '↗', '↘', '↙'][index]),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _DirectionalPad(onMove: _nudge),
      ],
    );
  }
}

class _LcdCornersPainter extends CustomPainter {
  const _LcdCornersPainter({required this.points, required this.active});

  final List<Offset> points;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;
    final screen = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(screen, Offset.zero);
    canvas.drawPath(shade, Paint()..color = Colors.black54);
    canvas.drawPath(
      screen,
      Paint()
        ..color = const Color(0xFF55D6FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(
        points[index],
        active == index ? 18 : 14,
        Paint()..color = const Color(0xFF55D6FF),
      );
      canvas.drawCircle(
        points[index],
        active == index ? 9 : 7,
        Paint()..color = Colors.black,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LcdCornersPainter oldDelegate) => true;
}

class _RegionEditor extends StatefulWidget {
  const _RegionEditor({
    required this.image,
    required this.aspectRatio,
    required this.regions,
    required this.onChanged,
  });

  final Uint8List image;
  final double aspectRatio;
  final List<NormalizedRegion> regions;
  final ValueChanged<List<NormalizedRegion>> onChanged;

  @override
  State<_RegionEditor> createState() => _RegionEditorState();
}

class _RegionEditorState extends State<_RegionEditor> {
  int _active = 0;
  bool _resize = false;

  void _start(DragStartDetails details, Size size) {
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    for (var index = widget.regions.length - 1; index >= 0; index--) {
      final region = widget.regions[index];
      final rect = Rect.fromLTWH(
        region.x,
        region.y,
        region.width,
        region.height,
      );
      if (!rect.inflate(0.025).contains(point)) continue;
      _active = index;
      _resize = (point - rect.bottomRight).distance < 0.10;
      setState(() {});
      return;
    }
  }

  void _update(DragUpdateDetails details, Size size) {
    final index = _active;
    final regions = [...widget.regions];
    final current = regions[index];
    final dx = details.delta.dx / size.width;
    final dy = details.delta.dy / size.height;
    if (_resize) {
      regions[index] = NormalizedRegion(
        x: current.x,
        y: current.y,
        width: (current.width + dx).clamp(0.18, 1 - current.x),
        height: (current.height + dy).clamp(0.12, 1 - current.y),
      );
    } else {
      regions[index] = NormalizedRegion(
        x: (current.x + dx).clamp(0.0, 1 - current.width),
        y: (current.y + dy).clamp(0.0, 1 - current.height),
        width: current.width,
        height: current.height,
      );
    }
    widget.onChanged(regions);
  }

  void _nudge(int horizontal, int vertical) {
    final regions = [...widget.regions];
    final current = regions[_active];
    final dx = horizontal * 0.004;
    final dy = vertical * 0.004;
    if (_resize) {
      regions[_active] = NormalizedRegion(
        x: current.x,
        y: current.y,
        width: (current.width + dx).clamp(0.18, 1 - current.x),
        height: (current.height + dy).clamp(0.12, 1 - current.y),
      );
    } else {
      final nextX = (current.x + dx).clamp(
        0.0,
        current.x + current.width - 0.18,
      );
      final nextY = (current.y + dy).clamp(
        0.0,
        current.y + current.height - 0.12,
      );
      regions[_active] = NormalizedRegion(
        x: nextX,
        y: nextY,
        width: current.width + current.x - nextX,
        height: current.height + current.y - nextY,
      );
    }
    widget.onChanged(regions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth;
              final contentHeight = contentWidth / widget.aspectRatio;
              final viewportHeight = constraints.maxHeight;
              final region = widget.regions[_active];
              final focusY = (region.y + region.height / 2) * contentHeight;
              final top = contentHeight <= viewportHeight
                  ? (viewportHeight - contentHeight) / 2
                  : (viewportHeight / 2 - focusY).clamp(
                      viewportHeight - contentHeight,
                      0.0,
                    );
              final imageSize = Size(contentWidth, contentHeight);
              return ClipRect(
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      left: 0,
                      top: top.toDouble(),
                      width: contentWidth,
                      height: contentHeight,
                      child: GestureDetector(
                        onPanStart: (details) => _start(details, imageSize),
                        onPanUpdate: (details) => _update(details, imageSize),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(widget.image, fit: BoxFit.fill),
                            CustomPaint(
                              painter: _EditableRegionsPainter(
                                widget.regions,
                                _active,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var index = 0; index < 3; index++)
              ChoiceChip(
                selected: _active == index,
                onSelected: (_) => setState(() => _active = index),
                label: Text(const ['SYS', 'DIA', 'Pulse'][index]),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.north_west),
              label: Text(l10n.topLeftCorner),
            ),
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.south_east),
              label: Text(l10n.bottomRightCorner),
            ),
          ],
          selected: {_resize},
          onSelectionChanged: (selection) {
            setState(() => _resize = selection.first);
          },
        ),
        const SizedBox(height: 6),
        _DirectionalPad(onMove: _nudge),
      ],
    );
  }
}

class _DirectionalPad extends StatelessWidget {
  const _DirectionalPad({required this.onMove});

  final void Function(int horizontal, int vertical) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget button(IconData icon, String label, int x, int y) {
      return _RepeatArrowButton(
        icon: icon,
        label: label,
        onPressed: () => onMove(x, y),
      );
    }

    return Semantics(
      label: l10n.preciseMovement,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.keyboard_arrow_up, l10n.moveUp, 0, -1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(Icons.keyboard_arrow_left, l10n.moveLeft, -1, 0),
              const SizedBox(width: 52, height: 48),
              button(Icons.keyboard_arrow_right, l10n.moveRight, 1, 0),
            ],
          ),
          button(Icons.keyboard_arrow_down, l10n.moveDown, 0, 1),
        ],
      ),
    );
  }
}

class _RepeatArrowButton extends StatefulWidget {
  const _RepeatArrowButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_RepeatArrowButton> createState() => _RepeatArrowButtonState();
}

class _RepeatArrowButtonState extends State<_RepeatArrowButton> {
  Timer? _holdDelay;
  Timer? _repeat;
  var _repeated = false;

  void _start(PointerDownEvent _) {
    _repeated = false;
    _holdDelay?.cancel();
    _repeat?.cancel();
    _holdDelay = Timer(const Duration(milliseconds: 350), () {
      _repeated = true;
      widget.onPressed();
      _repeat = Timer.periodic(
        const Duration(milliseconds: 70),
        (_) => widget.onPressed(),
      );
    });
  }

  void _stop(PointerEvent _) {
    _holdDelay?.cancel();
    _repeat?.cancel();
  }

  @override
  void dispose() {
    _holdDelay?.cancel();
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _start,
      onPointerUp: _stop,
      onPointerCancel: _stop,
      child: IconButton.outlined(
        tooltip: widget.label,
        onPressed: () {
          if (!_repeated) widget.onPressed();
        },
        icon: Icon(widget.icon),
        iconSize: 28,
      ),
    );
  }
}

class _EditableRegionsPainter extends CustomPainter {
  const _EditableRegionsPainter(this.regions, this.active);

  final List<NormalizedRegion> regions;
  final int? active;

  static const labels = ['SYS', 'DIA', 'Pulse'];
  static const colors = [
    Color(0xFFFFD54F),
    Color(0xFF69F0AE),
    Color(0xFF55D6FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < regions.length; index++) {
      final region = regions[index];
      final rect = Rect.fromLTWH(
        region.x * size.width,
        region.y * size.height,
        region.width * size.width,
        region.height * size.height,
      );
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = active == index ? 5 : 3;
      canvas.drawRect(rect, paint);
      canvas.drawCircle(
        rect.bottomRight,
        active == index ? 13 : 10,
        paint..style = PaintingStyle.fill,
      );
      final label = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(
            color: Colors.black,
            backgroundColor: colors[index],
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(rect.left, math.max(0, rect.top - label.height)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EditableRegionsPainter oldDelegate) => true;
}
