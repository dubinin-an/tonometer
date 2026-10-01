import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/measurement_repository.dart';
import '../domain/measurement_draft.dart';
import '../l10n/l10n.dart';
import '../services/seven_segment_recognizer.dart';
import 'measurement_form_screen.dart';
import 'recognition_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    required this.repository,
    required this.recognizer,
    this.returnDraft = false,
    super.key,
  }) : calibrationMode = false;

  const CameraScreen.calibration({super.key})
    : repository = null,
      recognizer = null,
      returnDraft = false,
      calibrationMode = true;

  final MeasurementRepository? repository;
  final SevenSegmentRecognizer? recognizer;
  final bool returnDraft;
  final bool calibrationMode;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _error;
  var _busy = false;
  var _torchEnabled = false;
  var _initializing = false;
  var _cameraGeneration = 0;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  Offset? _focusIndicator;
  Timer? _focusIndicatorTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _initialize();
      return;
    }
    _cameraGeneration++;
    unawaited(_disposeController());
  }

  Future<void> _initialize() async {
    if (_initializing ||
        !mounted ||
        _lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _initializing = true;
    final generation = _cameraGeneration;
    CameraController? candidate;
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (!_isCurrentInitialization(generation)) return;
      if (cameras.isEmpty) throw StateError(context.l10n.cameraNotFound);
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      candidate = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await candidate.initialize();
      await _configureCamera(candidate);
      if (!_isCurrentInitialization(generation)) {
        await candidate.dispose();
        candidate = null;
        return;
      }
      setState(() {
        _controller = candidate;
        _error = null;
        _torchEnabled = false;
      });
      candidate = null;
    } catch (error) {
      await candidate?.dispose();
      candidate = null;
      if (_isCurrentInitialization(generation)) {
        setState(() => _error = error);
      }
    } finally {
      _initializing = false;
      if (mounted &&
          _lifecycleState == AppLifecycleState.resumed &&
          _controller == null &&
          generation != _cameraGeneration) {
        unawaited(_initialize());
      }
    }
  }

  bool _isCurrentInitialization(int generation) {
    return mounted &&
        generation == _cameraGeneration &&
        _lifecycleState == AppLifecycleState.resumed;
  }

  Future<void> _configureCamera(CameraController controller) async {
    for (final configure in <Future<void> Function()>[
      () => controller.setFocusMode(FocusMode.auto),
      () => controller.setFocusPoint(const Offset(0.5, 0.5)),
      () => controller.setExposurePoint(const Offset(0.5, 0.5)),
      () => controller.setFlashMode(FlashMode.off),
    ]) {
      try {
        await configure();
      } on CameraException {
        // Some devices do not expose every manual camera control.
      }
    }
  }

  Future<void> _focusAt(TapDownDetails details, Size previewSize) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final normalized = Offset(
      (details.localPosition.dx / previewSize.width).clamp(0, 1),
      (details.localPosition.dy / previewSize.height).clamp(0, 1),
    );
    setState(() => _focusIndicator = details.localPosition);
    _focusIndicatorTimer?.cancel();
    _focusIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusIndicator = null);
    });
    try {
      await Future.wait([
        controller.setFocusPoint(normalized),
        controller.setExposurePoint(normalized),
      ]);
    } on CameraException {
      // The preview remains usable when a device rejects a custom point.
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    final next = !_torchEnabled;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchEnabled = next);
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.torchUnavailable(error.description ?? error.code),
          ),
        ),
      );
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    if (mounted && controller != null) {
      setState(() {
        _controller = null;
        _torchEnabled = false;
      });
    } else {
      _controller = null;
      _torchEnabled = false;
    }
    await controller?.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final photo = await controller.takePicture();
      final bytes = await File(photo.path).readAsBytes();
      if (widget.calibrationMode) {
        if (mounted) Navigator.of(context).pop(bytes);
        return;
      }
      final rectified = await widget.recognizer!.preparePhoto(bytes);
      if (!mounted) return;
      final draft = await Navigator.of(context).push<MeasurementDraft>(
        MaterialPageRoute(
          builder: (_) => RecognitionPreviewScreen(
            repository: widget.repository!,
            recognizer: widget.recognizer!,
            rectifiedLcd: rectified,
            returnDraft: widget.returnDraft,
          ),
        ),
      );
      if (widget.returnDraft && draft != null && mounted) {
        Navigator.of(context).pop(draft);
        return;
      }
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.photoRecognitionFailed(error.toString())),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    _focusIndicatorTimer?.cancel();
    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.photographDevice),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _error != null
                  ? _CameraError(error: _error!, retry: _initialize)
                  : controller == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Center(
                      child: Stack(
                        children: [
                          CameraPreview(controller),
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final previewSize = constraints.biggest;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) =>
                                      _focusAt(details, previewSize),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: _Instruction(),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: _TorchButton(
                                          enabled: _torchEnabled,
                                          onPressed: _toggleTorch,
                                        ),
                                      ),
                                      if (_focusIndicator case final point?)
                                        Positioned(
                                          left: point.dx - 24,
                                          top: point.dy - 24,
                                          child: const IgnorePointer(
                                            child: _FocusIndicator(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _capture,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_busy ? l10n.recognizing : l10n.capture),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    heroTag: 'camera_manual_measurement',
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
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => MeasurementFormScreen(
                                repository: widget.repository!,
                              ),
                            ),
                          ),
                    child: const Icon(Icons.back_hand_outlined),
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

class _Instruction extends StatelessWidget {
  const _Instruction();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            context.l10n.cameraInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: enabled,
      label: enabled ? context.l10n.disableTorch : context.l10n.enableTorch,
      child: IconButton.filledTonal(
        tooltip: enabled ? context.l10n.disableLight : context.l10n.enableLight,
        onPressed: onPressed,
        icon: Icon(enabled ? Icons.flashlight_off : Icons.flashlight_on),
      ),
    );
  }
}

class _FocusIndicator extends StatelessWidget {
  const _FocusIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF55D6FF), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.cameraUnavailable(error.toString()),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: retry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
