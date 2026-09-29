import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../profile_screen_system_ui.dart';

class AddFamilyProfilePage extends StatefulWidget {
  final String accessToken;
  final String relation;

  const AddFamilyProfilePage({
    super.key,
    required this.accessToken,
    required this.relation,
  });

  @override
  State<AddFamilyProfilePage> createState() => _AddFamilyProfilePageState();
}

class _AddFamilyProfilePageState extends State<AddFamilyProfilePage> {
  final _fullName = TextEditingController();
  final _nickName = TextEditingController();
  final _size = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _nickNameFocus = FocusNode();
  final _sizeFocus = FocusNode();
  final GlobalKey _sizeUnitKey = GlobalKey();

  DateTime? _dob;
  String _sizeUnit = 'US';
  String? _abnormality;
  Uint8List? _imageBytes;
  String _imageFileName = 'family.jpg';
  bool _submitted = false;

  static const _fieldText = Color(0xF2FFFFFF);
  static const _saveBtnTeal = Color(0xFF12899B);
  static const _saveBtnBorder = Color(0xFF09E0FF);
  static const _infoIconAsset = 'assets/images/icons/profile/info.svg';

  static const _sizeUnits = ['US', 'UK', 'EU'];
  static const _abnormalities = [
    'No Abnormality',
    'Flat Foot',
    'Wide Foot',
    'Narrow Foot',
    'High Arches',
  ];

