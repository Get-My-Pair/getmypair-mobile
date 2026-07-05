import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/data/footwear_background_remover.dart';
import 'package:gmp/features/articles/data/footwear_image_validator.dart';
import 'package:gmp/features/articles/data/footwear_live_scanner.dart';
import 'package:gmp/features/articles/data/footwear_orientation_detector.dart';
import 'package:gmp/features/articles/presentation/widgets/footwear_cutout_preview.dart';
import 'package:gmp/features/articles/presentation/pages/footwear_camera_capture_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum _CaptureReviewAction { accept, reject }

/// Upload footwear: compact camera frame, capture up to 3, keep one best photo.
class UploadFootwearPage extends StatefulWidget {
  const UploadFootwearPage({super.key, this.initialFiles = const []});

  final List<File> initialFiles;

  static const Color _teal = Color(0xFF12899B);
  static const Color _cyanBorder = Color(0xFF09DFFF);
  static const int requiredPhotos = 1;
  static const int maxPhotos = FootwearCameraCapturePage.maxAngles;

  @override
  State<UploadFootwearPage> createState() => _UploadFootwearPageState();
}

class _UploadFootwearPageState extends State<UploadFootwearPage>
    with WidgetsBindingObserver {
  static const int _maxPhotos = UploadFootwearPage.maxPhotos;
  static const int _requiredPhotos = UploadFootwearPage.requiredPhotos;

  CameraController? _cameraController;
  bool _cameraInitializing = true;
  String? _cameraError;
  bool _capturing = false;
  bool _validatingImage = false;
  String _processingLabel = 'Checking footwear…';
  FootwearScanStatus _scanStatus = FootwearScanStatus.idle;

  final FootwearLiveScanner _liveScanner = FootwearLiveScanner();
  late List<File> _images;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _images = List<File>.from(widget.initialFiles.take(_maxPhotos));
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveScanner.stop();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    _liveScanner.updateDeviceOrientation(
      landscape
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.portraitUp,
    );
  }

  void _disposeCamera() {
    _liveScanner.stop();
    _cameraController?.dispose();
    _cameraController = null;
  }

  void _onScanStatusChanged(FootwearScanStatus status) {
    if (!mounted || _validatingImage || _capturing) return;
    setState(() => _scanStatus = status);
  }

  Future<void> _startLiveScan(CameraController controller) async {
    if (_validatingImage || _capturing || _remaining <= 0) return;
    await _liveScanner.start(
      controller: controller,
      onStatusChanged: _onScanStatusChanged,
    );
    if (!mounted) return;
    setState(() => _scanStatus = _liveScanner.status);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_validatingImage) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      if (state == AppLifecycleState.resumed && _cameraError != null) {
        _initCamera();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
      if (mounted) {
        setState(() {
          _cameraInitializing = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  int get _remaining => _maxPhotos - _images.length;

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _cameraInitializing = false;
          _cameraError =
              'Camera permission is required to capture footwear photos.';
        });
      }
      return;
    }

    try {
      _disposeCamera();
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
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraInitializing = false;
        _cameraError = null;
      });
      await _startLiveScan(controller);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraInitializing = false;
        _cameraError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<File?> _persistCapture(XFile xFile) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/footwear_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return File(xFile.path).copy(path);
  }

  Future<bool> _ensureGalleryPermission() async {
    // Android uses the system photo picker — no READ_MEDIA_* permissions required.
    if (Platform.isAndroid) return true;

    if (!Platform.isIOS) return true;

    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;

    status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;

    if (!mounted) return false;
    await _showMessageDialog(
      title: 'Photo access needed',
      message: 'Photo library access is required to upload images.',
    );
    return false;
  }

  Future<void> _pickFromGallery() async {
    if (_remaining <= 0) return;
    if (!await _ensureGalleryPermission()) return;

    final picker = ImagePicker();
    List<XFile> picked;

    if (_remaining == 1) {
      final one = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (one == null || !mounted) return;
      picked = [one];
    } else {
      final multi = await picker.pickMultiImage(imageQuality: 90);
      if (multi.isEmpty || !mounted) return;
      picked = multi.take(_remaining).toList();
    }

    for (final xFile in picked) {
      if (!mounted || _remaining <= 0) break;
      final file = await _persistCapture(xFile);
      if (file == null || !mounted) continue;
      await _processNewImage(file);
    }
  }

  Future<void> _captureFromPreview() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        _remaining <= 0) {
      return;
    }

    setState(() => _capturing = true);
    await _liveScanner.stop();
    try {
      final xFile = await controller.takePicture();
      final file = await _persistCapture(xFile);
      if (file == null || !mounted) return;
      await _processNewImage(file);
    } catch (e) {
      if (mounted) {
        await _showMessageDialog(
          title: 'Capture failed',
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        final active = _cameraController;
        if (active != null && active.value.isInitialized) {
          await _startLiveScan(active);
        }
      }
    }
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
    bool isError = true,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D5B68),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? AppColors.error : const Color(0xFF09DFFF),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF09DFFF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFootwearValidationError(
    FootwearImageValidationResult result,
  ) {
    return _showMessageDialog(
      title: FootwearImageValidator.dialogTitle(result),
      message: result.message ?? FootwearImageValidator.rejectionMessage,
      isError: true,
    );
  }

  Future<void> _processNewImage(File file) async {
    if (!mounted) return;

    await _liveScanner.stop();
    setState(() {
      _validatingImage = true;
      _processingLabel = 'Checking footwear…';
      _scanStatus = FootwearScanStatus.idle;
    });

    try {
      FootwearImageValidationResult result;
      try {
        result = await FootwearImageValidator.validate(file);
      } catch (e) {
        if (!mounted) return;
        await _showMessageDialog(
          title: 'Processing failed',
          message:
              'Could not verify this image. Please try again.\n${e.toString().replaceFirst('Exception: ', '')}',
        );
        return;
      }

      if (!mounted) return;
      if (!result.isFootwear) {
        await _showFootwearValidationError(result);
        return;
      }

      File imageToSave = file;
      if (FootwearBackgroundRemover.isConfigured) {
        if (mounted) {
          setState(() => _processingLabel = 'Preparing photo…');
        }
        try {
          imageToSave = await FootwearBackgroundRemover.removeBackground(file);
        } on FootwearBackgroundRemoverException catch (e) {
          if (!mounted) return;
          await _showMessageDialog(
            title: 'Photo preparation failed',
            message: e.message,
          );
          return;
        } catch (e) {
          if (!mounted) return;
          await _showMessageDialog(
            title: 'Photo preparation failed',
            message: e.toString().replaceFirst('Exception: ', ''),
          );
          return;
        }
      }

      if (mounted) {
        setState(() => _processingLabel = 'Checking orientation…');
      }
      final orientation =
          await FootwearOrientationDetector.detect(imageToSave);
      if (!mounted) return;
      if (!orientation.isRightFacing) {
        await _showMessageDialog(
          title: 'Wrong side',
          message: FootwearOrientationDetector.wrongSideMessage,
        );
        return;
      }

      await _reviewCapture(saveFile: imageToSave);
    } finally {
      if (mounted) {
        setState(() => _validatingImage = false);
        final active = _cameraController;
        if (active != null &&
            active.value.isInitialized &&
            _remaining > 0) {
          await _startLiveScan(active);
        }
      }
    }
  }

  Future<void> _reviewCapture({required File saveFile}) async {
    final action = await showModalBottomSheet<_CaptureReviewAction>(
      context: context,
      backgroundColor: const Color(0xFF0D5B68),
      isScrollControlled: true,
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
                  'Photo ${_images.length + 1} of $_maxPhotos',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FootwearCutoutPreview(
                    file: saveFile,
                    height: 220,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Does this show a clear side profile?',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pop(ctx, _CaptureReviewAction.reject),
                        icon: const Icon(Icons.close, color: AppColors.error),
                        label: const Text('Retake'),
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
                            Navigator.pop(ctx, _CaptureReviewAction.accept),
                        icon: const Icon(
                          Icons.check,
                          color: UploadFootwearPage._teal,
                        ),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: UploadFootwearPage._teal,
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

    if (!mounted || action != _CaptureReviewAction.accept) return;
    setState(() => _images.add(saveFile));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _showPhotoPreview(File file) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FootwearCutoutPreview(
                file: file,
                height: 360,
                fit: BoxFit.contain,
                borderRadius: 16,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMultiplePhotosWarning() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D5B68),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Choose one photo only',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have ${_images.length} photos. Remove the extra ${_images.length - 1} '
          'and keep only your best side-profile shot, then tap Done.',
          style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF09DFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    if (_images.isEmpty) {
      await _showMessageDialog(
        title: 'Photo required',
        message:
            'Capture or upload at least one side-profile photo of your footwear.',
        isError: false,
      );
      return;
    }
    if (_images.length > _requiredPhotos) {
      _showMultiplePhotosWarning();
      return;
    }
    Navigator.pop(context, List<File>.from(_images));
  }

  Widget _liveCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      if (_cameraInitializing) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _cameraError ?? 'Camera unavailable',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              if (_cameraError != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final status = await Permission.camera.status;
                    if (status.isPermanentlyDenied) {
                      await openAppSettings();
                    }
                    if (!mounted) return;
                    setState(() {
                      _cameraInitializing = true;
                      _cameraError = null;
                    });
                    _initCamera();
                  },
                  child: Text(
                    'Allow camera / Retry',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF09DFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return CameraPreview(controller);
        }

        // Cover the frame so no letterboxing (black bars) on the sides.
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }

  /// Figma header: back + title row, then 2-line subtitle (wraps, no clip).
  Widget _headerSection() {
    final subtitleSize = Responsive.fontSize(context, 14).clamp(12.0, 14.0);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 26, height: 26),
                visualDensity: VisualDensity.compact,
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
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Upload Footwear',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.boldonse(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Please upload a clear image showing the side profile\n'
            'of your footwear for accurate detection.',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: subtitleSize,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  static const String _cameraShoeGuideAsset =
      'assets/images/icons/myrack/shoe.png';

  /// Centered camera frame + shoe guide (Figma layout).
  Widget _captureRow(double contentWidth) {
    final frameW = contentWidth * 0.88;
    final frameH = frameW * (0.55 / 0.88);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: frameW,
          height: frameH,
          child: _cameraPreviewStack(),
        ),
      ),
    );
  }

  Widget _capturedPhotosStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose the best one  (${_images.length}/$_maxPhotos)',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a photo to preview · tap × to remove',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _maxPhotos; i++)
              Padding(
                padding: EdgeInsets.only(right: i < _maxPhotos - 1 ? 12 : 0),
                child: _photoSlot(i),
              ),
          ],
        ),
      ],
    );
  }

  static const double _slotSize = 92;

  Widget _photoSlot(int index) {
    final hasImage = index < _images.length;
    if (!hasImage) {
      return Container(
        width: _slotSize,
        height: _slotSize,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.4,
            child: Image.asset(
              _cameraShoeGuideAsset,
              width: _slotSize * 0.6,
              height: _slotSize * 0.6,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.checkroom_outlined,
                size: _slotSize * 0.4,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      );
    }

    final file = _images[index];
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showPhotoPreview(file),
            child: SizedBox(
              width: _slotSize,
              height: _slotSize,
              child: FootwearCutoutPreview(
                file: file,
                height: _slotSize,
                fit: BoxFit.contain,
                borderRadius: 12,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _validatingImage ? null : () => _removeImage(index),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.error,
                child: Icon(
                  Icons.close,
                  color: AppColors.textOnPrimary,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Figma shoe guide — camera preview center only.
  Widget _cameraShoeGuideOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Center(
          child: Opacity(
            opacity: 0.9,
            child: Image.asset(
              _cameraShoeGuideAsset,
              width: w * 0.78,
              height: h * 0.68,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.checkroom_outlined,
                size: (w * 0.35).clamp(48.0, 72.0),
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cameraPreviewStack() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _liveCameraPreview(),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _cameraShoeGuideOverlay(),
            ),
          ),
        ),
        if (_validatingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    _processingLabel,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Figma: Click Image → divider copy → Upload Image.
  Widget _captureActionsSection() {
    final atMax = _remaining <= 0;
    final cameraReady = _cameraController != null &&
        _cameraController!.value.isInitialized;
    final helperSize = Responsive.fontSize(context, 13).clamp(11.0, 13.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _actionButton(
            label: atMax ? 'Max $_maxPhotos photos' : 'Click Image',
            onPressed: !atMax && cameraReady && !_validatingImage
                ? _captureFromPreview
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'or Upload images of the same orientation',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: helperSize,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          _actionButton(
            label: atMax ? 'Max $_maxPhotos photos' : 'Upload Image',
            onPressed: !atMax && !_validatingImage ? _pickFromGallery : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);

    return Scaffold(
      backgroundColor: BgTheme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...BgTheme.background(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth - horizontal * 2;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _headerSection(),
                          _captureRow(contentWidth),
                          _captureActionsSection(),
                          const SizedBox(height: 16),
                          _capturedPhotosStrip(),
                          if (_images.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 24),
                              child: _actionButton(
                                label: 'Done',
                                onPressed: _finish,
                              ),
                            )
                          else
                            const SizedBox(height: 24),
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    final textColor = enabled
        ? UploadFootwearPage._teal
        : UploadFootwearPage._teal.withValues(alpha: 0.5);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.white : Colors.white38,
          foregroundColor: UploadFootwearPage._teal,
          disabledBackgroundColor: Colors.white38,
          disabledForegroundColor: UploadFootwearPage._teal.withValues(alpha: 0.5),
          elevation: enabled ? 2 : 0,
          shadowColor: Colors.black26,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: const BorderSide(
              color: UploadFootwearPage._cyanBorder,
              width: 1,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: GoogleFonts.boldonse(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.15,
              letterSpacing: 0.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
