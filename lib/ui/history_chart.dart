import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../l10n/l10n.dart';

const _sysColor = Color(0xFF1565C0);
const _diaColor = Color(0xFF00866A);
const _pulseColor = Color(0xFFE46A19);

class MeasurementHistoryChart extends StatefulWidget {
  const MeasurementHistoryChart({required this.measurements, super.key});

  final List<Measurement> measurements;

  @override
  State<MeasurementHistoryChart> createState() =>
      _MeasurementHistoryChartState();
}

class _MeasurementHistoryChartState extends State<MeasurementHistoryChart> {
  final _scrollController = ScrollController();
  var _zoom = 1.0;
  var _focusedInitially = false;

  @override
  void initState() {
    super.initState();
    _focusLatestAfterLayout();
  }

  @override
  void didUpdateWidget(MeasurementHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measurements.length != widget.measurements.length) {
      _focusLatestAfterLayout();
    }
  }

  void _focusLatestAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _focusedInitially = true;
    });
  }

  void _changeZoom(double delta) {
    final next = (_zoom + delta).clamp(0.6, 3.0);
    if (next == _zoom) return;
    final wasAtEnd =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            24;
    final oldExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final oldOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    setState(() => _zoom = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = wasAtEnd
          ? position.maxScrollExtent
          : oldExtent == 0
          ? 0.0
          : oldOffset / oldExtent * position.maxScrollExtent;
      _scrollController.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final points = widget.measurements.reversed.toList(growable: false);
    final scale = _ChartScale.fromMeasurements(points);
    final averages = _Averages.fromLastSevenDays(points, DateTime.now());
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    final chartHeight = textScale > 20 ? 460.0 : 390.0;

    return ListView(
      key: const PageStorageKey('measurement-chart'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 120),
      children: [
        Row(
          children: [
            const Expanded(child: _Legend()),
            IconButton.outlined(
              tooltip: l10n.zoomOut,
              onPressed: _zoom <= 0.6 ? null : () => _changeZoom(-0.25),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: l10n.zoomIn,
              onPressed: _zoom >= 3 ? null : () => _changeZoom(0.25),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            label: averages == null
                ? l10n.chartNoMeasurements
                : l10n.chartSemantics(
                    l10n.measurementCount(points.length),
                    averages.usesLastSevenDays
                        ? l10n.lastSevenDays
                        : l10n.availableData,
                    averages.sys.round(),
                    averages.dia.round(),
                    averages.pulse.round(),
                  ),
            child: SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: textScale > 20 ? 92 : 72,
                    child: CustomPaint(
                      painter: _YAxisPainter(
                        scale: scale,
                        averages: averages,
                        colors: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final pointSpacing = 52.0 * _zoom;
                        final width = math.max(
                          constraints.maxWidth,
                          36 + math.max(0, points.length - 1) * pointSpacing,
                        );
                        if (!_focusedInitially) _focusLatestAfterLayout();
                        return Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: width,
                              child: CustomPaint(
                                painter: _LinesPainter(
                                  measurements: points,
                                  scale: scale,
                                  averages: averages,
                                  colors: Theme.of(context).colorScheme,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chartScrollHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        const _LegendItem(label: 'SYS', color: _sysColor),
        const _LegendItem(label: 'DIA', color: _diaColor),
        _LegendItem(label: context.l10n.pulse, color: _pulseColor),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LinesPainter extends CustomPainter {
  const _LinesPainter({
    required this.measurements,
    required this.scale,
    required this.averages,
    required this.colors,
  });

  final List<Measurement> measurements;
  final _ChartScale scale;
  final _Averages? averages;
  final ColorScheme colors;

  static const _top = 18.0;
  static const _bottom = 58.0;
  static const _side = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _side,
      _top,
      size.width - _side,
      size.height - _bottom,
    );
    final gridPaint = Paint()
      ..color = colors.outlineVariant.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var index = 0; index <= 5; index++) {
      final y = plot.top + plot.height * index / 5;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final averages = this.averages;
    if (averages != null) {
      _drawAverage(canvas, plot, averages.sys, _sysColor);
      _drawAverage(canvas, plot, averages.dia, _diaColor);
      _drawAverage(canvas, plot, averages.pulse, _pulseColor);
    }
    _drawSeries(canvas, plot, (m) => m.systolic, _sysColor);
    _drawSeries(canvas, plot, (m) => m.diastolic, _diaColor);
    _drawSeries(canvas, plot, (m) => m.pulse, _pulseColor);
    _drawDates(canvas, plot);
  }

  void _drawAverage(Canvas canvas, Rect plot, double value, Color color) {
    final y = scale.y(value, plot);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    for (var x = plot.left; x < plot.right; x += 10) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 5, plot.right), y),
        paint,
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect plot,
    int Function(Measurement) valueOf,
    Color color,
  ) {
    if (measurements.isEmpty) return;
    final path = Path();
    for (var index = 0; index < measurements.length; index++) {
      final point = Offset(
        _x(index, plot),
        scale.y(valueOf(measurements[index]).toDouble(), plot),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = colors.surface
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < measurements.length; index++) {
      final point = Offset(
        _x(index, plot),
        scale.y(valueOf(measurements[index]).toDouble(), plot),
      );
      canvas.drawCircle(point, 4.5, fill);
      canvas.drawCircle(point, 4.5, outline);
    }
  }

  void _drawDates(Canvas canvas, Rect plot) {
    if (measurements.isEmpty) return;
    final available = plot.width / measurements.length;
    final step = math.max(1, (64 / math.max(available, 1)).ceil());
    for (var index = 0; index < measurements.length; index += step) {
      final date = measurements[index].measuredAt.toLocal();
      final label =
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}\n'
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (_x(index, plot) - painter.width / 2).clamp(
            0,
            plot.right - painter.width,
          ),
          plot.bottom + 8,
        ),
      );
    }
  }

  double _x(int index, Rect plot) {
    if (measurements.length <= 1) return plot.center.dx;
    return plot.left + plot.width * index / (measurements.length - 1);
  }

  @override
  bool shouldRepaint(_LinesPainter oldDelegate) =>
      oldDelegate.measurements != measurements ||
      oldDelegate.scale != scale ||
      oldDelegate.averages != averages ||
      oldDelegate.colors != colors;
}

class _YAxisPainter extends CustomPainter {
  const _YAxisPainter({
    required this.scale,
    required this.averages,
    required this.colors,
  });

  final _ChartScale scale;
  final _Averages? averages;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      0,
      _LinesPainter._top,
      size.width,
      size.height - _LinesPainter._bottom,
    );
    final axisX = size.width - 1;
    canvas.drawLine(
      Offset(axisX, plot.top),
      Offset(axisX, plot.bottom),
      Paint()
        ..color = colors.outline
        ..strokeWidth = 1.5,
    );
    for (var index = 0; index <= 5; index++) {
      final value = scale.maximum - scale.range * index / 5;
      final y = plot.top + plot.height * index / 5;
      _paintText(
        canvas,
        value.round().toString(),
        Offset(axisX - 8, y),
        colors.onSurfaceVariant,
        alignRight: true,
      );
      canvas.drawLine(
        Offset(axisX - 5, y),
        Offset(axisX, y),
        Paint()..color = colors.outline,
      );
    }
    final averages = this.averages;
    if (averages == null) return;
    final labels = [
      _AverageLabel('SYS', averages.sys, _sysColor),
      _AverageLabel('DIA', averages.dia, _diaColor),
      _AverageLabel('P', averages.pulse, _pulseColor),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final positions = <double>[];
    for (final label in labels) {
      var y = scale.y(label.value, plot).clamp(plot.top + 8, plot.bottom - 8);
      if (positions.isNotEmpty && y - positions.last < 18) {
        y = positions.last + 18;
      }
      positions.add(y.clamp(plot.top + 8, plot.bottom - 8));
    }
    for (var index = 0; index < labels.length; index++) {
      final label = labels[index];
      final y = positions[index];
      _paintText(
        canvas,
        '${label.name} ${label.value.round()}',
        Offset(axisX - 8, y),
        label.color,
        alignRight: true,
        bold: true,
      );
      canvas.drawCircle(Offset(axisX, y), 3.5, Paint()..color = label.color);
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color, {
    required bool alignRight,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          backgroundColor: colors.surface.withValues(alpha: 0.88),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        alignRight ? anchor.dx - painter.width : anchor.dx,
        anchor.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_YAxisPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.averages != averages ||
      oldDelegate.colors != colors;
}

class _ChartScale {
  const _ChartScale(this.minimum, this.maximum);

  factory _ChartScale.fromMeasurements(List<Measurement> measurements) {
    final values = <int>[
      for (final item in measurements) ...[
        item.systolic,
        item.diastolic,
        item.pulse,
      ],
    ];
    final rawMin = values.reduce(math.min).toDouble();
    final rawMax = values.reduce(math.max).toDouble();
    final padding = math.max(8.0, (rawMax - rawMin) * 0.1);
    final minimum = ((rawMin - padding) / 5).floor() * 5.0;
    final maximum = ((rawMax + padding) / 5).ceil() * 5.0;
    return _ChartScale(minimum, maximum == minimum ? minimum + 10 : maximum);
  }

  final double minimum;
  final double maximum;
  double get range => maximum - minimum;

  double y(double value, Rect plot) =>
      plot.bottom - (value - minimum) / range * plot.height;

  @override
  bool operator ==(Object other) =>
      other is _ChartScale &&
      other.minimum == minimum &&
      other.maximum == maximum;

  @override
  int get hashCode => Object.hash(minimum, maximum);
}

class _Averages {
  const _Averages(
    this.sys,
    this.dia,
    this.pulse, {
    required this.usesLastSevenDays,
  });

  static _Averages? fromLastSevenDays(
    List<Measurement> measurements,
    DateTime now,
  ) {
    final localNow = now.toLocal();
    final cutoff = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    ).subtract(const Duration(days: 6));
    final recent = measurements
        .where((item) {
          final measuredAt = item.measuredAt.toLocal();
          return !measuredAt.isBefore(cutoff) && !measuredAt.isAfter(localNow);
        })
        .toList(growable: false);
    final source = recent.isEmpty ? measurements : recent;
    if (source.isEmpty) return null;
    double average(int Function(Measurement) valueOf) =>
        source.fold<double>(0, (sum, item) => sum + valueOf(item)) /
        source.length;
    return _Averages(
      average((item) => item.systolic),
      average((item) => item.diastolic),
      average((item) => item.pulse),
      usesLastSevenDays: recent.isNotEmpty,
    );
  }

  final double sys;
  final double dia;
  final double pulse;
  final bool usesLastSevenDays;

  @override
  bool operator ==(Object other) =>
      other is _Averages &&
      other.sys == sys &&
      other.dia == dia &&
      other.pulse == pulse &&
      other.usesLastSevenDays == usesLastSevenDays;

  @override
  int get hashCode => Object.hash(sys, dia, pulse, usesLastSevenDays);
}

class _AverageLabel {
  const _AverageLabel(this.name, this.value, this.color);

  final String name;
  final double value;
  final Color color;
}
