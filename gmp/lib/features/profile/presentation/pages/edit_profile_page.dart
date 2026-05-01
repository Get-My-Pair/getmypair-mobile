import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../profile_screen_system_ui.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile profile;
  final String accessToken;

  const EditProfilePage({
    super.key,
    required this.profile,
    required this.accessToken,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _nickNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isPickingImage = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _nickNameController = TextEditingController(
      text: _deriveNickname(widget.profile.name),
    );
    _phoneController = TextEditingController(text: widget.profile.phone);
    _emailController = TextEditingController(text: widget.profile.email ?? '');
    _passwordController = TextEditingController(text: '........');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nickNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _handleImagePick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _handleImagePick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final originalBytes = await file.readAsBytes();
      if (!mounted) return;

      Uint8List? croppedBytes;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final controller = CropController();
          final cropHeight = (MediaQuery.sizeOf(ctx).height * 0.5).clamp(
            280.0,
            400.0,
          );
          return AlertDialog(
            title: const Text('Crop image'),
            content: SizedBox(
              width: double.maxFinite,
              height: cropHeight,
              child: Crop(
                image: originalBytes,
                controller: controller,
                onCropped: (bytes) {
                  croppedBytes = bytes;
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => controller.crop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Crop'),
              ),
            ],
          );
        },
      );

      final bytes = croppedBytes ?? originalBytes;
      final fileName = file.path.split('/').last;

      if (!mounted) return;
      context.read<ProfileBloc>().add(
        ProfileImageUploadRequested(
          accessToken: widget.accessToken,
          imageBytes: bytes,
          fileName: fileName,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  String _deriveNickname(String fullName) {
    final cleaned = fullName.trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    return parts.first;
  }

  /// Vertical space needed by the form at [scale], mirroring clamps in [build].
  double _estimateEditProfileColumnHeight(double scale) {
    double sx(double v, double lo, double hi) => (v * scale).clamp(lo, hi);

    var h = 0.0;
    h += sx(100, 72, 100);
    h += sx(20, 10, 22);
    for (var i = 0; i < 5; i++) {
      h += sx(15, 11, 14);
      h += sx(8, 4, 8);
      final v = sx(11, 7, 11);
      final t = sx(14, 11, 14);
      final hasSuffix = i == 4;
      final icon = hasSuffix ? sx(32, 24, 32) : 0.0;
      final base = 2 * v + t * 1.28;
      h += (hasSuffix ? (base > icon ? base : icon) : base) + 6;
      h += sx(12, 7, 14);
    }
    h += sx(18, 10, 20);
    h += sx(15, 11, 14);
    h += sx(8, 4, 8);
    h += sx(14, 11, 14) * 1.2;
    h += sx(20, 8, 16);
    h += sx(15, 11, 14);
    h += sx(6, 3, 6);
    h += sx(14, 11, 14) * 1.2;
    h += sx(16, 10, 20);
    // Matches article create primary pill (height ~50, scaled).
    h += sx(50, 44, 52);
    return h;
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      await showAppFeedbackAlert(
        context,
        message: 'Please enter your full name.',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (!mounted) return;
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            accessToken: widget.accessToken,
            name: name,
            email: email.isEmpty ? null : email,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) {
        if (current is ProfileError) return true;
        if (previous is ProfileUpdating && current is ProfileLoaded) return true;
        return false;
      },
      listener: (context, state) async {
        if (state is ProfileError) {
          await showAppFeedbackAlert(
            context,
            message: state.message,
            type: AppFeedbackType.failure,
          );
          return;
        }
        if (state is ProfileLoaded) {
          await showAppFeedbackAlert(
            context,
            message: 'Your profile has been updated.',
            type: AppFeedbackType.success,
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state is ProfileUpdating || state is ProfileImageUploading;
        final profile = (state is ProfileLoaded)
            ? state.profile
            : (state is ProfileUpdating)
            ? state.profile
            : (state is ProfileImageUploading)
            ? state.profile
            : widget.profile;

        final avatarImage =
            profile.profileImage != null && profile.profileImage!.isNotEmpty
            ? NetworkImage(profile.profileImage!)
            : null;

        final statusTop = MediaQuery.paddingOf(context).top;
        final size = MediaQuery.sizeOf(context);
        final deviceTextScale = MediaQuery.textScalerOf(context).scale(1.0);
        final shortestSide = size.shortestSide;
        final widthScale = (size.width / 390.0).clamp(0.82, 1.04);
        final heightScale = (size.height / 844.0).clamp(0.54, 1.0);
        final textScaleTightness = (1.06 / deviceTextScale).clamp(0.82, 1.04);
        final deviceClassScale = shortestSide < 360
            ? 0.90
            : shortestSide > 430
            ? 1.04
            : 1.0;
        final heightComfortScale = size.height < 760
            ? 0.92
            : size.height > 900
            ? 1.05
            : 1.0;
        final layoutScale = (widthScale < heightScale ? widthScale : heightScale) *
            textScaleTightness *
            deviceClassScale *
            heightComfortScale;
        final uiScale = layoutScale.clamp(0.50, 1.08);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: kProfileGradientHeaderSystemUi,
          child: Scaffold(
            extendBody: true,
            body: SafeArea(
              top: false,
              // Let the bottom-nav widget own the bottom inset, otherwise we can
              // end up double-padding and the header/card spacing feels off.
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        image: const DecorationImage(
                          image: AssetImage(BgTheme.backgroundImageAsset),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFABABAB),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      // No scrolling: shrink spacing, padding, and control sizes until
                      // the column fits the available height (see [_estimateEditProfileColumnHeight]).
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          var contentScale = uiScale.clamp(0.48, 1.08);
                          for (var i = 0; i < 22; i++) {
                            final padTop =
                                statusTop + 30;
                            final padBottom =
                                (72 * contentScale).clamp(22.0, 84.0);
                            final innerH =
                                constraints.maxHeight - padTop - padBottom;
                            if (innerH <= 80) break;
                            final need =
                                _estimateEditProfileColumnHeight(contentScale);
                            if (need <= innerH - 2) break;
                            contentScale *= (innerH / need) * 0.995;
                            if (contentScale < 0.44) {
                              contentScale = 0.44;
                              break;
                            }
                          }
                          contentScale = contentScale.clamp(0.44, uiScale);

                          final padTop =
                              statusTop + 30;
                          final padBottom =
                              (72 * contentScale).clamp(22.0, 84.0);

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              (18 * contentScale).clamp(12.0, 18.0),
                              padTop,
                              (18 * contentScale).clamp(12.0, 18.0),
                              padBottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(
                                  profile,
                                  avatarImage,
                                  isLoading,
                                  state,
                                  contentScale,
                                ),
                                SizedBox(
                                  height: (20 * contentScale).clamp(10.0, 22.0),
                                ),
                                _buildLabel('Full Name', contentScale),
                                SizedBox(
                                  height: (8 * contentScale).clamp(4.0, 8.0),
                                ),
                                _profileField(
                                  controller: _nameController,
                                  scale: contentScale,
                                ),
                                SizedBox(
                                  height: (12 * contentScale).clamp(7.0, 14.0),
                                ),
                                _buildLabel('Nick Name', contentScale),
                                SizedBox(
                                  height: (8 * contentScale).clamp(4.0, 8.0),
                                ),
                                _profileField(
                                  controller: _nickNameController,
                                  readOnly: true,
                                  scale: contentScale,
                                ),
                                SizedBox(
                                  height: (12 * contentScale).clamp(7.0, 14.0),
                                ),
                                _buildLabel('Phone Number', contentScale),
                                SizedBox(
                                  height: (8 * contentScale).clamp(4.0, 8.0),
                                ),
                                _profileField(
                                  controller: _phoneController,
                                  readOnly: true,
                                  scale: contentScale,
                                ),
                                SizedBox(
                                  height: (12 * contentScale).clamp(7.0, 14.0),
                                ),
                                _buildLabel('E-Mail Address', contentScale),
                                SizedBox(
                                  height: (8 * contentScale).clamp(4.0, 8.0),
                                ),
                                _profileField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  scale: contentScale,
                                ),
                                SizedBox(
                                  height: (12 * contentScale).clamp(7.0, 14.0),
                                ),
                                _buildLabel('Password', contentScale),
                                SizedBox(
                                  height: (8 * contentScale).clamp(4.0, 8.0),
                                ),
                                _profileField(
                                  controller: _passwordController,
                                  readOnly: true,
                                  obscureText: !_showPassword,
                                  scale: contentScale,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    splashRadius:
                                        (22 * contentScale).clamp(14.0, 22.0),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xCCFFFFFF),
                                      size: (24 * contentScale)
                                          .clamp(18.0, 24.0),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (18 * contentScale).clamp(10.0, 20.0),
                                ),
                                _buildLabel('Foot Size Chart', contentScale),
                                SizedBox(
                                  height: (8 * contentScale).clamp(4.0, 8.0),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _footMetricChip(
                                        'US:10',
                                        contentScale,
                                      ),
                                    ),
                                    SizedBox(
                                      width: (8 * contentScale)
                                          .clamp(4.0, 8.0),
                                    ),
                                    Expanded(
                                      child: _footMetricChip(
                                        'UK:09',
                                        contentScale,
                                      ),
                                    ),
                                    SizedBox(
                                      width: (8 * contentScale)
                                          .clamp(4.0, 8.0),
                                    ),
                                    Expanded(
                                      child: _footMetricChip(
                                        'EURO:41',
                                        contentScale,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: (20 * contentScale).clamp(8.0, 16.0),
                                ),
                                _buildLabel('Foot Abnormality', contentScale),
                                SizedBox(
                                  height: (6 * contentScale).clamp(3.0, 6.0),
                                ),
                                Text(
                                  'Wide Foot',
                                  style: GoogleFonts.boldonse(
                                    fontSize: (14 * contentScale)
                                        .clamp(11.0, 14.0),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (16 * contentScale).clamp(10.0, 20.0),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildSaveChangesButton(
                                    scale: contentScale,
                                    isBusy: isLoading,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const DashboardLinkedBottomNav(selectedTabIndex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    UserProfile profile,
    ImageProvider<Object>? avatarImage,
    bool isLoading,
    ProfileState state,
    double scale,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Edit Profile',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: GoogleFonts.boldonse(
              color: const Color(0xFFDFE7E9),
              fontSize: (22 * scale).clamp(16.0, 22.0),
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
        SizedBox(
          width: (102 * scale).clamp(72.0, 102.0),
          height: (100 * scale).clamp(72.0, 100.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: (6 * scale).clamp(3.0, 6.0),
                right: 0,
                child: CircleAvatar(
                  radius: (35.0 * scale).clamp(24.0, 35.0),
                  backgroundColor: const Color(0x33FFFFFF),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.boldonse(
                            fontSize: (18 * scale).clamp(12.0, 18.0),
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : null,
                ),
              ),
              if (state is ProfileImageUploading || _isPickingImage)
                const Positioned(
                  top: 8,
                  right: 0,
                  child: SizedBox(
                    width: 79,
                    height: 79,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.overlayOnGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 1,
                top: 40,
                child: InkWell(
                  onTap: isLoading ? null : _pickAndUploadImage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: (48 * scale).clamp(34.0, 48.0),
                    width: (48 * scale).clamp(34.0, 48.0),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0E8EA4),
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: (20 * scale).clamp(13.0, 20.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, double scale) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: (15 * scale).clamp(11.0, 14.0),
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1,
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    double scale = 1.0,
  }) {
    final radius = BorderRadius.circular(100);
    final glassTint = readOnly
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.11);
    final borderAlpha = readOnly ? 0.18 : 0.26;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: glassTint,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: borderAlpha),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.montserrat(
              fontSize: (13 * scale).clamp(10.0, 13.0),
              fontWeight: FontWeight.w500,
              color: const Color(0xF2FFFFFF),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: (18 * scale).clamp(12.0, 18.0),
                vertical: (10 * scale).clamp(7.0, 10.0),
              ),
              suffixIcon: suffix,
              suffixIconConstraints: BoxConstraints(
                minHeight: (34 * scale).clamp(24.0, 34.0),
                minWidth: (40 * scale).clamp(28.0, 40.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footMetricChip(String value, double scale) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: GoogleFonts.boldonse(
          fontSize: (12 * scale).clamp(10.0, 12.0),
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Same visual language as [ArticleCreatePage] primary actions (white pill, cyan border, Boldonse).
  Widget _buildSaveChangesButton({
    required double scale,
    required bool isBusy,
  }) {
    const teal = Color(0xFF12899B);
    const cyanBorder = Color(0xFF09DFFF);
    final fontSize = (14 * scale).clamp(12.0, 14.0);
    final btnHeight = (50 * scale).clamp(44.0, 52.0);
    final indicator = (22 * scale).clamp(18.0, 22.0);

    return ElevatedButton(
      onPressed: isBusy ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: teal,
        disabledBackgroundColor: Colors.white,
        disabledForegroundColor: teal,
        elevation: 2,
        shadowColor: Colors.black26,
        padding: EdgeInsets.symmetric(
          horizontal: (24 * scale).clamp(18.0, 28.0),
        ),
        minimumSize: Size(0, btnHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: const BorderSide(color: cyanBorder, width: 1),
        ),
      ),
      child: isBusy
          ? SizedBox(
              width: indicator,
              height: indicator,
              child: const CircularProgressIndicator(
                color: teal,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Save Changes',
              style: GoogleFonts.boldonse(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: teal,
              ),
            ),
    );
  }
}
