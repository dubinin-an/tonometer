import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/measurement_repository.dart';
import '../domain/measurement_draft.dart';
import '../l10n/l10n.dart';
import '../services/seven_segment_recognizer.dart';
import 'measurement_form_screen.dart';

class RecognitionPreviewScreen extends StatefulWidget {
  const RecognitionPreviewScreen({
    required this.repository,
    required this.recognizer,
    required this.rectifiedLcd,
    this.returnDraft = false,
    super.key,
  });

  final MeasurementRepository repository;
  final SevenSegmentRecognizer recognizer;
  final Uint8List rectifiedLcd;
  final bool returnDraft;

  @override
  State<RecognitionPreviewScreen> createState() =>
      _RecognitionPreviewScreenState();
}

class _RecognitionPreviewScreenState extends State<RecognitionPreviewScreen> {
  var _busy = false;
  var _showBlackWhite = true;
  late final Future<Uint8List> _blackWhitePreview;
  late final Future<RecognitionLayout> _layout;

  @override
  void initState() {
    super.initState();
    _blackWhitePreview = widget.recognizer.buildBlackWhitePreview(
      widget.rectifiedLcd,
    );
    _layout = widget.recognizer.loadLayout();
  }

  Future<void> _recognize() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.recognizer.recognizeRectified(
        widget.rectifiedLcd,
      );
      if (!mounted) return;
      if (widget.returnDraft) {
        final draft = await Navigator.of(context).push<MeasurementDraft>(
          MaterialPageRoute(
            builder: (_) => MeasurementFormScreen(
              repository: widget.repository,
              recognition: result,
              returnDraft: true,
            ),
          ),
        );
        if (!mounted) return;
        if (draft != null) {
          Navigator.of(context).pop(draft);
        } else {
          setState(() => _busy = false);
        }
        return;
      }
      await Navigator.of(context).pushReplacement<MeasurementDraft, void>(
        MaterialPageRoute(
          builder: (_) => MeasurementFormScreen(
            repository: widget.repository,
            recognition: result,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.recognitionFailed(error.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkRegions)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(l10n.regionsInstruction, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.contrast),
                    label: Text(l10n.blackWhiteMask),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(l10n.photo),
                  ),
                ],
                selected: {_showBlackWhite},
                onSelectionChanged: (selection) {
                  setState(() => _showBlackWhite = selection.first);
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: FutureBuilder<RecognitionLayout>(
                    future: _layout,
                    builder: (context, layoutSnapshot) {
                      final layout = layoutSnapshot.data;
                      return AspectRatio(
                        aspectRatio: layout == null
                            ? 640 / 960
                            : layout.width / layout.height,
                        child: Semantics(
                          image: true,
                          label: _showBlackWhite
                              ? l10n.blackWhitePreviewSemantics
                              : l10n.photoPreviewSemantics,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_showBlackWhite)
                                FutureBuilder<Uint8List>(
                                  future: _blackWhitePreview,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.fill,
                                        gaplessPlayback: true,
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Image.memory(
                                        widget.rectifiedLcd,
                                        fit: BoxFit.fill,
                                      );
                                    }
                                    return const ColoredBox(
                                      color: Colors.white,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                )
                              else
                                Image.memory(
                                  widget.rectifiedLcd,
                                  fit: BoxFit.fill,
                                ),
                              if (layout != null)
                                CustomPaint(
                                  painter: _RecognitionRegionsPainter(layout),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _busy ? null : _recognize,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner_outlined),
                    label: Text(_busy ? l10n.recognizing : l10n.recognize),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retake),
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

class _RecognitionRegionsPainter extends CustomPainter {
  const _RecognitionRegionsPainter(this.layout);

  final RecognitionLayout layout;

  List<_RegionGroup> get _groups => [
    _RegionGroup(
      'SYS',
      const Color(0xFFFFD54F),
      layout.regions['systolic'] ?? const [],
    ),
    _RegionGroup(
      'DIA',
      const Color(0xFF69F0AE),
      layout.regions['diastolic'] ?? const [],
    ),
    _RegionGroup(
      'Pulse',
      const Color(0xFF55D6FF),
      layout.regions['pulse'] ?? const [],
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final group in _groups) {
      if (group.regions.isEmpty) continue;
      final paint = Paint()
        ..color = group.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (final region in group.regions) {
        canvas.drawRect(
          Rect.fromLTWH(
            region.left * size.width,
            region.top * size.height,
            region.width * size.width,
            region.height * size.height,
          ),
          paint,
        );
      }
      final first = group.regions.first;
      final label = TextPainter(
        text: TextSpan(
          text: group.label,
          style: TextStyle(
            color: Colors.black,
            backgroundColor: group.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(first.left * size.width, first.top * size.height - label.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RecognitionRegionsPainter oldDelegate) =>
      oldDelegate.layout != layout;
}

class _RegionGroup {
  const _RegionGroup(this.label, this.color, this.regions);

  final String label;
  final Color color;
  final List<Rect> regions;
}
