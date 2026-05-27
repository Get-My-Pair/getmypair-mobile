import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/home/presentation/pages/select_location_page.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/features/profile/domain/usecases/get_user_profile.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/service_flow_article.dart';
import '../utils/service_flow_layout.dart';
import '../widgets/service_flow_pickup_pill.dart';
import 'request_summary_page.dart';
import 'select_address_page.dart';

/// Maintenance subscription plan shown when user selects Maintenance service.
class MaintenancePlanData {
  final String id;
  final String label;
  final int priceRupees;

  const MaintenancePlanData({
    required this.id,
    required this.label,
    required this.priceRupees,
  });
}

class ServiceSelectionPage extends StatefulWidget {
  final List<ServiceFlowArticle> selectedArticles;
  final List<String>? allowedServiceTypes;
  final String? flowPageTitle;

  /// Single-article entry (e.g. from article rack).
  ServiceSelectionPage({
    super.key,
    required String articleId,
    this.allowedServiceTypes,
    String? articleName,
    String? articleImageUrl,
    this.flowPageTitle,
  }) : selectedArticles = [
          ServiceFlowArticle(
            id: articleId,
            name: articleName ?? '',
            imageUrl: articleImageUrl ?? '',
          ),
        ];

  ServiceSelectionPage.multi({
    super.key,
    required this.selectedArticles,
    this.allowedServiceTypes,
    this.flowPageTitle,
  }) : assert(selectedArticles.length > 0);

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  static const BorderRadius _repairFlowPanelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const int kMaxProofImages = 5;
  static const int kMaxProofVideos = 3;
  static const int kRepairEstimateRupees = 1000;
  static const int kWashEstimateRupees = 300;

  static const List<MaintenancePlanData> _maintenancePlans = [
    MaintenancePlanData(id: '1m', label: '1 month', priceRupees: 299),
    MaintenancePlanData(id: '3m', label: '3 months', priceRupees: 999),
    MaintenancePlanData(id: '6m', label: '6 months', priceRupees: 1500),
  ];

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Address> _addresses = const [];
  Address? _selectedAddress;

  ServiceOptionData? _selectedService;
  MaintenancePlanData? _selectedMaintenancePlan;
  int _repairStep = 0;
  bool _homePickup = true;
  bool _pickupModeChosen = false;
  bool _showRepairStep0FieldErrors = true;
  final FocusNode _problemFocusNode = FocusNode();
  int _selectedPickupDay = 0;
  int _selectedPickupSlot = -1;
  /// When user picks a place on the map for [cobbler_nearby], shown on the summary.
  String? _cobblerNearbyLocationSummary;
  final TextEditingController _problemController = TextEditingController();

  final List<XFile> _proofImages = [];
  final List<XFile> _proofVideos = [];
  final ImagePicker _picker = ImagePicker();

  String get _singleFlowType {
    if (_visibleOptions.isEmpty) return 'repair';
    return _visibleOptions.first.value;
  }

  String get _issuePrompt {
    switch (_singleFlowType) {
      case 'maintenance':
        return 'Please describe the maintenance needed for your footwear';
      case 'wash':
        return 'Please describe the cleaning needed for your footwear';
      default:
        return 'Please describe the problem with your footwear';
    }
  }

  String get _issueHint {
    switch (_singleFlowType) {
      case 'maintenance':
        return 'Type maintenance details';
      case 'wash':
        return 'Type wash details';
      default:
        return 'Type Here';
    }
  }

  String get _uploadPrompt {
    switch (_singleFlowType) {
      case 'maintenance':
        return 'Upload photos to show current condition';
      case 'wash':
        return 'Upload photos to show dirt/stains';
      default:
        return 'Upload photos to show us the problem';
    }
  }

  List<DateTime> get _pickupDays {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List.generate(3, (index) => start.add(Duration(days: index)));
  }

  List<String> get _pickupDayLabels =>
      _pickupDays.map((d) => '${d.day}${_dayOrdinal(d.day)} ${DateFormat('EEEE').format(d)}').toList();

