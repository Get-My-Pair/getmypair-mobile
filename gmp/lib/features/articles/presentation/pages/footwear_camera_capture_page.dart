import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/presentation/widgets/footwear_angle_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// One capture per angle slot; only one accepted image per slot (min 3 slots).
class FootwearAngleSlot {
  File? acceptedImage;
  final List<File> rejectedImages = [];
}

enum _SlotReviewAction { accept, reject }

/// In-app camera with side-profile guide. [minCaptures]–[maxCaptures] accepted shots.
class FootwearCameraCapturePage extends StatefulWidget {
  const FootwearCameraCapturePage({
    super.key,
    this.minCaptures = minAngles,
    this.maxCaptures = maxAngles,
  }) : assert(minCaptures >= 1),
       assert(maxCaptures >= minCaptures);

  static const int minAngles = 1;
  static const int maxAngles = 3;

  /// Legacy alias — maximum capture slots.
  static const int requiredAngles = maxAngles;

  final int minCaptures;
  final int maxCaptures;

  @override
  State<FootwearCameraCapturePage> createState() =>
      _FootwearCameraCapturePageState();
}

class _FootwearCameraCapturePageState extends State<FootwearCameraCapturePage> {
  static const Color _teal = Color(0xFF12899B);

  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _capturing = false;

  late final List<FootwearAngleSlot> _slots;

  int get _maxCaptures => widget.maxCaptures;
  int get _minCaptures => widget.minCaptures;

  @override
  void initState() {
    super.initState();
    _slots = List.generate(_maxCaptures, (_) => FootwearAngleSlot());
    _initCamera();
  }

  int get _activeSlotIndex {
    final idx = _slots.indexWhere((s) => s.acceptedImage == null);
    return idx == -1 ? _maxCaptures - 1 : idx;
  }

  int get _acceptedCount =>
      _slots.where((s) => s.acceptedImage != null).length;

  bool get _canFinish => _acceptedCount >= _minCaptures;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Camera permission is required to capture footwear photos.';
        });
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera found on this device.');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<File?> _persistCapture(XFile xFile) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/footwear_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return File(xFile.path).copy(path);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    if (_acceptedCount >= _maxCaptures) return;

    setState(() => _capturing = true);
    try {
      final xFile = await controller.takePicture();
      final file = await _persistCapture(xFile);
      if (file == null || !mounted) return;
      await _reviewCapture(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _reviewCapture(File file) async {
    final slotIndex = _activeSlotIndex;
    final action = await showModalBottomSheet<_SlotReviewAction>(
      context: context,
      backgroundColor: const Color(0xFF0D5B68),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Photo ${slotIndex + 1} of $_maxCaptures',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file, height: 180, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                Text(
                  'Does this show a clear side profile?',
                  style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pop(ctx, _SlotReviewAction.reject),
                        icon: const Icon(Icons.close, color: AppColors.error),
                        label: const Text('Wrong angle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pop(ctx, _SlotReviewAction.accept),
                        icon: const Icon(Icons.check, color: _teal),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    setState(() {
      final slot = _slots[slotIndex];
      if (action == _SlotReviewAction.accept) {
        if (slot.acceptedImage != null) {
          slot.rejectedImages.add(slot.acceptedImage!);
        }
        slot.acceptedImage = file;
      } else {
        slot.rejectedImages.add(file);
      }
    });
  }

  void _finish() {
    if (!_canFinish) return;
    final files = _slots
        .map((s) => s.acceptedImage)
        .whereType<File>()
        .toList();
    Navigator.pop(context, files);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !mounted) return;
    final files = picked.map((x) => File(x.path)).toList();
    if (files.length < _minCaptures) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least $_minCaptures image${_minCaptures > 1 ? 's' : ''}.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(context, files.take(_maxCaptures).toList());
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!),
          if (_initializing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_error != null)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (!_initializing && _error == null) ...[
            FootwearAngleOverlay(
              angleLabel: _acceptedCount >= _maxCaptures
                  ? 'Maximum photos captured'
                  : 'Photo ${_activeSlotIndex + 1} — align side profile in frame',
              lightLineGuide: true,
              shoeGuideOpacity: 0.9,
              showShoeGuide: true,
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: SvgPicture.asset(
                            'assets/images/chevron-left.svg',
                            width: 26,
                            height: 26,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Capture Footwear',
                            style: GoogleFonts.boldonse(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Text(
                          '$_acceptedCount/$_maxCaptures',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: _pickFromGallery,
                          child: Text(
                            'Gallery',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _thumbnailStrip(horizontal),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _canFinish
                                ? (_acceptedCount >= _maxCaptures
                                    ? 'Tap Done to continue.'
                                    : 'Tap Done or capture more (up to $_maxCaptures).')
                                : 'Capture side profile for photo ${_activeSlotIndex + 1}',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _capturing ? null : _capture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _capturing
                                    ? const Padding(
                                        padding: EdgeInsets.all(18),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _teal,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 88,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _canFinish ? _finish : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _teal,
                              disabledBackgroundColor: Colors.white38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Text(
                              'Done',
                              style: GoogleFonts.boldonse(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _thumbnailStrip(double horizontal) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        children: [
          for (var i = 0; i < _maxCaptures; i++)
            _slotThumbnail(i),
          ..._slots.expand((s) => s.rejectedImages.map(_rejectedThumb)),
        ],
      ),
    );
  }

  Widget _slotThumbnail(int index) {
    final slot = _slots[index];
    final file = slot.acceptedImage;
    final isActive = index == _activeSlotIndex && file == null;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFF09DFFF) : Colors.white38,
                width: isActive ? 2 : 1,
              ),
              color: Colors.black26,
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white54,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          if (file != null)
            Positioned(
              top: 4,
              right: 4,
              child: _badgeIcon(Icons.check_circle, AppColors.success),
            ),
        ],
      ),
    );
  }

  Widget _rejectedThumb(File file) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              color: Colors.black54,
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _badgeIcon(Icons.cancel, AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
