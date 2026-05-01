import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/gradient_page_shell.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';

class ProfileCompletionPage extends StatefulWidget {
  final String mobile;

  const ProfileCompletionPage({
    super.key,
    required this.mobile,
  });

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;

  final List<Map<String, dynamic>> _genders = [
    {'value': 'male', 'label': 'Male', 'icon': Icons.male},
    {'value': 'female', 'label': 'Female', 'icon': Icons.female},
    {'value': 'other', 'label': 'Other', 'icon': Icons.transgender},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    // Users must be at least 18 years old
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime(now.year - 18);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool get _isFormValid {
    return _nameController.text.trim().length >= 2 &&
        _selectedDate != null &&
        _selectedGender != null;
  }

  Future<Map<String, dynamic>?> _getLocationIfAllowed() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested != LocationPermission.whileInUse && requested != LocationPermission.always) return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      // Try server reverse geocode — backend returns { data: { location: { displayName, ... } } }
      try {
        final uri = Uri.parse(ApiEndpoints.geocodeReverse(
          pos.latitude,
          pos.longitude,
        ));
        final resp = await http.get(
          uri,
          headers: const {'Accept': 'application/json'},
        );
        if (resp.statusCode == 200 && resp.body.isNotEmpty) {
          String? displayAddr;
          try {
            final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
            final data = decoded['data'];
            if (data is Map && data['location'] is Map) {
              final loc = data['location'] as Map<String, dynamic>;
              final dn = loc['displayName'];
              if (dn is String && dn.trim().isNotEmpty) {
                displayAddr = dn.trim();
              }
            }
          } catch (_) {
            // ignore parse errors — still return coordinates
          }
          return {
            'lat': pos.latitude,
            'lng': pos.longitude,
            if (displayAddr != null) 'address': displayAddr,
          };
        }
      } catch (_) {
        // ignore reverse geocode failures — return coords
      }
      return {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      return null;
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select your date of birth',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (_selectedGender == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select your gender',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final location = await _getLocationIfAllowed();

    if (!mounted) return;
    context.read<AuthBloc>().add(AuthCompleteProfile(
      mobile: widget.mobile,
      name: _nameController.text.trim(),
      dateOfBirth: _selectedDate!,
      gender: _selectedGender!,
      location: location,
    ));
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Name must be less than 100 characters';
    }
    // Only allow alphabets and spaces (no digits or special characters)
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can contain only letters and spaces';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthProfileCompleted || state is AuthAuthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const CustomerDashboardPage(),
            ),
            (route) => false,
          );
        } else if (state is AuthError) {
          await showAppFeedbackAlert(
            context,
            message: state.message,
            type: AppFeedbackType.failure,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          
          return GradientPageShell(
            appBar: buildGradientBackOnlyAppBar(
              onBack: () => Navigator.pop(context),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPaddingOf(context),
                  vertical: 12,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          AppAssets.appLogo,
                          width: Responsive.maxLogoSizeOf(context, 0.22),
                          height: Responsive.maxLogoSizeOf(context, 0.22),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      Center(
                        child: Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 28),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Center(
                        child: Text(
                          'Tell us a bit about yourself',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onGradientBody,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Form Card
                      Container(
                        padding: EdgeInsets.all(Responsive.horizontalPaddingOf(context)),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Input
                            const Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                hintStyle: TextStyle(color: AppColors.textTertiary),
                                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textTertiary),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: _validateName,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 24),
                            
                            // Date of Birth
                            const Text(
                              'Date of Birth',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _selectedDate != null
                                      ? Border.all(color: AppColors.primary, width: 2)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: _selectedDate != null
                                          ? AppColors.primary
                                          : AppColors.textTertiary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedDate == null
                                            ? 'Select your date of birth'
                                            : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.w400,
                                          color: _selectedDate == null
                                              ? AppColors.textTertiary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (_selectedDate != null)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Gender Selection
                            const Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: _genders.map((gender) {
                                final isSelected = _selectedGender == gender['value'];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: gender != _genders.last ? 12 : 0,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedGender = gender['value'];
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryLight
                                              : AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              gender['icon'],
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textTertiary,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              gender['label'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Complete Profile Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isFormValid ? _completeProfile : null,
                          icon: isLoading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                                  ),
                                )
                              : const Text(
                                  'Complete Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                            disabledForegroundColor: AppColors.textOnPrimary.withOpacity(0.65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: _isFormValid ? 2 : 0,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

