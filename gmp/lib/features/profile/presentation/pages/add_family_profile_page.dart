import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/bgtheme.dart';
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
  String? _gender;
  DateTime? _dob;
  Uint8List? _imageBytes;
  String _imageFileName = 'family.jpg';
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
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

  @override
  Widget build(BuildContext context) {
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
            message: state.message,
            type: AppFeedbackType.failure,
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: kProfileGradientHeaderSystemUi,
        child: Scaffold(
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
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        const ChevronScreenBackButton(iconColor: Colors.white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            familyRelationLabel(widget.relation),
                            style: GoogleFonts.boldonse(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                        const SizedBox(height: 24),
                        TextField(
                          controller: _name,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          dropdownColor: const Color(0xFF0B3A4A),
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'female',
                              child: Text(
                                'Female',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'male',
                              child: Text(
                                'Male',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _gender = value),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          onTap: _pickDob,
                          tileColor: Colors.white.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            _dob == null
                                ? 'Date of birth'
                                : DateFormat('dd/MM/yyyy').format(_dob!),
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: _submitted ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                              : const Text('Create profile'),
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
    );
  }
}