  @override
  void dispose() {
    _fullName.dispose();
    _nickName.dispose();
    _size.dispose();
    _fullNameFocus.dispose();
    _nickNameFocus.dispose();
    _sizeFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name.isNotEmpty ? picked.name : 'family.jpg';
    });
  }

  Future<void> _pickDob() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _pickSizeUnit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final anchorContext = _sizeUnitKey.currentContext;
    if (anchorContext == null) return;

    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    // White menu under the US / chevron control (Figma-style).
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        Offset(topLeft.dx - 8, bottomRight.dy + 4),
        Offset(bottomRight.dx + 12, bottomRight.dy + 4),
      ),
      Offset.zero & overlay.size,
    );

    final options =
        _sizeUnits.where((unit) => unit != _sizeUnit).toList(growable: false);

    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 72, maxWidth: 96),
      items: [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<String>(
            value: options[i],
            height: 40,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 80,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: BoxDecoration(
                  border: i < options.length - 1
                      ? const Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  options[i],
                  textAlign: TextAlign.left,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF2C2C2C),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (selected != null && mounted) {
      setState(() => _sizeUnit = selected);
    }
  }

  Future<void> _pickAbnormality() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _abnormalities.length; i++) ...[
                InkWell(
                  onTap: () => Navigator.pop(ctx, _abnormalities[i]),
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: i == _abnormalities.length - 1
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _abnormalities[i],
                            textAlign: TextAlign.left,
                            style: GoogleFonts.montserrat(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_abnormalities[i] != 'No Abnormality')
                          SvgPicture.asset(
                            _infoIconAsset,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.55),
                              BlendMode.srcIn,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (i < _abnormalities.length - 1)
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
              ],
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _abnormality = selected);
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _fullName.text.trim();
    if (name.length < 2) {
      await showAppFeedbackAlert(
        context,
        message: 'Enter a valid full name',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (_dob == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Select date of birth',
        type: AppFeedbackType.warning,
      );
      return;
    }
    setState(() => _submitted = true);
    // API still requires gender; design omits it — default until API supports optional.
    context.read<ProfileBloc>().add(
          FamilyMemberAddRequested(
            accessToken: widget.accessToken,
            name: name,
            relation: widget.relation,
            gender: 'female',
            dateOfBirth: _dob!,
            imageBytes: _imageBytes,
            imageFileName: _imageBytes == null ? null : _imageFileName,
          ),
        );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
    );
  }

  /// Same glass field shell as [EditProfilePage].
  Widget _glassFieldShell({required Widget child}) {
    const radius = BorderRadius.all(Radius.circular(100));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _glassInputDecoration({Widget? suffixIcon}) {
    const radius = BorderRadius.all(Radius.circular(100));
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 44),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1,
        ),
      ),
      disabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
    String? hint,
    Widget? suffix,
    TextStyle? style,
  }) {
    final valueStyle = style ??
        GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _fieldText,
        );
    return _glassFieldShell(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        style: valueStyle,
        decoration: _glassInputDecoration(suffixIcon: suffix).copyWith(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: valueStyle.fontSize ?? 16,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  Widget _tapField({
    required String value,
    required String hint,
    required Widget suffix,
    required VoidCallback onTap,
  }) {
    final hasValue = value.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: _glassFieldShell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hasValue ? value : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.montserrat(
                        color: hasValue
                            ? _fieldText
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                suffix,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                backgroundImage:
                    _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                child: _imageBytes == null
                    ? Icon(
                        Icons.person_outline,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 26,
                      )
                    : null,
              ),
            ),
            Positioned(
              left: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF0CADC5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final statusTop = MediaQuery.paddingOf(context).top;
    final dobLabel =
        _dob == null ? '' : DateFormat('dd/MM/yyyy').format(_dob!);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (!_submitted) return;
        if (state is ProfileLoaded) {
          if (!mounted) return;
          Navigator.of(context).pop();
        } else if (state is ProfileError) {
          setState(() => _submitted = false);
          await showAppFeedbackAlert(
            context,
            message: userFacingFamilyProfileError(state.message),
            type: AppFeedbackType.failure,
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: kProfileGradientHeaderSystemUi,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(22),
                        ),
                        image: const DecorationImage(
                          image: AssetImage(BgTheme.backgroundImageAsset),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              ArticleStyleHeaderInsets.titleLeftInsetOf(
                                  context),
                              statusTop + 16,
                              ArticleStyleHeaderInsets.headerRightInsetOf(
                                  context),
                              0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const ChevronScreenBackButton(
                                  iconColor: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Add Profile',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.boldonse(
                                      color: const Color(0xFFDFE7E9),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                _buildAvatar(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                24 + keyboardInset.clamp(0.0, 24.0),
                              ),
                              children: [
                                _buildLabel('Full Name'),
                                const SizedBox(height: 6),
                                _profileField(
                                  controller: _fullName,
                                  focusNode: _fullNameFocus,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (_) =>
                                      _nickNameFocus.requestFocus(),
                                  hint: 'Jane Doe',
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('Nick Name'),
                                const SizedBox(height: 6),
                                _profileField(
                                  controller: _nickName,
                                  focusNode: _nickNameFocus,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (_) => _nickNameFocus.unfocus(),
                                  hint: 'Jane',
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('DOB'),
                                const SizedBox(height: 6),
                                _tapField(
                                  value: dobLabel,
                                  hint: 'dd/mm/yyyy',
                                  suffix: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: _fieldText.withValues(alpha: 0.9),
                                  ),
                                  onTap: _pickDob,
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('Add Size'),
                                const SizedBox(height: 6),
                                _profileField(
                                  controller: _size,
                                  focusNode: _sizeFocus,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  hint: 'Example: 11',
                                  style: GoogleFonts.boldonse(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.0,
                                  ),
                                  suffix: GestureDetector(
                                    key: _sizeUnitKey,
                                    onTap: _pickSizeUnit,
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _sizeUnit,
                                            style: GoogleFonts.boldonse(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildLabel(
                                  'Do they have any foot abnormality?',
                                ),
                                const SizedBox(height: 6),
                                _tapField(
                                  value: _abnormality ?? '',
                                  hint: 'Example: Wide Foot',
                                  suffix: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _fieldText.withValues(alpha: 0.9),
                                  ),
                                  onTap: _pickAbnormality,
                                ),
                                const SizedBox(height: 36),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _submitted ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: _saveBtnTeal,
                                      disabledBackgroundColor: Colors.white,
                                      disabledForegroundColor: _saveBtnTeal,
                                      elevation: 2,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.10,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 48,
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(210, 48),
                                      tapTargetSize:
                                          MaterialTapTargetSize.padded,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        side: const BorderSide(
                                          color: _saveBtnBorder,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: _submitted
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _saveBtnTeal,
                                            ),
                                          )
                                        : Text(
                                            'Save Profile',
                                            style: GoogleFonts.boldonse(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: _saveBtnTeal,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const DashboardLinkedBottomNav(selectedTabIndex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