  List<DateTime> get _pickupSlotDateTimes {
    final selectedDay = _pickupDays[_selectedPickupDay.clamp(0, _pickupDays.length - 1)];
    final now = DateTime.now();
    final isToday = selectedDay.year == now.year &&
        selectedDay.month == now.month &&
        selectedDay.day == now.day;

    DateTime base;
    if (isToday) {
      final roundedMinutes = now.minute < 30 ? 30 : 60;
      base = DateTime(now.year, now.month, now.day, now.hour, 0).add(Duration(minutes: roundedMinutes));
    } else {
      base = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 9, 0);
    }
    return List.generate(9, (index) => base.add(Duration(minutes: 30 * index)));
  }

  List<String> get _pickupSlotLabels =>
      _pickupSlotDateTimes.map((d) => DateFormat('h:mm a').format(d)).toList();

  String _dayOrdinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  static const List<ServiceOptionData> _options = [
    ServiceOptionData(
      value: 'repair',
      title: 'Repair',
      subtitle: 'Fix soles, stitches, tears',
      icon: Icons.build_outlined,
    ),
    ServiceOptionData(
      value: 'maintenance',
      title: 'Maintenance',
      subtitle: 'Polish, protect, refresh',
      icon: Icons.handyman_outlined,
    ),
    ServiceOptionData(
      value: 'wash',
      title: 'Wash',
      subtitle: 'Deep clean and deodorize',
      icon: Icons.local_laundry_service_outlined,
    ),
    ServiceOptionData(
      value: 'donate',
      title: 'Donate',
      subtitle: 'Give your pair a second life',
      icon: Icons.volunteer_activism_outlined,
    ),
    ServiceOptionData(
      value: 'dispose',
      title: 'Dispose',
      subtitle: 'Responsible recycling',
      icon: Icons.delete_outline,
    ),
  ];

  List<ServiceOptionData> get _visibleOptions {
    final allowed = widget.allowedServiceTypes;
    if (allowed == null || allowed.isEmpty) return _options;
    final allowedSet = allowed.map((e) => e.trim().toLowerCase()).toSet();
    return _options.where((o) => allowedSet.contains(o.value)).toList();
  }

  bool get _isSingleServiceFlow => _visibleOptions.length == 1;

  bool get _repairStep0ProblemValid =>
      _problemController.text.trim().isNotEmpty;

  bool get _repairStep0PhotosValid => _proofImages.isNotEmpty;

  bool get _repairStep0PickupValid => _pickupModeChosen;

  bool get _repairStep0Complete =>
      _repairStep0ProblemValid &&
      _repairStep0PhotosValid &&
      _repairStep0PickupValid;

  @override
  void initState() {
    super.initState();
    if (_isSingleServiceFlow) {
      _selectedService = _visibleOptions.first;
    }
    _problemController.addListener(_onRepairStep0FieldsChanged);
    _problemFocusNode.addListener(_onProblemFocusChanged);
    _load();
  }

  void _onRepairStep0FieldsChanged() {
    if (mounted) setState(() {});
  }

  void _onProblemFocusChanged() {
    if (_problemFocusNode.hasFocus || !mounted) return;
    if (_problemController.text.trim().isEmpty) {
      setState(() => _showRepairStep0FieldErrors = true);
    }
  }

  @override
  void dispose() {
    _problemController.removeListener(_onRepairStep0FieldsChanged);
    _problemFocusNode.removeListener(_onProblemFocusChanged);
    _problemFocusNode.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<bool> _validateRepairStep0() async {
    if (!_repairStep0Complete) {
      setState(() => _showRepairStep0FieldErrors = true);
      return false;
    }
    return true;
  }

  Widget _repairStep0InlineError(String message, double layoutScale) {
    return Padding(
      padding: EdgeInsets.only(top: 4 * layoutScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: (16 * layoutScale).clamp(14.0, 18.0),
            color: const Color(0xFFB00020),
          ),
          SizedBox(width: 4 * layoutScale),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                color: const Color(0xFFB00020),
                fontSize: (12 * layoutScale).clamp(10.0, 13.0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _validateRepairStep1() async {
    if (_selectedPickupSlot < 0) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a pickup time slot',
        type: AppFeedbackType.warning,
      );
      return false;
    }
    if (_selectedAddress == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a pickup address',
        type: AppFeedbackType.warning,
      );
      return false;
    }
    return true;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _error = 'Please sign in again';
          _loading = false;
        });
      },
      (token) async {
        try {
          final profile = await sl<GetUserProfile>().call(token);
          if (!mounted) return;
          setState(() {
            _addresses = profile.addresses;
            _selectedAddress = profile.addresses.isNotEmpty
                ? profile.addresses.first
                : null;
            if (_isSingleServiceFlow && _selectedService == null) {
              _selectedService = _visibleOptions.first;
            }
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
            _loading = false;
          });
        }
      },
    );
  }

  Future<void> _pickAddress() async {
    final picked = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) =>
            SelectAddressPage(selectedAddressId: _selectedAddress?.id),
      ),
    );

    if (picked != null && mounted) setState(() => _selectedAddress = picked);
  }

  Future<void> _pickImages() async {
    if (_proofImages.length >= kMaxProofImages) return;
    try {
      final list = await _picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _showRepairStep0FieldErrors = true);
        return;
      }
      setState(() {
        for (final f in list) {
          if (_proofImages.length >= kMaxProofImages) break;
          _proofImages.add(f);
        }
      });
    } catch (_) {
      final single = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (single != null && _proofImages.length < kMaxProofImages) {
        setState(() => _proofImages.add(single));
      } else if (single == null) {
        setState(() => _showRepairStep0FieldErrors = true);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_proofVideos.length >= kMaxProofVideos) return;
    final v = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (v != null && mounted) {
      setState(() {
        if (_proofVideos.length < kMaxProofVideos) {
          _proofVideos.add(v);
        }
      });
    }
  }

  Future<void> _takePicture() async {
    if (_proofImages.length >= kMaxProofImages) return;
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (photo != null) {
      setState(() {
        if (_proofImages.length < kMaxProofImages) {
          _proofImages.add(photo);
        }
      });
    } else {
      setState(() => _showRepairStep0FieldErrors = true);
    }
  }

  void _removeImage(int index) {
    setState(() => _proofImages.removeAt(index));
  }

  void _removeVideo(int index) {
    setState(() => _proofVideos.removeAt(index));
  }

  void _onSelectService(ServiceOptionData opt) {
    setState(() {
      _selectedService = opt;
      _repairStep = 0;
      if (opt.value != 'maintenance') {
        _selectedMaintenancePlan = null;
      }
    });
  }

  Future<void> _openNearbyCobblers() async {
    if (_submitting || !mounted) return;
    ProfileBloc profileBloc;
    try {
      profileBloc = BlocProvider.of<ProfileBloc>(context);
    } catch (_) {
      profileBloc = sl<ProfileBloc>();
    }
    final selectedLocation = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SelectLocationPage(
          profileBloc: profileBloc,
        ),
      ),
    );
    if (!mounted || selectedLocation == null || selectedLocation.trim().isEmpty) {
      return;
    }
    setState(() => _cobblerNearbyLocationSummary = selectedLocation.trim());
    await _submit();
  }

  void _selectPickupMode(bool homePickup) {
    if (_submitting || !mounted) return;
    setState(() {
      _homePickup = homePickup;
      _pickupModeChosen = true;
    });
  }

  Future<void> _onRepairStepZeroNext() async {
    if (_submitting || !mounted) return;
    if (!await _validateRepairStep0()) return;
    if (_homePickup) {
      setState(() => _repairStep = 1);
      return;
    }
    await _openNearbyCobblers();
  }

  int? _resolvedEstimatedRupees() {
    final s = _selectedService?.value;
    switch (s) {
      case 'repair':
        return kRepairEstimateRupees;
      case 'wash':
        return kWashEstimateRupees;
      case 'maintenance':
        return (_selectedMaintenancePlan ?? _maintenancePlans.first).priceRupees;
      case 'donate':
      case 'dispose':
        return 0;
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_isSingleServiceFlow && _repairStep == 1) {
      if (!await _validateRepairStep1()) return;
    }
    if (_selectedService == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a service type',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (_selectedService!.value == 'maintenance' &&
        _selectedMaintenancePlan == null &&
        !_isSingleServiceFlow) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a maintenance plan',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (_homePickup) {
      if (!await _validateRepairStep1()) return;
    } else if (_selectedAddress == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a pickup address',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final est = _resolvedEstimatedRupees();
    if (est == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Could not resolve price for this service',
        type: AppFeedbackType.failure,
      );
      return;
    }

    setState(() => _submitting = true);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RequestSummaryPage(
          articleIds:
              widget.selectedArticles.map((a) => a.id).toList(growable: false),
          service: _selectedService!,
          address: _selectedAddress!,
          proofImages: List<XFile>.from(_proofImages),
          proofVideos: List<XFile>.from(_proofVideos),
          estimatedCostRupees: est,
          problemDescription: _problemController.text.trim().isEmpty
              ? null
              : _problemController.text.trim(),
          pickupModeLabel: _homePickup ? 'Home Pickup' : 'Cobblers Nearby',
          pickupScheduleLabel: !_homePickup && _cobblerNearbyLocationSummary != null
              ? _cobblerNearbyLocationSummary
              : _selectedPickupSlot < 0
                  ? null
                  : '${_pickupDayLabels[_selectedPickupDay.clamp(0, _pickupDayLabels.length - 1)]}, ${_pickupSlotLabels[_selectedPickupSlot.clamp(0, _pickupSlotLabels.length - 1)]}',
          maintenancePlan: _selectedService!.value == 'maintenance'
              ? (_selectedMaintenancePlan ?? _maintenancePlans.first)
              : null,
          homePickup: _homePickup,
          requestedPickupAt: _homePickup &&
                  _selectedPickupSlot >= 0 &&
                  _pickupSlotDateTimes.isNotEmpty
              ? _pickupSlotDateTimes[_selectedPickupSlot
                  .clamp(0, _pickupSlotDateTimes.length - 1)]
              : null,
        ),
      ),
    );
    if (mounted) setState(() => _submitting = false);
    if (!mounted) return;
    if (created == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);

    if (_isSingleServiceFlow) {
      return _buildRepairOnlyPage();
    }

    if (_loading) {
      return GradientPageShell(
        appBar: buildGradientAppBar(
          title: 'Select Service',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
          automaticallyImplyLeading: false,
          centerTitle: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GradientPageShell(
      appBar: buildGradientAppBar(
        title: _isSingleServiceFlow
            ? (widget.flowPageTitle ?? 'RepairMyPair')
            : 'Select Service',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: _submitting
              ? null
              : () {
                  if (_isSingleServiceFlow && _repairStep > 0) {
                    setState(() => _repairStep -= 1);
                    return;
                  }
                  Navigator.pop(context);
                },
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _submitting ? null : _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
          const Text(
            'What do you need today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose one service to create a request.',
            style: TextStyle(color: AppColors.onGradientBody, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visibleOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (_, i) {
              final opt = _visibleOptions[i];
              final selected = _selectedService?.value == opt.value;
              return _ServiceCard(
                option: opt,
                selected: selected,
                onTap: _submitting ? null : () => _onSelectService(opt),
              );
            },
          ),
          if (_selectedService != null) ...[
            const SizedBox(height: 22),
            _sectionTitle(
              'Request proof (optional)',
              'Photos & videos help us assess your pair.',
            ),
            const SizedBox(height: 10),
            _proofImagesCard(),
            const SizedBox(height: 12),
            _proofVideosCard(),
            const SizedBox(height: 18),
            ..._buildPricingBlocks(),
          ],
          const SizedBox(height: 18),
          _addressCard(),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting || _selectedService == null
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.textOnPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Continue to summary',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairOnlyPage() {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  kServiceFlowTopInset,
                  horizontalInset,
                  0,
                ),
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: _repairFlowPanelRadius,
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _repairFlowPanelRadius,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF11999E),
                            ),
                          )
                        : _buildRepairSingleServicePanel(context),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Offstage(
              offstage: MediaQuery.viewInsetsOf(context).bottom > 0,
              child: const DashboardLinkedBottomNav(selectedTabIndex: 1),
            ),
          ),
        ],
      ),
    );
  }

  /// Matches [DonateMyPairDetailsPage] shell: fixed viewport, scaled controls; step 2 scrolls if needed.
  Widget _buildRepairSingleServicePanel(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final navH = dashboardLinkedBottomNavStackHeight(context);
    final layoutScale = serviceFlowLayoutScale(context, uiScale: uiScale);
    final fs = (16 * layoutScale).clamp(12.0, 16.0);
    final titleFs = (24 * layoutScale).clamp(17.0, 24.0);
    final pillH = (48 * layoutScale).clamp(40.0, 52.0);
    final pillFs = (14 * layoutScale).clamp(11.0, 14.0);
    final actionFs = (14 * layoutScale).clamp(11.0, 14.0);
    final iconSz = (58 * layoutScale).clamp(36.0, 58.0);
    final uploadTapH = (96 * layoutScale).clamp(70.0, 112.0);
    final effectiveUploadH = uploadTapH;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final title = widget.flowPageTitle ?? 'RepairMyPair';
    final selectedArticles = widget.selectedArticles;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        navH + 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _submitting
                    ? null
                    : () {
                        if (_repairStep > 0) {
                          setState(() => _repairStep -= 1);
                          return;
                        }
                        Navigator.pop(context);
                      },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF062F35),
                  size: (24 * layoutScale).clamp(18.0, 24.0),
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 26, height: 26),
              ),
              SizedBox(width: 6 * layoutScale),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.boldonse(
                    color: const Color(0xFF062F35),
                    fontSize: titleFs,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * layoutScale),
          if (_repairStep == 0 && selectedArticles.isNotEmpty) ...[
            _buildSelectedFootwearHeader(
              selectedArticles,
              layoutScale: layoutScale,
              fontSize: fs,
              iconSize: iconSz,
            ),
            SizedBox(height: 10 * layoutScale),
          ],
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8 * layoutScale),
              child: Text(
                _error!,
                style: TextStyle(
                  color: const Color(0xFFB00020),
                  fontSize: (13 * layoutScale).clamp(10.0, 13.0),
                ),
              ),
            ),
          if (_repairStep == 0) ...[
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: keyboardInset + 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _issuePrompt,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF062F35),
                        fontSize: fs,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4 * layoutScale),
                    TextField(
                      controller: _problemController,
                      focusNode: _problemFocusNode,
                      keyboardType: TextInputType.multiline,
                      minLines: 4,
                      maxLines: 8,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF062F35),
                        fontSize: fs,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: _issueHint,
                        hintStyle: GoogleFonts.montserrat(
                          color: const Color(0xFFABABAB),
                          fontSize: fs,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.10),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: (12 * layoutScale).clamp(8.0, 14.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            width: 1,
                            color: Color(0x7F12899B),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            width: 1,
                            color: Color(0x7F12899B),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 1.2,
                            color: const Color(0xFF12899B),
                          ),
                        ),
                      ),
                    ),
                    if (_showRepairStep0FieldErrors && !_repairStep0ProblemValid)
                      _repairStep0InlineError(
                        'Please fill out this field.',
                        layoutScale,
                      ),
                    SizedBox(height: 8 * layoutScale),
                    Text(
                      _uploadPrompt,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF062F35),
                        fontSize: fs,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4 * layoutScale),
                    SizedBox(
                      height: effectiveUploadH,
                      child: InkWell(
                        onTap: _submitting ? null : _pickImages,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 1,
                                color: Color(0x7F12899B),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _submitting ? null : _pickImages,
                                child: Text(
                                  'Upload Photos ',
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF12899B),
                                    fontSize: actionFs,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Text(
                                'or',
                                style: GoogleFonts.boldonse(
                                  color: const Color(0xFFABABAB),
                                  fontSize: actionFs,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: _submitting ? null : _takePicture,
                                child: Text(
                                  ' Take Pictures',
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF12899B),
                                    fontSize: actionFs,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_showRepairStep0FieldErrors && !_repairStep0PhotosValid)
                      _repairStep0InlineError(
                        'Please upload images.',
                        layoutScale,
                      ),
                    if (_proofImages.isNotEmpty) ...[
                      SizedBox(height: 8 * layoutScale),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_proofImages.length}/$kMaxProofImages photo(s) added',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF12899B),
                            fontSize: (12 * layoutScale).clamp(10.0, 13.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 6 * layoutScale),
                      SizedBox(
                        height: (76 * layoutScale).clamp(60.0, 92.0),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _proofImages.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(width: 8 * layoutScale),
                          itemBuilder: (_, i) {
                            final thumb = (72 * layoutScale).clamp(56.0, 88.0);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: thumb,
                                    height: thumb,
                                    child: FutureBuilder(
                                      future: _proofImages[i].readAsBytes(),
                                      builder: (context, snap) {
                                        if (!snap.hasData) {
                                          return Container(
                                            color: const Color(0xFFDFE7E9),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF11999E),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Image.memory(
                                          snap.data!,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Material(
                                    color: const Color(0xFFB00020),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _submitting
                                          ? null
                                          : () => _removeImage(i),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.close,
                                          size: (16 * layoutScale)
                                              .clamp(14.0, 18.0),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    SizedBox(height: 8 * layoutScale),
                    Text(
                      'How would you like to send us your footwear?',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF062F35),
                        fontSize: fs,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 6 * layoutScale),
                    SizedBox(
                      height: pillH,
                      child: Row(
                        children: [
                          Expanded(
                            child: ServiceFlowPickupPill(
                              label: 'Home Pickup',
                              selected:
                                  _pickupModeChosen && _homePickup,
                              height: pillH,
                              fontSize: pillFs,
                              onTap: () => _selectPickupMode(true),
                            ),
                          ),
                          SizedBox(width: 12 * layoutScale),
                          Expanded(
                            child: ServiceFlowPickupPill(
                              label: 'Cobblers Nearby',
                              selected:
                                  _pickupModeChosen && !_homePickup,
                              height: pillH,
                              fontSize: pillFs,
                              onTap: () => _selectPickupMode(false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showRepairStep0FieldErrors && !_repairStep0PickupValid)
                      _repairStep0InlineError(
                        'Please choose an option.',
                        layoutScale,
                      ),
                    if (_repairStep0Complete) ...[
                      SizedBox(height: 10 * layoutScale),
                      Center(
                        child: SizedBox(
                          width: (164 * layoutScale).clamp(132.0, 180.0),
                          height: pillH,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFF0CADC5),
                                  Color(0xFF063239),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed:
                                  _submitting ? null : _onRepairStepZeroNext,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Next',
                                          style: GoogleFonts.boldonse(
                                            color: Colors.white,
                                            fontSize: fs,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(width: 20 * layoutScale),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.white,
                                          size: (16 * layoutScale)
                                              .clamp(13.0, 16.0),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8 * layoutScale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Home Pickup',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: fs,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (_proofImages.isNotEmpty) ...[
                        SizedBox(height: 8 * layoutScale),
                        Text(
                          'Your uploaded photos (${_proofImages.length})',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF4E7F8A),
                            fontSize: (12 * layoutScale).clamp(10.0, 13.0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6 * layoutScale),
                        SizedBox(
                          height: (52 * layoutScale).clamp(44.0, 60.0),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _proofImages.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(width: 6 * layoutScale),
                            itemBuilder: (_, i) {
                              final w =
                                  (48 * layoutScale).clamp(40.0, 56.0);
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: w,
                                  height: w,
                                  child: FutureBuilder(
                                    future: _proofImages[i].readAsBytes(),
                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return Container(
                                          color: const Color(0xFFDFE7E9),
                                        );
                                      }
                                      return Image.memory(
                                        snap.data!,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      SizedBox(height: 8 * layoutScale),
                      Text(
                        'Please choose a time slot from the options below',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF062F35),
                          fontSize: fs,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 20 * layoutScale),
                      Row(
                        children: [
                          Text(
                            _pickupDayLabels[_selectedPickupDay.clamp(
                              0,
                              _pickupDayLabels.length - 1,
                            )],
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF12899B),
                              fontSize: pillFs,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 8 * layoutScale),
                          SvgPicture.asset(
                            'assets/images/calendar.svg',
                            width: (18 * layoutScale).clamp(16.0, 20.0),
                            height: (18 * layoutScale).clamp(16.0, 20.0),
                          ),
                        ],
                      ),
                      SizedBox(height: 14 * layoutScale),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pickupSlotLabels.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14 * layoutScale,
                          mainAxisSpacing: 16 * layoutScale,
                          childAspectRatio: 2.1,
                        ),
                        itemBuilder: (_, index) {
                          final selected = _selectedPickupSlot == index;
                          return InkWell(
                            onTap: _submitting
                                ? null
                                : () => setState(() {
                                      _selectedPickupSlot =
                                          selected ? -1 : index;
                                    }),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                        colors: [
                                          Color(0xFF0CADC5),
                                          Color(0xFF063239),
                                        ],
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : const Color(0xFFDFE7E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  width: 1,
                                  color: selected
                                      ? Colors.transparent
                                      : const Color(0xFF0F6876),
                                ),
                              ),
                              child: Text(
                                _pickupSlotLabels[index],
                                style: GoogleFonts.boldonse(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF12899B),
                                  fontSize: (13 * layoutScale).clamp(11.0, 13.0),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24 * layoutScale),
                      Text(
                        'Pickup Address',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: fs,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 10 * layoutScale),
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          8 * layoutScale,
                          6 * layoutScale,
                          8 * layoutScale,
                          10 * layoutScale,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: (30 * layoutScale).clamp(26.0, 34.0),
                              height: (30 * layoutScale).clamp(26.0, 34.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF11899B),
                                ),
                              ),
                              child: Icon(
                                Icons.home_outlined,
                                color: const Color(0xFF11899B),
                                size: (17 * layoutScale).clamp(14.0, 18.0),
                              ),
                            ),
                            SizedBox(width: 10 * layoutScale),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAddress?.addressLine1
                                                .isNotEmpty ==
                                            true
                                        ? _selectedAddress!.addressLine1
                                        : 'Home',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFF12899B),
                                      fontSize:
                                          (13 * layoutScale).clamp(11.0, 13.0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2 * layoutScale),
                                  Text(
                                    _selectedAddress == null
                                        ? 'No address selected'
                                        : '${_selectedAddress!.addressLine1}, ${_selectedAddress!.city}, ${_selectedAddress!.state}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFF4E7F8A),
                                      fontSize:
                                          (13 * layoutScale).clamp(11.0, 13.0),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8 * layoutScale),
                            InkWell(
                              onTap: _submitting ? null : _pickAddress,
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (10 * layoutScale).clamp(8.0, 12.0),
                                  vertical: (4 * layoutScale).clamp(3.0, 6.0),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11899B),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Change',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize:
                                        (11 * layoutScale).clamp(10.0, 12.0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24 * layoutScale),
                      Center(
                        child: SizedBox(
                          width: (164 * layoutScale).clamp(132.0, 180.0),
                          height: pillH,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFF0CADC5),
                                  Color(0xFF063239),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: _submitting ? null : _submit,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Next',
                                          style: GoogleFonts.boldonse(
                                            color: Colors.white,
                                            fontSize: fs,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(width: 20 * layoutScale),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.white,
                                          size: (16 * layoutScale)
                                              .clamp(13.0, 16.0),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedFootwearHeader(
    List<ServiceFlowArticle> articles, {
    required double layoutScale,
    required double fontSize,
    required double iconSize,
  }) {
    if (articles.length == 1) {
      final article = articles.first;
      final name = article.name.trim();
      if (name.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.boldonse(
                color: const Color(0xFF11899B),
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: 4 * layoutScale),
          LayoutBuilder(
            builder: (context, ac) {
              final imgW = (ac.maxWidth * 0.52).clamp(120.0, 230.0);
              final imgH = (imgW * 96 / 230).clamp(48.0, 96.0);
              return Center(
                child: SizedBox(
                  width: imgW,
                  height: imgH,
                  child: Center(
                    child: article.imageUrl.isEmpty
                        ? Icon(
                            Icons.checkroom_outlined,
                            color: const Color(0xFF8D8D8D),
                            size: iconSize,
                          )
                        : ArticleRackShoeImage(
                            imageUrl: article.imageUrl,
                            width: imgW,
                            height: imgH,
                            fit: BoxFit.contain,
                            placeholder: Icon(
                              Icons.checkroom_outlined,
                              color: const Color(0xFF8D8D8D),
                              size: iconSize,
                            ),
                            errorPlaceholder: Icon(
                              Icons.checkroom_outlined,
                              color: const Color(0xFF8D8D8D),
                              size: iconSize,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    final thumb = (72 * layoutScale).clamp(56.0, 88.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${articles.length} pairs selected',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF11899B),
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 6 * layoutScale),
        SizedBox(
          height: thumb + 22 * layoutScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            separatorBuilder: (_, _) => SizedBox(width: 10 * layoutScale),
            itemBuilder: (_, i) {
              final article = articles[i];
              final label = article.name.trim().isEmpty ? 'Shoe' : article.name.trim();
              return SizedBox(
                width: thumb,
                child: Column(
                  children: [
                    SizedBox(
                      width: thumb,
                      height: thumb,
                      child: article.imageUrl.isEmpty
                          ? Icon(
                              Icons.checkroom_outlined,
                              color: const Color(0xFF8D8D8D),
                              size: iconSize,
                            )
                          : ArticleRackShoeImage(
                              imageUrl: article.imageUrl,
                              width: thumb,
                              height: thumb,
                              fit: BoxFit.contain,
                              placeholder: Icon(
                                Icons.checkroom_outlined,
                                color: const Color(0xFF8D8D8D),
                                size: iconSize,
                              ),
                              errorPlaceholder: Icon(
                                Icons.checkroom_outlined,
                                color: const Color(0xFF8D8D8D),
                                size: iconSize,
                              ),
                            ),
                    ),
                    SizedBox(height: 4 * layoutScale),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFF11899B),
                        fontSize: (12 * layoutScale).clamp(10.0, 12.0),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepairFlowBody(double horizontal) {
    return ListView(
      padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
        if (widget.selectedArticles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSelectedFootwearHeader(
              widget.selectedArticles,
              layoutScale: 1,
              fontSize: 16,
              iconSize: 52,
            ),
          ),
        ],
        if (_repairStep == 0) ...[
          _sectionTitle(
            'Repair details',
            'Describe the problem and upload shoe photos.',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please describe the problem with your footwear',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _problemController,
                  minLines: 2,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Type Here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _proofImagesCard(),
          const SizedBox(height: 12),
          _proofVideosCard(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How would you like to send us your footwear?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _pickupModeChip(
                        label: 'Cobblers Nearby',
                        selected: !_homePickup,
                        onTap: () => _selectPickupMode(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pickupModeChip(
                        label: 'Home Pickup',
                        selected: _homePickup,
                        onTap: () => _selectPickupMode(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _estimationCard(
            title: 'Estimated cost',
            amountRupees: kRepairEstimateRupees,
            subtitle: 'Fixed estimate for repair service',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!await _validateRepairStep0()) return;
                      setState(() => _repairStep = 1);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ] else ...[
          _sectionTitle(
            'Home Pickup',
            'Please choose a time slot from the options below.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_pickupDayLabels.length, (index) {
              final selected = _selectedPickupDay == index;
              return ChoiceChip(
                label: Text(_pickupDayLabels[index]),
                selected: selected,
                onSelected: _submitting
                    ? null
                    : (_) => setState(() {
                        _selectedPickupDay = index;
                        _selectedPickupSlot = -1;
                      }),
              );
            }),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_pickupSlotLabels.length, (index) {
              final selected = _selectedPickupSlot == index;
              return ChoiceChip(
                label: Text(_pickupSlotLabels[index]),
                selected: selected,
                onSelected: _submitting ? null : (_) => setState(() => _selectedPickupSlot = index),
              );
            }),
          ),
          const SizedBox(height: 16),
          _addressCard(),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.textOnPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Continue to summary',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepBadge(String text, bool active) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: active ? AppColors.textOnPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _pickupModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ServiceFlowPickupPill(
      label: label,
      selected: selected,
      onTap: onTap,
      height: 38,
      fontSize: 12.5,
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppColors.onGradientBody),
        ),
      ],
    );
  }

  List<Widget> _buildPricingBlocks() {
    final s = _selectedService!.value;
    if (s == 'repair') {
      return [
        _estimationCard(
          title: 'Estimated cost',
          amountRupees: kRepairEstimateRupees,
          subtitle: 'Fixed estimate for repair service',
        ),
      ];
    }
    if (s == 'wash') {
      return [
        _estimationCard(
          title: 'Estimated cost',
          amountRupees: kWashEstimateRupees,
          subtitle: 'Estimated wash service charge',
        ),
      ];
    }
    if (s == 'maintenance') {
      return [
        _sectionTitle('Choose a plan', 'Select how long you want coverage.'),
        const SizedBox(height: 10),
        ..._maintenancePlans.map((p) {
          final sel = _selectedMaintenancePlan?.id == p.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _submitting
                  ? null
                  : () => setState(() => _selectedMaintenancePlan = p),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: sel ? AppColors.primary : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '₹${p.priceRupees}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: sel ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ];
    }
    if (s == 'donate' || s == 'dispose') {
      return [];
    }
    return [];
  }

  Widget _estimationCard({
    required String title,
    required int amountRupees,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountRupees == 0 ? '₹0' : '₹$amountRupees',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofImagesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Photos',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_proofImages.length}/$kMaxProofImages',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_proofImages.isEmpty)
            Text(
              'Add up to $kMaxProofImages photos of your shoes.',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            )
          else
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _proofImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: FutureBuilder(
                            future: _proofImages[i].readAsBytes(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Image.memory(
                                snap.data!,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Material(
                          color: AppColors.error,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _submitting ? null : () => _removeImage(i),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _submitting || _proofImages.length >= kMaxProofImages
                ? null
                : _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            label: const Text('Add photos'),
          ),
        ],
      ),
    );
  }

  Widget _proofVideosCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.videocam_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Videos',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_proofVideos.length}/$kMaxProofVideos',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._proofVideos.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.movie_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  e.value.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: _submitting ? null : () => _removeVideo(e.key),
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _submitting || _proofVideos.length >= kMaxProofVideos
                ? null
                : _pickVideo,
            icon: const Icon(Icons.video_call_outlined, size: 20),
            label: const Text('Add video'),
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    final hasAddresses = _addresses.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pickup address',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _submitting ? null : _pickAddress,
                child: Text(
                  hasAddresses ? 'Change' : 'Select',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasAddresses)
            Text(
              'No saved addresses found. Please add one in Profile → Saved Addresses.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else if (_selectedAddress == null)
            Text(
              'Select an address to schedule pickup.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAddress!.addressLine1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.pincode}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ServiceOptionData {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const ServiceOptionData({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ServiceCard extends StatelessWidget {
  final ServiceOptionData option;
  final bool selected;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primary : AppColors.border;
    final bg = selected
        ? AppColors.primary.withOpacity(0.08)
        : AppColors.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected ? 2 : 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option.icon,
                    color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.success)
                else
                  const Icon(
                    Icons.radio_button_unchecked,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              option.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
