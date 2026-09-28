import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../domain/entities/user_profile.dart';
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
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  String? _gender;
  DateTime? _dob;
  Uint8List? _imageBytes;
  String _imageFileName = 'family.jpg';
  bool _submitted = false;

  static const _fieldFill = Color(0x2E000000);
  static const _fieldText = Color(0xFFDFE7E9);
  static const _radius = 16.0;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
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
    _nameFocus.unfocus();
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

  Future<void> _pickGender() async {
    _nameFocus.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0B3A4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select gender',
                  style: GoogleFonts.boldonse(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _genderOption(ctx, 'female', 'Female'),
                _genderOption(ctx, 'male', 'Male'),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _gender = selected);
    }
  }

  Widget _genderOption(BuildContext ctx, String value, String label) {
    final active = _gender == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.pop(ctx, value),
        tileColor: Colors.white.withValues(alpha: active ? 0.16 : 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          active ? Icons.check_circle : Icons.circle_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _nameFocus.unfocus();
    final name = _name.text.trim();
    if (name.length < 2) {
      await showAppFeedbackAlert(
        context,
        message: 'Enter a valid name',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (_gender == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Select gender',
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
    context.read<ProfileBloc>().add(
          FamilyMemberAddRequested(
            accessToken: widget.accessToken,
            name: name,
            relation: widget.relation,
            gender: _gender!,
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
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _fieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: _fieldText.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
          height: 54,
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
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
                          : Colors.white.withValues(alpha: 0.55),
                      fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final genderLabel = _gender == 'female'
        ? 'Female'
        : _gender == 'male'
            ? 'Male'
            : '';
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
            resizeToAvoidBottomInset: true,
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(BgTheme.backgroundImageAsset),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        ArticleStyleHeaderInsets.titleLeftInsetOf(context),
                        8,
                        ArticleStyleHeaderInsets.headerRightInsetOf(context),
                        0,
                      ),
                      child: Row(
                        children: [
                          const ChevronScreenBackButton(iconColor: Colors.white),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              familyRelationLabel(widget.relation),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.boldonse(
                                color: const Color(0xFFDFE7E9),
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          20,
                          24,
                          24 + keyboardInset.clamp(0.0, 24.0),
                        ),
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                backgroundImage: _imageBytes != null
                                    ? MemoryImage(_imageBytes!)
                                    : null,
                                child: _imageBytes == null
                                    ? const Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.white,
                                        size: 28,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Profile image',
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _fieldLabel('Name'),
                          TextField(
                            controller: _name,
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            onSubmitted: (_) => _nameFocus.unfocus(),
                            style: GoogleFonts.montserrat(
                              color: _fieldText,
                              fontSize: 16,
                            ),
                            decoration: _fieldDecoration(hint: 'Enter name'),
                          ),
                          const SizedBox(height: 18),
                          _fieldLabel('Gender'),
                          _tapField(
                            value: genderLabel,
                            hint: 'Select gender',
                            suffix: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _fieldText.withValues(alpha: 0.9),
                            ),
                            onTap: _pickGender,
                          ),
                          const SizedBox(height: 18),
                          _fieldLabel('Date of birth'),
                          _tapField(
                            value: dobLabel,
                            hint: 'DD/MM/YYYY',
                            suffix: Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: _fieldText.withValues(alpha: 0.9),
                            ),
                            onTap: _pickDob,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitted ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: _submitted
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Create profile',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }
}
