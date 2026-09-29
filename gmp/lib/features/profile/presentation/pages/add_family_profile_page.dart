import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  DateTime? _dob;
  String _sizeUnit = 'US';
  String? _abnormality;
  Uint8List? _imageBytes;
  String _imageFileName = 'family.jpg';
  bool _submitted = false;

  static const _fieldFill = Color(0x33000000);
  static const _fieldText = Color(0xFFDFE7E9);
  static const _fieldBorder = Color(0x66FFFFFF);
  static const _radius = 100.0;
  static const _saveBtnBg = Color(0xFFE8E8E8);
  static const _saveBtnFg = Color(0xFF3A3A3A);
  static const _sheetTeal = Color(0xFF0A4A52);

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
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _sizeUnits.length; i++) ...[
                ListTile(
                  title: Text(
                    _sizeUnits[i],
                    style: GoogleFonts.montserrat(
                      color: _sheetTeal,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  trailing: _sizeUnit == _sizeUnits[i]
                      ? const Icon(Icons.check, color: _sheetTeal)
                      : null,
                  onTap: () => Navigator.pop(ctx, _sizeUnits[i]),
                ),
                if (i < _sizeUnits.length - 1)
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
              ],
            ],
          ),
        );
      },
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
                            style: GoogleFonts.montserrat(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_abnormalities[i] != 'No Abnormality')
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.black.withValues(alpha: 0.55),
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

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: _fieldBorder, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _fieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
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
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _fieldBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: hasValue
                          ? _fieldText
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
        width: 72,
        height: 72,
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
                        size: 34,
                      )
                    : null,
              ),
            ),
            Positioned(
              left: -2,
              bottom: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0CADC5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 14,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 18),
                                  child: ChevronScreenBackButton(
                                    iconColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
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
                                _fieldLabel('Full Name'),
                                TextField(
                                  controller: _fullName,
                                  focusNode: _fullNameFocus,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (_) =>
                                      _nickNameFocus.requestFocus(),
                                  style: GoogleFonts.montserrat(
                                    color: _fieldText,
                                    fontSize: 15,
                                  ),
                                  decoration: _fieldDecoration(
                                    hint: 'Jane Doe',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _fieldLabel('Nick Name'),
                                TextField(
                                  controller: _nickName,
                                  focusNode: _nickNameFocus,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (_) => _nickNameFocus.unfocus(),
                                  style: GoogleFonts.montserrat(
                                    color: _fieldText,
                                    fontSize: 15,
                                  ),
                                  decoration: _fieldDecoration(hint: 'Jane'),
                                ),
                                const SizedBox(height: 20),
                                _fieldLabel('DOB'),
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
                                _fieldLabel('Add Size'),
                                TextField(
                                  controller: _size,
                                  focusNode: _sizeFocus,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  style: GoogleFonts.montserrat(
                                    color: _fieldText,
                                    fontSize: 15,
                                  ),
                                  decoration: _fieldDecoration(
                                    hint: 'Example: 11',
                                    suffix: GestureDetector(
                                      onTap: _pickSizeUnit,
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 14,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _sizeUnit,
                                              style: GoogleFonts.montserrat(
                                                color: _fieldText,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: _fieldText.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _fieldLabel(
                                  'Do they have any foot abnormality?',
                                ),
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
                                SizedBox(
                                  height: 52,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitted ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _saveBtnBg,
                                      foregroundColor: _saveBtnFg,
                                      disabledBackgroundColor: _saveBtnBg
                                          .withValues(alpha: 0.7),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                    child: _submitted
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _saveBtnFg,
                                            ),
                                          )
                                        : Text(
                                            'Save Profile',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
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
