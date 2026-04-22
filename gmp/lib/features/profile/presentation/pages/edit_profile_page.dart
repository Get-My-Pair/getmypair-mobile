import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
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
  static const Color _inputFill = Color(0x24FFFFFF);
  static const Color _inputFillReadOnly = Color(0x1FFFFFFF);
  static const Color _inputBorder = Color(0x40FFFFFF);
  static const Color _inputBorderFocused = Color(0x8CFFFFFF);

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
                      child: SingleChildScrollView(
                        // Status bar inset; keep the last fields above the bottom bar.
                        padding: EdgeInsets.fromLTRB(
                          20,
                          statusTop + 20,
                          20,
                          112,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(
                              profile,
                              avatarImage,
                              isLoading,
                              state,
                            ),
                            const SizedBox(height: 26),
                            _buildLabel('Full Name'),
                            const SizedBox(height: 8),
                            _profileField(controller: _nameController),
                            const SizedBox(height: 18),
                            _buildLabel('Nick Name'),
                            const SizedBox(height: 8),
                            _profileField(
                              controller: _nickNameController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Phone Number'),
                            const SizedBox(height: 8),
                            _profileField(
                              controller: _phoneController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('E-Mail Address'),
                            const SizedBox(height: 8),
                            _profileField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Password'),
                            const SizedBox(height: 8),
                            _profileField(
                              controller: _passwordController,
                              readOnly: true,
                              obscureText: !_showPassword,
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                splashRadius: 18,
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xCCFFFFFF),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildLabel('Foot Size Chart'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _footMetricChip('US:10')),
                                const SizedBox(width: 10),
                                Expanded(child: _footMetricChip('UK:09')),
                                const SizedBox(width: 10),
                                Expanded(child: _footMetricChip('EURO:41')),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _buildLabel('Foot Abnormality'),
                            const SizedBox(height: 8),
                            Text(
                              'Wide Foot',
                              style: GoogleFonts.boldonse(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            // Align with the reference header rhythm (title + avatar cluster).
            padding: const EdgeInsets.only(top: 28),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.boldonse(
                color: const Color(0xFFDFE7E9),
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 112,
          height: 110,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 6,
                right: 0,
                child: CircleAvatar(
                  radius: 39.5,
                  backgroundColor: const Color(0x33FFFFFF),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.boldonse(
                            fontSize: 20,
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
                right: 4,
                top: 56,
                child: InkWell(
                  onTap: isLoading ? null : _pickAndUploadImage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xCC0E8EA4),
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 18,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 16,
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
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xF2FFFFFF),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly ? _inputFillReadOnly : _inputFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 11,
        ),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(
          minHeight: 36,
          minWidth: 44,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: _inputBorder, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: _inputBorderFocused, width: 1.1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: _inputBorder),
        ),
      ),
    );
  }

  Widget _footMetricChip(String value) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: GoogleFonts.boldonse(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }
}
