import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/home/presentation/pages/select_location_page.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/profile/domain/entities/user_profile.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_state.dart';
import 'package:gmp/features/profile/presentation/pages/saved_addresses_page.dart';
import 'package:gmp/features/profile/domain/usecases/get_user_profile.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../utils/service_flow_article.dart';
import '../utils/service_flow_layout.dart';
import '../widgets/service_flow_pickup_pill.dart';
import 'request_summary_page.dart';
import 'select_address_page.dart';

/// Care option shown on MaintainMyPair / WashMyPair after article selection.
class MaintenancePlanData {
  final String id;
  final String label;
  final String description;
  final int priceRupees;

  const MaintenancePlanData({
    required this.id,
    required this.label,
    this.description = '',
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

class _ServiceSelectionPageState extends State<ServiceSelectionPage>
    with WidgetsBindingObserver {
  static const BorderRadius _repairFlowPanelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );

  static const int kMaxProofImages = 5;
  /// Max photos per RepairMyPair option (camera badge shows n/3).
  static const int kMaxOptionProofImages = 3;
  static const int kMaxProofVideos = 3;
  static const int kRepairEstimateRupees = 1000;
  static const int kWashEstimateRupees = 300;

  static const List<MaintenancePlanData> _maintenancePlans = [
    MaintenancePlanData(
      id: 'protection_conditioning',
      label: 'Protection & Conditioning',
      description:
          'Protect and revive your footwear with hydrophobic weatherproofing, UV shielding, and deep-leather conditioning to keep your shoes soft, vibrant, and dirt-resistant.',
      priceRupees: 299,
    ),
    MaintenancePlanData(
      id: 'surface_care_polishing',
      label: 'Preventive Surface Care & Polishing',
      description:
          'Restore your footwear\'s original shine with material-specific brushing, premium polishing, and precise edge detailing to eliminate buildup and yellowing.',
      priceRupees: 299,
    ),
    MaintenancePlanData(
      id: 'structural_shape',
      label: 'Structural & Shape Maintenance',
      description:
          'Refresh your shoes inside and out with professional steam reshaping, antimicrobial lining sanitization, and factory-fresh lace care.',
      priceRupees: 299,
    ),
    MaintenancePlanData(
      id: 'storage_preservation',
      label: 'Storage & Preservation Prep',
      description:
          'Safeguard your footwear from long-term wear with custom sole protection and humidity-controlled seasonal storage prep.',
      priceRupees: 299,
    ),
  ];

  static const List<MaintenancePlanData> _washPlans = [
    MaintenancePlanData(
      id: 'exterior_surface_deep_clean',
      label: 'Exterior & Surface Deep Cleaning',
      description:
          'Comprehensive deep cleaning that lifts dirt from uppers, scrubs soles clean, and restores yellowed midsoles across all materials.',
      priceRupees: 300,
    ),
    MaintenancePlanData(
      id: 'interior_care_sanitization',
      label: 'Interior Care & Sanitization',
      description:
          'Deep interior extraction wash and antibacterial treatment to eliminate trapped sweat, dirt, and odor-causing bacteria.',
      priceRupees: 300,
    ),
    MaintenancePlanData(
      id: 'detailing_finishing',
      label: 'Detailing & Finishing',
      description:
          'Targeted stain treatment, deep lace soaking, and controlled moisture extraction for a spot-free, safe finish.',
      priceRupees: 300,
    ),
  ];

  /// RepairMyPair multi-select options — Figma node 3079-7627.
  static const List<MaintenancePlanData> _repairPlans = [
    MaintenancePlanData(
      id: 'sole_bottom_construction',
      label: 'Sole & Bottom Construction Repairs',
      description:
          'Complete bottom-up sole restoration, from re-gluing delaminated outsoles and replacing worn heels to full resoles and midsole rebuilds.',
      priceRupees: 236,
    ),
    MaintenancePlanData(
      id: 'upper_seam_restoration',
      label: 'Upper Material & Seam Restoration',
      description:
          'Full upper and interior restoration to patch tears, fix split seams, rebuild heel linings, and replace damaged panels.',
      priceRupees: 236,
    ),
    MaintenancePlanData(
      id: 'hardware_fastener',
      label: 'Hardware & Fastener Repairs',
      description:
          'Complete hardware and fastener replacement for eyelets, zippers, straps, buckles, velcro, and snaps.',
      priceRupees: 236,
    ),
    MaintenancePlanData(
      id: 'fit_structural',
      label: 'Fit & Structural Adjustments',
      description:
          'Fixes squeaks, shaky support inside your shoes, and stretches tight spots for a comfortable fit.',
      priceRupees: 236,
    ),
  ];

  bool _careOptionsScrollbarNeeded = false;

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Address> _addresses = const [];
  Address? _selectedAddress;

  ServiceOptionData? _selectedService;
  MaintenancePlanData? _selectedMaintenancePlan;
  final Set<String> _selectedCareOptionIds = {};
  late List<ServiceFlowArticle> _flowArticles;
  int _focusedArticleIndex = 0;
  int _repairStep = 0;
  bool _homePickup = true;
  bool _pickupModeChosen = false;
  bool _showRepairStep0FieldErrors = true;
  final FocusNode _problemFocusNode = FocusNode();
  final GlobalKey _problemFieldKey = GlobalKey();
  final ScrollController _repairStep0ScrollController = ScrollController();
  int _selectedPickupDay = 0;
  int _selectedPickupSlot = -1;
  int _selectedDropOffIndex = -1;
  bool _showDropOffSchedule = false;
  int _selectedDropOffTimeWindow = -1; // 0 Morning, 1 Afternoon, 2 Evening
  static const List<String> _dropOffTimeWindows = [
    'Morning',
    'Afternoon',
    'Evening',
  ];
  /// When user picks a place on the map for [cobbler_nearby], shown on the summary.
  String? _cobblerNearbyLocationSummary;

  /// Self Drop off locations (UI reference — replace with API later).
  static const List<_DropOffLocation> _dropOffLocations = [
    _DropOffLocation(
      name: 'Bellandur',
      address:
          '996, 1 Floor, 20 Main, 2 Cross, Sec 5, HSR Layout, Bangalore, Karnataka',
      distanceLabel: '4.3 km',
      phone: '+91 9333999339',
      closesAt: '6:30 PM',
      isOpen: true,
    ),
  ];
  final TextEditingController _problemController = TextEditingController();

  final List<XFile> _proofImages = [];
  final List<XFile> _proofVideos = [];
  /// RepairMyPair: selected option ids per shoe article.
  final Map<String, Set<String>> _repairArticleOptionIds = {};
  /// RepairMyPair: photos per shoe article → option id.
  final Map<String, Map<String, List<XFile>>> _repairArticleOptionImages = {};
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
    return List.generate(5, (index) => start.add(Duration(days: index)));
  }

  List<String> get _pickupDayLabels =>
      _pickupDays.map((d) => '${d.day}${_dayOrdinal(d.day)} ${DateFormat('EEEE').format(d)}').toList();

  List<String> get _pickupDayShortLabels =>
      _pickupDays.map((d) => DateFormat('EEE').format(d)).toList();

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

  bool get _isMaintenanceFlow => _singleFlowType == 'maintenance';

  bool get _isWashFlow => _singleFlowType == 'wash';

  bool get _isRepairFlow => _singleFlowType == 'repair';

  /// RepairMyPair / MaintainMyPair / WashMyPair share the checkbox options UI.
  bool get _isCareOptionsFlow =>
      _isMaintenanceFlow || _isWashFlow || _isRepairFlow;

  bool get _repairStep0ProblemValid =>
      _problemController.text.trim().isNotEmpty;

  bool get _repairStep0PhotosValid => _proofImages.isNotEmpty;

  bool get _repairStep0CareOptionsValid {
    if (_isRepairFlow) {
      if (_flowArticles.isEmpty) return false;
      // Every shoe must have ≥1 service, and each selected service needs a photo.
      for (final article in _flowArticles) {
        final opts = _repairArticleOptionIds[article.id] ?? const <String>{};
        if (opts.isEmpty) return false;
        final byOption = _repairArticleOptionImages[article.id] ?? const {};
        for (final optionId in opts) {
          if (byOption[optionId]?.isNotEmpty != true) return false;
        }
      }
      return true;
    }
    return _selectedCareOptionIds.isNotEmpty;
  }

  // Kept for pickup UI (commented out below); re-enable in `_repairStep0Complete`.
  // ignore: unused_element
  bool get _repairStep0PickupValid => _pickupModeChosen;

  // Pickup mode UI is temporarily commented out (future); do not require it yet.
  // MaintainMyPair / WashMyPair step 0: select care options (Figma 2851-4014).
  // RepairMyPair: per-shoe options + upload image for each selected option.
  bool get _repairStep0Complete => _isCareOptionsFlow
      ? _repairStep0CareOptionsValid
      : (_repairStep0ProblemValid && _repairStep0PhotosValid);

  String? get _focusedArticleId {
    if (_flowArticles.isEmpty) return null;
    final i = _focusedArticleIndex.clamp(0, _flowArticles.length - 1);
    return _flowArticles[i].id;
  }

  Set<String> _optionIdsForFocusedArticle() {
    final articleId = _focusedArticleId;
    if (articleId == null) return <String>{};
    return _repairArticleOptionIds.putIfAbsent(articleId, () => <String>{});
  }

  /// Options shown as selected in the current UI (focused shoe for repair).
  Set<String> get _uiSelectedOptionIds =>
      _isRepairFlow ? _optionIdsForFocusedArticle() : _selectedCareOptionIds;

  List<XFile> _imagesForOption(String optionId) {
    if (!_isRepairFlow) return const <XFile>[];
    final articleId = _focusedArticleId;
    if (articleId == null) return const <XFile>[];
    return _repairArticleOptionImages[articleId]?[optionId] ?? const <XFile>[];
  }

  List<XFile> _mutableImagesForOption(String optionId) {
    final articleId = _focusedArticleId;
    if (articleId == null) return <XFile>[];
    final byOption = _repairArticleOptionImages.putIfAbsent(
      articleId,
      () => <String, List<XFile>>{},
    );
    return byOption.putIfAbsent(optionId, () => <XFile>[]);
  }

  List<XFile> get _allOptionProofImages {
    final out = <XFile>[];
    for (final article in _flowArticles) {
      final opts = _repairArticleOptionIds[article.id] ?? const <String>{};
      final byOption = _repairArticleOptionImages[article.id] ?? const {};
      for (final optionId in opts) {
        final list = byOption[optionId];
        if (list != null) out.addAll(list);
      }
    }
    return out;
  }

  String? get _repairSelectionsDescription {
    final lines = <String>[];
    for (final article in _flowArticles) {
      final opts = _repairArticleOptionIds[article.id] ?? const <String>{};
      if (opts.isEmpty) continue;
      final labels = _repairPlans
          .where((p) => opts.contains(p.id))
          .map((p) => p.label)
          .join(', ');
      if (labels.isEmpty) continue;
      final name = article.name.trim().isEmpty ? 'Shoe' : article.name.trim();
      lines.add('$name: $labels');
    }
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  int get _repairSelectionsTotalRupees {
    var sum = 0;
    for (final article in _flowArticles) {
      final opts = _repairArticleOptionIds[article.id] ?? const <String>{};
      for (final plan in _repairPlans) {
        if (opts.contains(plan.id)) sum += plan.priceRupees;
      }
    }
    return sum;
  }

  List<MaintenancePlanData> get _activeCarePlans {
    if (_isWashFlow) return _washPlans;
    if (_isRepairFlow) return _repairPlans;
    return _maintenancePlans;
  }

  List<MaintenancePlanData> get _selectedCareOptions => _activeCarePlans
      .where((p) => _uiSelectedOptionIds.contains(p.id))
      .toList(growable: false);

  MaintenancePlanData? get _resolvedCarePlan {
    if (_isRepairFlow) {
      final total = _repairSelectionsTotalRupees;
      final desc = _repairSelectionsDescription;
      if (total <= 0 || desc == null) return _selectedMaintenancePlan;
      return MaintenancePlanData(
        id: 'repair_multi',
        label: desc,
        description: desc,
        priceRupees: total,
      );
    }
    final selected = _selectedCareOptions;
    if (selected.isEmpty) return _selectedMaintenancePlan;
    if (selected.length == 1) return selected.first;
    return MaintenancePlanData(
      id: selected.map((p) => p.id).join(','),
      label: selected.map((p) => p.label).join(', '),
      description: selected.map((p) => p.description).join('\n'),
      priceRupees: selected.fold<int>(0, (sum, p) => sum + p.priceRupees),
    );
  }

  void _toggleCareOption(String id) {
    if (_submitting) return;
    setState(() {
      final selected = _uiSelectedOptionIds;
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
      _selectedMaintenancePlan =
          _isMaintenanceFlow || _isRepairFlow ? _resolvedCarePlan : null;
      _showRepairStep0FieldErrors = true;
    });
  }

  void _ensureOptionSelected(String optionId) {
    final selected = _uiSelectedOptionIds;
    if (!selected.contains(optionId)) {
      selected.add(optionId);
      _selectedMaintenancePlan =
          _isMaintenanceFlow || _isRepairFlow ? _resolvedCarePlan : null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flowArticles = List<ServiceFlowArticle>.of(widget.selectedArticles);
    if (_isSingleServiceFlow) {
      _selectedService = _visibleOptions.first;
    }
    _problemController.addListener(_onRepairStep0FieldsChanged);
    _problemFocusNode.addListener(_onProblemFocusChanged);
    _repairStep0ScrollController.addListener(_updateCareOptionsScrollbarNeeded);
    _load();
  }

  void _focusArticle(int index) {
    if (_submitting || index < 0 || index >= _flowArticles.length) return;
    setState(() => _focusedArticleIndex = index);
  }

  void _removeFlowArticle(int index) {
    if (_submitting || index < 0 || index >= _flowArticles.length) return;
    setState(() {
      final removedId = _flowArticles[index].id;
      _flowArticles.removeAt(index);
      _repairArticleOptionIds.remove(removedId);
      _repairArticleOptionImages.remove(removedId);
      if (_flowArticles.isEmpty) {
        _focusedArticleIndex = 0;
      } else if (_focusedArticleIndex >= _flowArticles.length) {
        _focusedArticleIndex = _flowArticles.length - 1;
      } else if (_focusedArticleIndex > index) {
        _focusedArticleIndex -= 1;
      }
      _selectedMaintenancePlan =
          _isRepairFlow ? _resolvedCarePlan : _selectedMaintenancePlan;
    });
    if (_flowArticles.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scheduleCareOptionsScrollbarCheck();
    if (_problemFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _scrollProblemFieldIntoView();
        });
      });
    }
  }

  void _updateCareOptionsScrollbarNeeded() {
    if (!mounted || !_isCareOptionsFlow) return;
    if (!_repairStep0ScrollController.hasClients) return;
    final needed =
        _repairStep0ScrollController.position.maxScrollExtent > 0.5;
    if (needed != _careOptionsScrollbarNeeded) {
      setState(() => _careOptionsScrollbarNeeded = needed);
    }
  }

  void _scheduleCareOptionsScrollbarCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCareOptionsScrollbarNeeded();
    });
  }

  void _onRepairStep0FieldsChanged() {
    if (mounted) setState(() {});
  }

  void _onProblemFocusChanged() {
    if (!mounted) return;
    if (_problemFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollProblemFieldIntoView();
      });
      return;
    }
    if (_problemController.text.trim().isEmpty) {
      setState(() => _showRepairStep0FieldErrors = true);
    }
  }

  void _scrollProblemFieldIntoView() {
    if (!mounted || !_problemFocusNode.hasFocus) return;
    final target = _problemFieldKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.22,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _problemController.removeListener(_onRepairStep0FieldsChanged);
    _problemFocusNode.removeListener(_onProblemFocusChanged);
    _repairStep0ScrollController
        .removeListener(_updateCareOptionsScrollbarNeeded);
    _problemFocusNode.dispose();
    _repairStep0ScrollController.dispose();
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

  static const String _alertCircleSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g clip-path="url(#clip0_alert_circle)">
    <path d="M12.8333 7.00033C12.8333 10.222 10.2216 12.8337 6.99996 12.8337C3.7783 12.8337 1.16663 10.222 1.16663 7.00033C1.16663 3.77866 3.7783 1.16699 6.99996 1.16699C10.2216 1.16699 12.8333 3.77866 12.8333 7.00033Z" stroke-width="1.16667" stroke-linecap="round" stroke-linejoin="round" stroke="#FF0000"/>
    <path d="M7 4.66699V7.00033" stroke-width="1.16667" stroke-linecap="round" stroke-linejoin="round" stroke="#FF0000"/>
    <path d="M7 9.33301H7.00625" stroke-width="1.16667" stroke-linecap="round" stroke-linejoin="round" stroke="#FF0000"/>
  </g>
  <defs>
    <clipPath id="clip0_alert_circle">
      <rect width="14" height="14" fill="white"/>
    </clipPath>
  </defs>
</svg>
''';

  Widget _repairStep0InlineError(String message, double layoutScale) {
    const errorRed = Color(0xFFFF0000);
    final iconSize = (14 * layoutScale).clamp(12.0, 16.0);
    return Padding(
      padding: EdgeInsets.only(top: 4 * layoutScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1 * layoutScale),
            child: SvgPicture.string(
              _alertCircleSvg,
              width: iconSize,
              height: iconSize,
            ),
          ),
          SizedBox(width: 4 * layoutScale),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                color: errorRed,
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
    if (!_homePickup) {
      if (_selectedDropOffIndex < 0 ||
          _selectedDropOffIndex >= _dropOffLocations.length) {
        await showAppFeedbackAlert(
          context,
          message: 'Please select a drop-off location',
          type: AppFeedbackType.warning,
        );
        return false;
      }
      if (!_showDropOffSchedule) {
        await showAppFeedbackAlert(
          context,
          message: 'Please book a drop-off location',
          type: AppFeedbackType.warning,
        );
        return false;
      }
      if (_selectedDropOffTimeWindow < 0) {
        await showAppFeedbackAlert(
          context,
          message: 'Please select a preferred time window',
          type: AppFeedbackType.warning,
        );
        return false;
      }
      return true;
    }
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

  UserProfile? _profileFromBlocOrNull() {
    try {
      final state = BlocProvider.of<ProfileBloc>(context).state;
      if (state is ProfileLoaded) return state.profile;
      if (state is AddressActionLoading) return state.profile;
      if (state is ProfileError) return state.profile;
    } catch (_) {}
    return null;
  }

  /// Opens Location (Saved Addresses) sliding in from the top; back returns here.
  Future<void> _openEditLocationPage() async {
    if (_submitting || !mounted) return;

    var profile = _profileFromBlocOrNull();
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        await showAppFeedbackAlert(
          context,
          message: 'Please sign in again to edit location.',
          type: AppFeedbackType.warning,
        );
      },
      (token) async {
        if (profile == null) {
          try {
            profile = await sl<GetUserProfile>().call(token);
          } catch (_) {
            profile = null;
          }
        }
        if (!mounted) return;
        if (profile == null) {
          await showAppFeedbackAlert(
            context,
            message: 'Could not load location. Try again.',
            type: AppFeedbackType.warning,
          );
          return;
        }

        ProfileBloc profileBloc;
        try {
          profileBloc = BlocProvider.of<ProfileBloc>(context);
        } catch (_) {
          profileBloc = sl<ProfileBloc>();
        }

        await Navigator.of(context).push<void>(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) {
              return BlocProvider.value(
                value: profileBloc,
                child: SavedAddressesPage(
                  profile: profile!,
                  accessToken: token,
                ),
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 320),
          ),
        );

        if (!mounted) return;
        // Refresh addresses after returning from Location page.
        try {
          final refreshed = await sl<GetUserProfile>().call(token);
          if (!mounted) return;
          setState(() {
            _addresses = refreshed.addresses;
            if (_selectedAddress != null) {
              final match = refreshed.addresses
                  .where((a) => a.id == _selectedAddress!.id)
                  .toList(growable: false);
              _selectedAddress = match.isNotEmpty
                  ? match.first
                  : (refreshed.addresses.isNotEmpty
                      ? refreshed.addresses.first
                      : null);
            } else if (refreshed.addresses.isNotEmpty) {
              _selectedAddress = refreshed.addresses.first;
            }
          });
        } catch (_) {}
      },
    );
  }

  int _maxImagesForTarget({String? optionId}) =>
      optionId == null ? kMaxProofImages : kMaxOptionProofImages;

  Future<void> _pickImages({String? optionId}) async {
    final target = optionId == null
        ? _proofImages
        : _mutableImagesForOption(optionId);
    final maxImages = _maxImagesForTarget(optionId: optionId);
    if (target.length >= maxImages) return;
    try {
      final list = await _picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _showRepairStep0FieldErrors = true);
        return;
      }
      setState(() {
        for (final f in list) {
          if (target.length >= maxImages) break;
          target.add(f);
        }
        if (optionId != null) _ensureOptionSelected(optionId);
        _showRepairStep0FieldErrors = true;
      });
    } catch (_) {
      final single = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (single != null && target.length < maxImages) {
        setState(() {
          target.add(single);
          if (optionId != null) _ensureOptionSelected(optionId);
          _showRepairStep0FieldErrors = true;
        });
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

  Future<void> _takePicture({String? optionId}) async {
    final target = optionId == null
        ? _proofImages
        : _mutableImagesForOption(optionId);
    final maxImages = _maxImagesForTarget(optionId: optionId);
    if (target.length >= maxImages) return;
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (photo != null) {
      setState(() {
        if (target.length < maxImages) {
          target.add(photo);
        }
        if (optionId != null) _ensureOptionSelected(optionId);
        _showRepairStep0FieldErrors = true;
      });
    } else {
      setState(() => _showRepairStep0FieldErrors = true);
    }
  }

  Future<void> _showPhotoSourceSheet({String? optionId}) async {
    if (_submitting) return;
    final existing =
        optionId == null ? _proofImages : _imagesForOption(optionId);
    final maxImages = _maxImagesForTarget(optionId: optionId);
    if (existing.length >= maxImages && existing.isEmpty) return;

    if (optionId != null && existing.isNotEmpty) {
      await _showOptionPhotosSheet(optionId);
      return;
    }

    if (existing.length >= maxImages) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF0F0F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF11899B)),
                  title: Text(
                    'Upload Photos',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF062F35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: Color(0xFF11899B)),
                  title: Text(
                    'Take Pictures',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF062F35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'camera') {
      await _takePicture(optionId: optionId);
    } else {
      await _pickImages(optionId: optionId);
    }
  }

  Future<void> _showOptionPhotosSheet(String optionId) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF0F0F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              final images = _imagesForOption(optionId);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Uploaded photos (${images.length}/$kMaxOptionProofImages)',
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFF062F35),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (images.isEmpty)
                      Text(
                        'No photos yet.',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF062F35),
                          fontSize: 13,
                        ),
                      )
                    else
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FutureBuilder(
                                    future: images[i].readAsBytes(),
                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: const Color(0xFFE8E8E8),
                                        );
                                      }
                                      return Image.memory(
                                        snap.data!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _mutableImagesForOption(optionId)
                                            .removeAt(i);
                                      });
                                      setModalState(() {});
                                    },
                                    child: SvgPicture.asset(
                                      'assets/images/icons/repairmypair/close_selected.svg',
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (images.length < kMaxOptionProofImages) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.photo_library_outlined,
                            color: Color(0xFF11899B)),
                        title: Text(
                          'Upload more',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF062F35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickImages(optionId: optionId);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.photo_camera_outlined,
                            color: Color(0xFF11899B)),
                        title: Text(
                          'Take another',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF062F35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _takePicture(optionId: optionId);
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
      _repairArticleOptionIds.clear();
      _repairArticleOptionImages.clear();
      if (opt.value != 'maintenance' && opt.value != 'wash') {
        _selectedMaintenancePlan = null;
        _selectedCareOptionIds.clear();
      } else {
        _selectedCareOptionIds.clear();
        _selectedMaintenancePlan = null;
      }
    });
  }

  // Kept for map-based nearby selection if Self Drop off gains live shops later.
  // ignore: unused_element
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
  }

  void _selectPickupMode(bool homePickup) {
    if (_submitting || !mounted) return;
    setState(() {
      _homePickup = homePickup;
      _pickupModeChosen = true;
      if (homePickup) {
        _selectedDropOffIndex = -1;
        _showDropOffSchedule = false;
        _selectedDropOffTimeWindow = -1;
      } else {
        _selectedPickupSlot = -1;
      }
    });
  }

  void _openDropOffSchedule(int index) {
    if (_submitting || !mounted) return;
    if (index < 0 || index >= _dropOffLocations.length) return;
    final loc = _dropOffLocations[index];
    setState(() {
      _selectedDropOffIndex = index;
      _homePickup = false;
      _pickupModeChosen = true;
      _showDropOffSchedule = true;
      _selectedDropOffTimeWindow = -1;
      _selectedPickupDay = 0;
      _cobblerNearbyLocationSummary =
          '${loc.name} · ${loc.distanceLabel}\n${loc.address}';
    });
  }

  void _backToDropOffList() {
    if (_submitting || !mounted) return;
    setState(() {
      _showDropOffSchedule = false;
      _selectedDropOffTimeWindow = -1;
    });
  }

  void _handleRepairFlowBack() {
    if (_submitting || !mounted) return;
    if (!_homePickup && _showDropOffSchedule) {
      _backToDropOffList();
      return;
    }
    if (_repairStep > 0) {
      setState(() => _repairStep -= 1);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _onRepairStepZeroNext() async {
    if (_submitting || !mounted) return;
    if (!await _validateRepairStep0()) return;
    if (!_pickupModeChosen) {
      setState(() {
        _homePickup = true;
        _pickupModeChosen = true;
      });
    }
    // RepairMyPair: review selections on Finalizing Services before pickup.
    // Wash / Maintain: go to delivery / drop-off step.
    setState(() => _repairStep = 1);
  }

  Future<void> _onFinalizingNext() async {
    if (_submitting || !mounted) return;
    if (!_pickupModeChosen) {
      setState(() {
        _homePickup = true;
        _pickupModeChosen = true;
      });
    }
    setState(() => _repairStep = 2);
  }

  /// One summary card per shoe × selected repair service.
  List<({ServiceFlowArticle article, MaintenancePlanData plan, List<XFile> photos})>
      get _finalizingCards {
    final cards = <({
      ServiceFlowArticle article,
      MaintenancePlanData plan,
      List<XFile> photos,
    })>[];
    for (final article in _flowArticles) {
      final opts = _repairArticleOptionIds[article.id] ?? const <String>{};
      final byOption = _repairArticleOptionImages[article.id] ?? const {};
      for (final plan in _repairPlans) {
        if (!opts.contains(plan.id)) continue;
        cards.add((
          article: article,
          plan: plan,
          photos: List<XFile>.from(byOption[plan.id] ?? const <XFile>[]),
        ));
      }
    }
    return cards;
  }

  int? _resolvedEstimatedRupees() {
    final s = _selectedService?.value;
    switch (s) {
      case 'repair':
        final total = _repairSelectionsTotalRupees;
        return total > 0 ? total : kRepairEstimateRupees;
      case 'wash':
        if (_selectedCareOptions.isNotEmpty) {
          return _selectedCareOptions.fold<int>(
            0,
            (sum, p) => sum + p.priceRupees,
          );
        }
        return kWashEstimateRupees;
      case 'maintenance':
        return (_resolvedCarePlan ?? _maintenancePlans.first).priceRupees;
      case 'donate':
      case 'dispose':
        return 0;
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final addressStep = _isRepairFlow ? 2 : 1;
    if (_isSingleServiceFlow && _repairStep == addressStep) {
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
    if ((_selectedService!.value == 'maintenance' ||
            _selectedService!.value == 'wash' ||
            _selectedService!.value == 'repair') &&
        !_repairStep0CareOptionsValid &&
        !_isSingleServiceFlow) {
      await showAppFeedbackAlert(
        context,
        message: _selectedService!.value == 'repair'
            ? 'Please select services and upload photos for each shoe'
            : 'Please select at least one option',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (!await _validateRepairStep1()) return;
    if (_selectedAddress == null) {
      await showAppFeedbackAlert(
        context,
        message: _homePickup
            ? 'Please select a pickup address'
            : 'Please set your location via Edit location',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (!_homePickup &&
        _selectedDropOffIndex >= 0 &&
        _selectedDropOffIndex < _dropOffLocations.length) {
      final drop = _dropOffLocations[_selectedDropOffIndex];
      _cobblerNearbyLocationSummary =
          '${drop.name} · ${drop.distanceLabel}\n${drop.address}';
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
              _flowArticles.map((a) => a.id).toList(growable: false),
          service: _selectedService!,
          address: _selectedAddress!,
          proofImages: List<XFile>.from(
            _isRepairFlow && _allOptionProofImages.isNotEmpty
                ? _allOptionProofImages
                : _proofImages,
          ),
          proofVideos: List<XFile>.from(_proofVideos),
          estimatedCostRupees: est,
          problemDescription: () {
            if (_selectedService!.value == 'repair') {
              return _repairSelectionsDescription;
            }
            if (_selectedService!.value == 'maintenance' ||
                _selectedService!.value == 'wash') {
              final labels =
                  _selectedCareOptions.map((p) => p.label).join(', ');
              return labels.isEmpty ? null : labels;
            }
            final text = _problemController.text.trim();
            return text.isEmpty ? null : text;
          }(),
          pickupModeLabel:
              _homePickup ? 'Delivery Pick up' : 'Self Drop off',
          pickupScheduleLabel: !_homePickup
              ? () {
                  final locSummary = _cobblerNearbyLocationSummary;
                  final day = _pickupDayLabels[
                      _selectedPickupDay.clamp(0, _pickupDayLabels.length - 1)];
                  final window = _selectedDropOffTimeWindow >= 0 &&
                          _selectedDropOffTimeWindow <
                              _dropOffTimeWindows.length
                      ? _dropOffTimeWindows[_selectedDropOffTimeWindow]
                      : null;
                  final schedule = [
                    if (locSummary != null && locSummary.trim().isNotEmpty)
                      locSummary.trim(),
                    if (window != null) '$day · $window',
                  ].join('\n');
                  return schedule.isEmpty ? null : schedule;
                }()
              : _selectedPickupSlot < 0
                  ? null
                  : '${_pickupDayLabels[_selectedPickupDay.clamp(0, _pickupDayLabels.length - 1)]}, ${_pickupSlotLabels[_selectedPickupSlot.clamp(0, _pickupSlotLabels.length - 1)]}',
          maintenancePlan: (_selectedService!.value == 'maintenance' ||
                  _selectedService!.value == 'repair')
              ? (_resolvedCarePlan ??
                  (_isRepairFlow ? _repairPlans.first : _maintenancePlans.first))
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
        body: const AppSkeletonCards(
          color: Color(0x66FFFFFF),
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
                  if (_isSingleServiceFlow) {
                    _handleRepairFlowBack();
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
    final layoutScale = serviceFlowLayoutScale(context, uiScale: uiScale);
    final pillH = (48 * layoutScale).clamp(40.0, 52.0);
    final fs = (16 * layoutScale).clamp(12.0, 16.0);
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final dockH = 14 + pillH + 14 + bottomSafe;
    final step0CanNext = _repairStep0Complete && !_submitting;
    final finalizeCanNext = !_submitting && _finalizingCards.isNotEmpty;
    final addressCanNext = !_submitting &&
        (_homePickup
            ? (_selectedPickupSlot >= 0 && _selectedAddress != null)
            : (_showDropOffSchedule &&
                _selectedDropOffIndex >= 0 &&
                _selectedDropOffIndex < _dropOffLocations.length &&
                _selectedDropOffTimeWindow >= 0));
    final bool canNext;
    final VoidCallback? onNext;
    if (_repairStep == 0) {
      canNext = step0CanNext;
      onNext = _onRepairStepZeroNext;
    } else if (_isRepairFlow && _repairStep == 1) {
      canNext = finalizeCanNext;
      onNext = _onFinalizingNext;
    } else {
      canNext = addressCanNext;
      onNext = _submit;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: true,
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
                  dockH - 12,
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
                        ? const AppSkeletonCards()
                        : _buildRepairSingleServicePanel(context),
                  ),
                ),
              ),
            ),
          ),
          if (!_loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _repairFlowNextButton(
                enabled: canNext,
                height: pillH,
                fontSize: fs,
                onPressed: onNext,
              ),
            ),
        ],
      ),
    );
  }

  Widget _repairFlowNextButton({
    required bool enabled,
    required double height,
    required double fontSize,
    required VoidCallback? onPressed,
  }) {
    const pillW = 168.0;
    final button = !enabled
        ? SizedBox(
            width: pillW,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  'Next',
                  style: GoogleFonts.boldonse(
                    color: const Color(0xFF4A4A4A),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          )
        : SizedBox(
            width: pillW,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF063239),
                    Color(0xFF0CADC5),
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
                onPressed: onPressed,
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
                    : Text(
                        'Next',
                        style: GoogleFonts.boldonse(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ),
            ),
          );

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
      child: Center(child: button),
    );
  }

  /// Matches [DonateMyPairDetailsPage] shell: fixed viewport, scaled controls; step 2 scrolls if needed.
  Widget _buildRepairSingleServicePanel(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final layoutScale = serviceFlowLayoutScale(context, uiScale: uiScale);
    final fs = (16 * layoutScale).clamp(12.0, 16.0);
    final titleFs = (24 * layoutScale).clamp(17.0, 24.0);
    // final pillH = (48 * layoutScale).clamp(40.0, 52.0); // pickup UI (future)
    // final pillFs = (14 * layoutScale).clamp(11.0, 14.0); // pickup UI (future)
    final actionFs = (14 * layoutScale).clamp(11.0, 14.0);
    final iconSz = (58 * layoutScale).clamp(36.0, 58.0);
    final uploadTapH = (96 * layoutScale).clamp(70.0, 112.0);
    final effectiveUploadH = uploadTapH;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Match Figma side inset — left was tighter than right; bump slightly.
    final contentHPadLeft = (16 * layoutScale).clamp(14.0, 18.0);
    final contentHPadRight = (20 * layoutScale).clamp(16.0, 22.0);

    final title = _isRepairFlow && _repairStep == 1
        ? 'Finalizing Services'
        : (widget.flowPageTitle ?? 'RepairMyPair');
    final selectedArticles = _flowArticles;
    final appBarTitleFs = _isRepairFlow && _repairStep == 1
        ? (18 * layoutScale).clamp(16.0, 18.0)
        : titleFs;

    // Next dock is rendered full-bleed in [_buildRepairOnlyPage] Stack.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        contentHPadLeft,
        16,
        contentHPadRight,
        keyboardInset > 0 ? 8.0 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_repairStep != 0)
            ColoredBox(
              color: const Color(0xFFF0F0F0),
              child: _buildRepairFlowAppBar(
                context,
                title: title,
                layoutScale: layoutScale,
                titleFontSize: appBarTitleFs,
                onBack: _submitting ? null : _handleRepairFlowBack,
              ),
            ),
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
              child: ColoredBox(
                color: const Color(0xFFF0F0F0),
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _updateCareOptionsScrollbarNeeded();
                    return false;
                  },
                  child: RawScrollbar(
                    controller: _repairStep0ScrollController,
                    // Show only when content overflows (when scroll is needed).
                    thumbVisibility: _isCareOptionsFlow
                        ? _careOptionsScrollbarNeeded
                        : false,
                    trackVisibility: _isCareOptionsFlow &&
                        _careOptionsScrollbarNeeded,
                    interactive: true,
                    radius: const Radius.circular(4),
                    thickness: _isCareOptionsFlow ? 6 : 4,
                    thumbColor: const Color(0xFF6B6B6B),
                    trackColor: const Color(0x336B6B6B),
                    trackRadius: const Radius.circular(4),
                    padding: EdgeInsets.only(
                      right: 2,
                      // Start near article/shoe image center — not from the top.
                      top: _isCareOptionsFlow
                          ? (_isRepairFlow
                              ? (168 * layoutScale).clamp(140.0, 200.0)
                              : (36 * layoutScale).clamp(28.0, 44.0))
                          : (8 * layoutScale).clamp(4.0, 10.0),
                      // Keep thumb clear of the Next dock / card bottom (Figma).
                      bottom: _isCareOptionsFlow
                          ? (72 * layoutScale).clamp(56.0, 88.0)
                          : (8 * layoutScale).clamp(4.0, 10.0),
                    ),
                    child: SingleChildScrollView(
                      controller: _repairStep0ScrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(
                        // Extra room so the last options clear the Next dock.
                        bottom: _isCareOptionsFlow
                            ? (120 * layoutScale).clamp(96.0, 140.0)
                            : 16,
                        right: _isCareOptionsFlow &&
                                _careOptionsScrollbarNeeded
                            ? 14
                            : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRepairFlowAppBar(
                            context,
                            title: title,
                            layoutScale: layoutScale,
                            titleFontSize: titleFs,
                            onBack: _submitting ? null : _handleRepairFlowBack,
                          ),
                          SizedBox(
                            height: keyboardInset > 0
                                ? 8
                                : (26 * layoutScale).clamp(20.0, 36.0),
                          ),
                          if (selectedArticles.isNotEmpty) ...[
                            _buildSelectedFootwearHeader(
                              selectedArticles,
                              layoutScale: layoutScale,
                              fontSize: fs,
                              iconSize: iconSz,
                              compact: _isCareOptionsFlow && !_isRepairFlow,
                              carousel: _isRepairFlow ||
                                  (_isCareOptionsFlow &&
                                      selectedArticles.length > 1),
                            ),
                            SizedBox(
                              height: _isCareOptionsFlow
                                  ? (12 * layoutScale).clamp(8.0, 16.0)
                                  : 8 * layoutScale,
                            ),
                          ],
                          if (_isCareOptionsFlow) ...[
                          Text(
                            'How can we help you today?',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF062F35),
                              fontSize:
                                  (16 * layoutScale).clamp(14.0, 16.0),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (_showRepairStep0FieldErrors &&
                              !_repairStep0CareOptionsValid)
                            _repairStep0InlineError(
                              _isRepairFlow
                                  ? 'Each shoe needs its own services + photos (tap a pair above to switch).'
                                  : 'Please select at least one option.',
                              layoutScale,
                            ),
                          SizedBox(
                            height: (18 * layoutScale).clamp(12.0, 24.0),
                          ),
                          _buildCareOptionsList(layoutScale),
                        ] else ...[
                      KeyedSubtree(
                        key: _problemFieldKey,
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
                            if (_showRepairStep0FieldErrors &&
                                !_repairStep0ProblemValid)
                              _repairStep0InlineError(
                                'Please fill out this field.',
                                layoutScale,
                              ),
                            SizedBox(height: 4 * layoutScale),
                            TextField(
                              controller: _problemController,
                              focusNode: _problemFocusNode,
                              keyboardType: TextInputType.multiline,
                              minLines: 4,
                              maxLines: 8,
                              scrollPadding: const EdgeInsets.only(
                                top: 72,
                                bottom: 24,
                              ),
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
                                filled: false,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical:
                                      (12 * layoutScale).clamp(8.0, 14.0),
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
                                  borderSide: const BorderSide(
                                    width: 1.2,
                                    color: Color(0xFF12899B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      if (_showRepairStep0FieldErrors &&
                          !_repairStep0PhotosValid)
                        _repairStep0InlineError(
                          'Please upload images.',
                          layoutScale,
                        ),
                      SizedBox(height: 4 * layoutScale),
                      SizedBox(
                        height: effectiveUploadH,
                        child: InkWell(
                          onTap: _submitting ? null : _showPhotoSourceSheet,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: ShapeDecoration(
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 1,
                                  color: Color(0x7F12899B),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_camera_outlined,
                                  color: const Color(0xFF8D8D8D),
                                  size: (28 * layoutScale).clamp(22.0, 30.0),
                                ),
                                SizedBox(height: 8 * layoutScale),
                                Text(
                                  'Upload Photos or Take Pictures',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF8D8D8D),
                                    fontSize: actionFs,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_proofImages.isNotEmpty) ...[
                        SizedBox(height: 8 * layoutScale),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_proofImages.length}/$kMaxProofImages photo(s) added',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF12899B),
                              fontSize:
                                  (12 * layoutScale).clamp(10.0, 13.0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 6 * layoutScale),
                        SizedBox(
                          height: (76 * layoutScale).clamp(60.0, 92.0),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.hardEdge,
                            itemCount: _proofImages.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(width: 8 * layoutScale),
                            itemBuilder: (_, i) {
                              final thumb =
                                  (72 * layoutScale).clamp(56.0, 88.0);
                              return SizedBox(
                                width: thumb,
                                height: thumb,
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: FutureBuilder(
                                          future: _proofImages[i]
                                              .readAsBytes(),
                                          builder: (context, snap) {
                                            if (!snap.hasData) {
                                              return Container(
                                                color: const Color(
                                                    0xFFDFE7E9),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(
                                                          0xFF11999E),
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
                                      top: 2,
                                      right: 2,
                                      child: Material(
                                        color: const Color(0xFFB00020),
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder:
                                              const CircleBorder(),
                                          onTap: _submitting
                                              ? null
                                              : () => _removeImage(i),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.all(3),
                                            child: Icon(
                                              Icons.close,
                                              size: (14 * layoutScale)
                                                  .clamp(12.0, 16.0),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      // ------------------------------------------------------------------
                      // Pickup section — keep for future implement; do not remove.
                      // ------------------------------------------------------------------
                      // SizedBox(height: 8 * layoutScale),
                      // Text(
                      //   'How would you like to send us your footwear?',
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: GoogleFonts.montserrat(
                      //     color: const Color(0xFF062F35),
                      //     fontSize: fs,
                      //     fontWeight: FontWeight.w400,
                      //   ),
                      // ),
                      // SizedBox(height: 6 * layoutScale),
                      // SizedBox(
                      //   height: pillH,
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         child: ServiceFlowPickupPill(
                      //           label: 'Home Pickup',
                      //           selected:
                      //               _pickupModeChosen && _homePickup,
                      //           height: pillH,
                      //           fontSize: pillFs,
                      //           onTap: () => _selectPickupMode(true),
                      //         ),
                      //       ),
                      //       SizedBox(width: 12 * layoutScale),
                      //       Expanded(
                      //         child: ServiceFlowPickupPill(
                      //           label: 'Cobblers Nearby',
                      //           selected:
                      //               _pickupModeChosen && !_homePickup,
                      //           height: pillH,
                      //           fontSize: pillFs,
                      //           onTap: () => _selectPickupMode(false),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // if (_showRepairStep0FieldErrors &&
                      //     !_repairStep0PickupValid)
                      //   _repairStep0InlineError(
                      //     'Please choose an option.',
                      //     layoutScale,
                      //   ),
                      ],
                    ],
                  ),
                ),
                ),
                ),
              ),
            ),
          ] else if (_isRepairFlow && _repairStep == 1) ...[
            Expanded(
              child: _buildFinalizingServicesPanel(layoutScale),
            ),
          ] else
            Expanded(
              child: ClipRect(
                child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8 * layoutScale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: (18 * layoutScale).clamp(12.0, 24.0),
                      ),
                      _buildDeliveryDropOffToggle(layoutScale),
                      SizedBox(height: (24 * layoutScale).clamp(18.0, 28.0)),
                      if (_homePickup)
                        _buildDeliveryPickupPanel(layoutScale, fs)
                      else if (_showDropOffSchedule)
                        _buildSelfDropOffSchedulePanel(layoutScale, fs)
                      else
                        _buildSelfDropOffPanel(layoutScale),
                    ],
                  ),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Segmented control — Delivery Pick up | Self Drop off (Figma).
  Widget _buildDeliveryDropOffToggle(double layoutScale) {
    final h = (28 * layoutScale).clamp(26.0, 32.0);
    final labelFs = (12 * layoutScale).clamp(11.0, 13.0);
    Widget segment({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _submitting ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: h,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF12899B) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.boldonse(
                  color: selected
                      ? const Color(0xFFF0F0F0)
                      : const Color(0xFFABABAB),
                  fontSize: labelFs,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: const Color(0x7F062F35),
        ),
      ),
      child: Row(
        children: [
          segment(
            label: 'Delivery Pick up',
            selected: _homePickup,
            onTap: () => _selectPickupMode(true),
          ),
          segment(
            label: 'Self Drop off',
            selected: !_homePickup,
            onTap: () => _selectPickupMode(false),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPickupPanel(double layoutScale, double fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pickup address',
                              style: GoogleFonts.boldonse(
                                color: const Color(0xFF062F35),
                                fontSize: fs,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _submitting ? null : _pickAddress,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: SvgPicture.asset(
                                'assets/images/icons/profile/edit.svg',
                                width: (22 * layoutScale).clamp(18.0, 24.0),
                                height: (22 * layoutScale).clamp(18.0, 24.0),
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF062F35),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: (14 * layoutScale).clamp(12.0, 18.0)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: (38 * layoutScale).clamp(32.0, 42.0),
                            height: (38 * layoutScale).clamp(32.0, 42.0),
                            decoration: BoxDecoration(
                              color: const Color(0x33D9D9D9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFF12899B),
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              'assets/images/icons/profile/home.svg',
                              width: (18 * layoutScale).clamp(15.0, 20.0),
                              height: (18 * layoutScale).clamp(15.0, 20.0),
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF12899B),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(width: (14 * layoutScale).clamp(12.0, 16.0)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF12899B),
                                    fontSize:
                                        (14 * layoutScale).clamp(12.0, 15.0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: (8 * layoutScale).clamp(6.0, 10.0),
                                ),
                                Text(
                                  _selectedAddress == null
                                      ? 'No address selected'
                                      : '${_selectedAddress!.addressLine1}, ${_selectedAddress!.city}, ${_selectedAddress!.state}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF4E7F8A),
                                    fontSize:
                                        (13 * layoutScale).clamp(11.0, 14.0),
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: (28 * layoutScale).clamp(22.0, 32.0)),
                      Text(
                        'Select a date',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: fs,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: (14 * layoutScale).clamp(12.0, 18.0)),
                      SizedBox(
                        height: (82 * layoutScale).clamp(72.0, 92.0),
                        child: Row(
                          // Flush with section titles: first/last at edges.
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_pickupDays.length, (index) {
                            final selected = _selectedPickupDay == index;
                            final day = _pickupDays[index];
                            final box =
                                (42 * layoutScale).clamp(36.0, 48.0);
                            return InkWell(
                              onTap: _submitting
                                  ? null
                                  : () => setState(() {
                                        _selectedPickupDay = index;
                                        _selectedPickupSlot = -1;
                                      }),
                              borderRadius: BorderRadius.circular(5),
                              child: SizedBox(
                                width: box,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _pickupDayShortLabels[index],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                        color: const Color(0xFF12899B),
                                        fontSize: (11 * layoutScale)
                                            .clamp(10.0, 12.0),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8 * layoutScale),
                                    Container(
                                      width: box,
                                      height: box,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFF12899B)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: const Color(0xFF12899B),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${day.day}',
                                        style: GoogleFonts.montserrat(
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF12899B),
                                          fontSize: (14 * layoutScale)
                                              .clamp(12.0, 15.0),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: (28 * layoutScale).clamp(22.0, 32.0)),
                      Text(
                        'Select a time slot',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: fs,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: (14 * layoutScale).clamp(12.0, 18.0)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Same side inset as titles/dates: spaceBetween edges.
                          final chipH =
                              (40 * layoutScale).clamp(36.0, 44.0);
                          final rowGap =
                              (14 * layoutScale).clamp(12.0, 18.0);
                          // Keep chips compact; leftover width becomes mid gaps.
                          final chipW = ((constraints.maxWidth - 72) / 3)
                              .clamp(70.0, 86.0);
                          const radius = 5.0;
                          final labels = _pickupSlotLabels;
                          final rows = <Widget>[];
                          for (var r = 0; r < 3; r++) {
                            final rowChildren = <Widget>[];
                            for (var c = 0; c < 3; c++) {
                              final index = r * 3 + c;
                              if (index >= labels.length) break;
                              final selected = _selectedPickupSlot == index;
                              rowChildren.add(
                                SizedBox(
                                  width: chipW,
                                  height: chipH,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _submitting
                                          ? null
                                          : () => setState(() {
                                                _selectedPickupSlot =
                                                    selected ? -1 : index;
                                              }),
                                      borderRadius:
                                          BorderRadius.circular(radius),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: selected
                                              ? const LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    Color(0xFF063239),
                                                    Color(0xFF0CADC5),
                                                  ],
                                                )
                                              : null,
                                          color: selected
                                              ? null
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(radius),
                                          border: Border.all(
                                            width: 1,
                                            color: selected
                                                ? Colors.transparent
                                                : const Color(0xFF12899B),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            labels[index],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF12899B),
                                              fontSize: (11 * layoutScale)
                                                  .clamp(10.0, 12.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            rows.add(
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: rowChildren,
                              ),
                            );
                            if (r < 2) {
                              rows.add(SizedBox(height: rowGap));
                            }
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rows,
                          );
                        },
                      ),
      ],
    );
  }

  /// Figma 3079:8144 / 3076:7081 — schedule after Book on a drop-off.
  Widget _buildSelfDropOffSchedulePanel(double layoutScale, double fs) {
    final loc = (_selectedDropOffIndex >= 0 &&
            _selectedDropOffIndex < _dropOffLocations.length)
        ? _dropOffLocations[_selectedDropOffIndex]
        : _dropOffLocations.first;
    final noteFs = (12 * layoutScale).clamp(11.0, 13.0);
    final windowH = (46 * layoutScale).clamp(40.0, 50.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.name,
                          style: GoogleFonts.boldonse(
                            color: const Color(0xFF062F35),
                            fontSize: (14 * layoutScale).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: (5 * layoutScale).clamp(4.0, 8.0)),
                        Text(
                          loc.distanceLabel,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF12899B),
                            fontSize: (16 * layoutScale).clamp(13.0, 16.0),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _submitting ? null : _backToDropOffList,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: SvgPicture.asset(
                        'assets/images/icons/profile/edit.svg',
                        width: (24 * layoutScale).clamp(20.0, 26.0),
                        height: (24 * layoutScale).clamp(20.0, 26.0),
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF062F35),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: (10 * layoutScale).clamp(8.0, 12.0)),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE0E0E0),
              ),
              SizedBox(height: (10 * layoutScale).clamp(8.0, 12.0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/icons/repairmypair/walk.svg',
                    width: (15 * layoutScale).clamp(13.0, 17.0),
                    height: (23 * layoutScale).clamp(20.0, 26.0),
                  ),
                  SizedBox(width: (10 * layoutScale).clamp(8.0, 12.0)),
                  Expanded(
                    child: Text(
                      'This is a self drop booking. You will have to drop your pairs to the drop location.',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFABABAB),
                        fontSize: noteFs,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: (28 * layoutScale).clamp(22.0, 32.0)),
        Text(
          'Select a date',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF062F35),
            fontSize: fs,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: (14 * layoutScale).clamp(12.0, 18.0)),
        SizedBox(
          height: (82 * layoutScale).clamp(72.0, 92.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_pickupDays.length, (index) {
              final selected = _selectedPickupDay == index;
              final day = _pickupDays[index];
              final box = (42 * layoutScale).clamp(36.0, 48.0);
              return InkWell(
                onTap: _submitting
                    ? null
                    : () => setState(() => _selectedPickupDay = index),
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  width: box,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pickupDayShortLabels[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF12899B),
                          fontSize: (11 * layoutScale).clamp(10.0, 12.0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8 * layoutScale),
                      Container(
                        width: box,
                        height: box,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF12899B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFF12899B),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.montserrat(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF12899B),
                            fontSize: (14 * layoutScale).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: (28 * layoutScale).clamp(22.0, 32.0)),
        Text(
          'Your preferred time window',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF062F35),
            fontSize: fs,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: (14 * layoutScale).clamp(12.0, 18.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_dropOffTimeWindows.length, (index) {
            final selected = _selectedDropOffTimeWindow == index;
            final label = _dropOffTimeWindows[index];
            return Flexible(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : (6 * layoutScale).clamp(4.0, 8.0),
                  right: index == _dropOffTimeWindows.length - 1
                      ? 0
                      : (6 * layoutScale).clamp(4.0, 8.0),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitting
                        ? null
                        : () => setState(
                              () => _selectedDropOffTimeWindow =
                                  selected ? -1 : index,
                            ),
                    borderRadius: BorderRadius.circular(5),
                    child: Ink(
                      height: windowH,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF12899B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          width: 1,
                          color: const Color(0xFF12899B),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF12899B),
                            fontSize: (13 * layoutScale).clamp(11.0, 15.0),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSelfDropOffPanel(double layoutScale) {
    final titleFs = (16 * layoutScale).clamp(14.0, 17.0);
    final editFs = (12 * layoutScale).clamp(11.0, 13.0);
    final cardGap = (28 * layoutScale).clamp(20.0, 32.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Drop-Offs near your location ',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: titleFs,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: (12 * layoutScale).clamp(8.0, 16.0)),
            InkWell(
              onTap: _submitting ? null : _openEditLocationPage,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit location',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: editFs,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: (5 * layoutScale).clamp(4.0, 7.0)),
                      Container(
                        height: 1,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: (20 * layoutScale).clamp(16.0, 24.0)),
        ...List.generate(_dropOffLocations.length, (index) {
          final loc = _dropOffLocations[index];
          final selected = _selectedDropOffIndex == index;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _dropOffLocations.length - 1 ? 0 : cardGap,
            ),
            child: _buildDropOffLocationCard(
              layoutScale: layoutScale,
              location: loc,
              selected: selected,
              onBook: () => _openDropOffSchedule(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDropOffLocationCard({
    required double layoutScale,
    required _DropOffLocation location,
    required bool selected,
    required VoidCallback onBook,
  }) {
    final nameFs = (14 * layoutScale).clamp(12.0, 15.0);
    final addressFs = (16 * layoutScale).clamp(13.0, 16.0);
    final metaFs = (12 * layoutScale).clamp(11.0, 13.0);
    final bookH = (32 * layoutScale).clamp(30.0, 36.0);
    final distW = (55 * layoutScale).clamp(50.0, 60.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: selected ? 1.5 : 0,
          color: selected ? const Color(0xFF12899B) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFF062F35),
                        fontSize: nameFs,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: (5 * layoutScale).clamp(4.0, 8.0)),
                    Text(
                      location.address,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF12899B),
                        fontSize: addressFs,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: (9 * layoutScale).clamp(6.0, 12.0)),
              SizedBox(
                width: distW,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: (32 * layoutScale).clamp(28.0, 34.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        border: Border.all(
                          width: 1,
                          color: const Color(0xFFABABAB),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/icons/profile/navigation.svg',
                        width: (16 * layoutScale).clamp(14.0, 18.0),
                        height: (16 * layoutScale).clamp(14.0, 18.0),
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF062F35),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: (26 * layoutScale).clamp(22.0, 28.0),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: Text(
                        location.distanceLabel,
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: metaFs,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: (15 * layoutScale).clamp(12.0, 18.0)),
          Row(
            children: [
              Image.asset(
                'assets/images/icons/repairmypair/clock.png',
                width: (12 * layoutScale).clamp(11.0, 14.0),
                height: (12 * layoutScale).clamp(11.0, 14.0),
                color: location.isOpen
                    ? const Color(0xFF0FB700)
                    : const Color(0xFFABABAB),
              ),
              SizedBox(width: (8 * layoutScale).clamp(6.0, 10.0)),
              Text(
                location.isOpen ? 'Open' : 'Closed',
                style: GoogleFonts.montserrat(
                  color: location.isOpen
                      ? const Color(0xFF0FB700)
                      : const Color(0xFFABABAB),
                  fontSize: metaFs,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: (8 * layoutScale).clamp(6.0, 10.0)),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF062F35),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: (8 * layoutScale).clamp(6.0, 10.0)),
              Flexible(
                child: Text(
                  'Closes ${location.closesAt}',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: metaFs,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Transform.rotate(
                angle: -1.5708,
                child: Image.asset(
                  'assets/images/icons/repairmypair/chevron_down.png',
                  width: (16 * layoutScale).clamp(14.0, 18.0),
                  height: (16 * layoutScale).clamp(14.0, 18.0),
                  color: const Color(0xFF062F35),
                ),
              ),
            ],
          ),
          SizedBox(height: (6 * layoutScale).clamp(4.0, 8.0)),
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/phone.svg',
                width: (12 * layoutScale).clamp(11.0, 14.0),
                height: (12 * layoutScale).clamp(11.0, 14.0),
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: (8 * layoutScale).clamp(6.0, 10.0)),
              Text(
                location.phone,
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: metaFs,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: (17 * layoutScale).clamp(12.0, 20.0)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submitting ? null : onBook,
              borderRadius: BorderRadius.circular(100),
              child: Ink(
                height: bookH,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFF0CADC5), Color(0xFF063239)],
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
                child: Center(
                  child: Text(
                    'Book',
                    style: GoogleFonts.boldonse(
                      color: Colors.white,
                      fontSize: metaFs,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Care / repair multi-select options — Figma nodes 2851-4014 / 3079-7627.
  Widget _buildCareOptionsList(double layoutScale) {
    final plans = _activeCarePlans;
    final titleFs = (14 * layoutScale).clamp(12.0, 14.0);
    final bodyFs = (14 * layoutScale).clamp(12.0, 14.0);
    // Slightly smaller than Figma 38 so rows feel tighter.
    final box = (28 * layoutScale).clamp(24.0, 30.0);
    final gap = (22 * layoutScale).clamp(14.0, 22.0);
    final itemGap = (10 * layoutScale).clamp(8.0, 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          if (i > 0) SizedBox(height: itemGap),
          _buildCareOptionRow(
            plan: plans[i],
            selected: _uiSelectedOptionIds.contains(plans[i].id),
            layoutScale: layoutScale,
            titleFs: titleFs,
            bodyFs: bodyFs,
            checkboxSize: box,
            gap: gap,
            showCamera: _isRepairFlow,
            photoCount: _imagesForOption(plans[i].id).length,
          ),
        ],
      ],
    );
  }

  Widget _buildCareOptionRow({
    required MaintenancePlanData plan,
    required bool selected,
    required double layoutScale,
    required double titleFs,
    required double bodyFs,
    required double checkboxSize,
    required double gap,
    bool showCamera = false,
    int photoCount = 0,
  }) {
    final cameraSize = (24 * layoutScale).clamp(20.0, 24.0);
    final priceAmount = plan.priceRupees.toString();
    final textGap = (6 * layoutScale).clamp(4.0, 8.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _submitting ? null : () => _toggleCareOption(plan.id),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: (8 * layoutScale).clamp(6.0, 10.0)),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 1,
                color: Color(0xFF09E0FF),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: checkboxSize,
                height: checkboxSize,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF12899B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF12899B),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(
                        Icons.check,
                        size: (checkboxSize * 0.55).clamp(12.0, 16.0),
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: gap),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        right: showCamera ? cameraSize + 10 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹',
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize:
                                        (22 * layoutScale).clamp(18.0, 22.0),
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                                TextSpan(
                                  text: priceAmount,
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize: titleFs,
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: textGap),
                          Text(
                            plan.label,
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF12899B),
                              fontSize: titleFs,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                            ),
                          ),
                          SizedBox(height: textGap),
                          Text(
                            plan.description,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF062F35),
                              fontSize: bodyFs,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showCamera)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _submitting
                              ? null
                              : () => _showPhotoSourceSheet(optionId: plan.id),
                          child: SizedBox(
                            width: cameraSize + 6,
                            height: cameraSize + 6,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/icons/repairmypair/camera.svg',
                                  width: cameraSize,
                                  height: cameraSize,
                                  fit: BoxFit.contain,
                                ),
                                // Count lives on the camera; tap again to add/remove.
                                if (photoCount > 0)
                                  Positioned(
                                    top: -2,
                                    right: -4,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 22),
                                      height: 15,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$photoCount/$kMaxOptionProofImages',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeFinalizingSelection({
    required String articleId,
    required String planId,
  }) {
    if (_submitting) return;
    setState(() {
      _repairArticleOptionIds[articleId]?.remove(planId);
      _repairArticleOptionImages[articleId]?.remove(planId);
      _selectedMaintenancePlan = _resolvedCarePlan;
    });
    if (_finalizingCards.isEmpty && mounted) {
      setState(() => _repairStep = 0);
    }
  }

  void _removeFinalizingPhoto({
    required String articleId,
    required String planId,
    required int index,
  }) {
    if (_submitting) return;
    setState(() {
      final list = _repairArticleOptionImages[articleId]?[planId];
      if (list == null || index < 0 || index >= list.length) return;
      list.removeAt(index);
      // No photos left → drop this service selection for the shoe.
      if (list.isEmpty) {
        _repairArticleOptionIds[articleId]?.remove(planId);
        _repairArticleOptionImages[articleId]?.remove(planId);
      }
      _selectedMaintenancePlan = _resolvedCarePlan;
    });
    if (_finalizingCards.isEmpty && mounted) {
      setState(() => _repairStep = 0);
    }
  }

  Widget _buildFinalizingServicesPanel(double layoutScale) {
    final cards = _finalizingCards;
    return ColoredBox(
      color: const Color(0xFFF0F0F0),
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          0,
          (12 * layoutScale).clamp(8.0, 16.0),
          0,
          (24 * layoutScale).clamp(16.0, 32.0),
        ),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox.shrink(),
        itemBuilder: (_, i) {
          final card = cards[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == cards.length - 1
                  ? 0
                  : (20 * layoutScale).clamp(14.0, 24.0),
            ),
            child: Padding(
              padding: EdgeInsets.all((14 * layoutScale).clamp(10.0, 14.0)),
              child: _buildFinalizingServiceCard(
                article: card.article,
                plan: card.plan,
                photos: card.photos,
                layoutScale: layoutScale,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinalizingServiceCard({
    required ServiceFlowArticle article,
    required MaintenancePlanData plan,
    required List<XFile> photos,
    required double layoutScale,
  }) {
    final name = article.name.trim().isEmpty ? 'Shoe' : article.name.trim();
    final subtitle = (article.subtitle?.trim().isNotEmpty ?? false)
        ? article.subtitle!.trim()
        : name;
    final nameFs = (14 * layoutScale).clamp(12.0, 14.0);
    final bodyFs = (14 * layoutScale).clamp(12.0, 14.0);
    final shoeW = (118 * layoutScale).clamp(96.0, 118.0);
    final shoeH = (63 * layoutScale).clamp(52.0, 64.0);
    final thumbW = (149 * layoutScale).clamp(120.0, 149.0);
    final thumbH = (69 * layoutScale).clamp(56.0, 72.0);
    final closeSize = (22 * layoutScale).clamp(18.0, 24.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all((10 * layoutScale).clamp(8.0, 12.0)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.boldonse(
                            color: const Color(0xFF11899B),
                            fontSize: nameFs,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: bodyFs,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: (12 * layoutScale).clamp(8.0, 16.0)),
                  SizedBox(
                    width: shoeW,
                    height: shoeH,
                    child: article.imageUrl.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFD9D9D9),
                            child: Icon(
                              Icons.checkroom_outlined,
                              color: Color(0xFF8D8D8D),
                            ),
                          )
                        : Image.network(
                            article.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFD9D9D9),
                              child: Icon(
                                Icons.checkroom_outlined,
                                color: Color(0xFF8D8D8D),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              SizedBox(height: (16 * layoutScale).clamp(12.0, 20.0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      plan.label,
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: bodyFs,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(width: (12 * layoutScale).clamp(8.0, 16.0)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '...',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: bodyFs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '₹',
                          style: GoogleFonts.boldonse(
                            color: Colors.black,
                            fontSize: bodyFs,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '${plan.priceRupees}',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: bodyFs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (photos.isNotEmpty) ...[
                SizedBox(height: (14 * layoutScale).clamp(10.0, 18.0)),
                SizedBox(
                  height: thumbH + 6,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: (12 * layoutScale).clamp(8.0, 16.0)),
                    itemBuilder: (_, i) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: thumbW,
                              height: thumbH,
                              child: FutureBuilder(
                                future: photos[i].readAsBytes(),
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return const ColoredBox(
                                      color: Color(0xFFD9D9D9),
                                    );
                                  }
                                  return Image.memory(
                                    snap.data!,
                                    fit: BoxFit.cover,
                                    width: thumbW,
                                    height: thumbH,
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _removeFinalizingPhoto(
                                articleId: article.id,
                                planId: plan.id,
                                index: i,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/icons/repairmypair/close_selected.svg',
                                width: closeSize,
                                height: closeSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: -closeSize * 0.35,
          right: -closeSize * 0.2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _removeFinalizingSelection(
              articleId: article.id,
              planId: plan.id,
            ),
            child: SvgPicture.asset(
              'assets/images/icons/repairmypair/close_selected.svg',
              width: closeSize,
              height: closeSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairFlowAppBar(
    BuildContext context, {
    required String title,
    required double layoutScale,
    required double titleFontSize,
    required VoidCallback? onBack,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF062F35),
            size: (24 * layoutScale).clamp(18.0, 24.0),
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints.tightFor(width: 24, height: 26),
        ),
        SizedBox(width: 4 * layoutScale),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.boldonse(
              color: const Color(0xFF062F35),
              fontSize: titleFontSize,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFootwearHeader(
    List<ServiceFlowArticle> articles, {
    required double layoutScale,
    required double fontSize,
    required double iconSize,
    bool compact = false,
    bool carousel = false,
  }) {
    if (articles.isEmpty) return const SizedBox.shrink();

    // RepairMyPair Figma 3079-7627: horizontal selected-shoe cards + focus label.
    if (carousel) {
      return _buildFootwearCarouselHeader(
        articles,
        layoutScale: layoutScale,
        fontSize: fontSize,
        iconSize: iconSize,
      );
    }

    if (articles.length == 1) {
      final article = articles.first;
      final name = article.name.trim();
      final subtitle = article.subtitle?.trim() ?? '';
      if (name.isEmpty && subtitle.isEmpty && article.imageUrl.isEmpty) {
        return const SizedBox.shrink();
      }
      final subtitleFs = (fontSize * 0.88).clamp(11.0, 14.0);

      // MaintainMyPair Figma: name + subtitle, then centered shoe image below.
      if (compact) {
        final imgW = (180 * layoutScale).clamp(140.0, 220.0);
        final imgH = (120 * layoutScale).clamp(96.0, 148.0);
        final graySubtitle = subtitle.isNotEmpty ? subtitle : name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (name.isNotEmpty)
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF12899B),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.05,
                ),
              ),
            if (graySubtitle.isNotEmpty) ...[
              SizedBox(height: 4 * layoutScale),
              Text(
                graySubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: subtitleFs,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ),
              ),
            ],
            if (article.imageUrl.isNotEmpty) ...[
              SizedBox(height: (10 * layoutScale).clamp(8.0, 14.0)),
              Center(
                child: SizedBox(
                  width: imgW,
                  height: imgH,
                  child: ArticleRackShoeImage(
                    imageUrl: article.imageUrl,
                    width: imgW,
                    height: imgH,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
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
            ],
          ],
        );
      }

      final imgW = (180 * layoutScale).clamp(140.0, 220.0);
      final imgH = (120 * layoutScale).clamp(96.0, 148.0);

      // Figma: article name + brand first, then centered article image.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.boldonse(
                color: const Color(0xFF11899B),
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                height: 1.05,
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 4 * layoutScale),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF062F35),
                fontSize: subtitleFs,
                fontWeight: FontWeight.w400,
                height: 1.15,
              ),
            ),
          ],
          if (article.imageUrl.isNotEmpty) ...[
            SizedBox(height: 10 * layoutScale),
            Center(
              child: SizedBox(
                width: imgW,
                height: imgH,
                child: ArticleRackShoeImage(
                  imageUrl: article.imageUrl,
                  width: imgW,
                  height: imgH,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
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
          ],
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
              final label =
                  article.name.trim().isEmpty ? 'Shoe' : article.name.trim();
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

  Widget _buildFootwearCarouselHeader(
    List<ServiceFlowArticle> articles, {
    required double layoutScale,
    required double fontSize,
    required double iconSize,
  }) {
    final cardW = (144 * layoutScale).clamp(120.0, 144.0);
    final cardPad = (10 * layoutScale).clamp(8.0, 10.0);
    final imgH = (66 * layoutScale).clamp(54.0, 72.0);
    final closeSize = (22 * layoutScale).clamp(18.0, 24.0);
    final gap = (24 * layoutScale).clamp(16.0, 24.0);
    final focused = articles[_focusedArticleIndex.clamp(0, articles.length - 1)];
    final focusedName = focused.name.trim();
    final focusedSubtitle = focused.subtitle?.trim() ?? '';
    final nameFs = (16 * layoutScale).clamp(13.0, 16.0);
    final subtitleFs = (16 * layoutScale).clamp(13.0, 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: imgH + (cardPad * 2) + 6,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            separatorBuilder: (_, _) => SizedBox(width: gap),
            itemBuilder: (_, i) {
              final article = articles[i];
              final isFocused = i == _focusedArticleIndex;
              return GestureDetector(
                onTap: () => _focusArticle(i),
                child: SizedBox(
                  width: cardW,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: cardW,
                        padding: EdgeInsets.all(cardPad),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isFocused
                                ? const Color(0xFF12899B)
                                : const Color(0xFFABABAB),
                            width: isFocused ? 3 : 1,
                          ),
                        ),
                        // Same presentation as My Rack row (no extra tilt).
                        child: SizedBox(
                          height: imgH,
                          width: double.infinity,
                          child: article.imageUrl.isEmpty
                              ? Icon(
                                  Icons.checkroom_outlined,
                                  color: const Color(0xFF8D8D8D),
                                  size: iconSize * 0.7,
                                )
                              : Image.network(
                                  article.imageUrl,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.checkroom_outlined,
                                    color: const Color(0xFF8D8D8D),
                                    size: iconSize * 0.7,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: -closeSize * 0.35,
                        right: -closeSize * 0.2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _removeFlowArticle(i),
                          child: SvgPicture.asset(
                            isFocused
                                ? 'assets/images/icons/repairmypair/close_selected.svg'
                                : 'assets/images/icons/repairmypair/close_unselected.svg',
                            width: closeSize,
                            height: closeSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: (12 * layoutScale).clamp(8.0, 14.0)),
        if (focusedName.isNotEmpty)
          Text(
            focusedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.boldonse(
              color: const Color(0xFF11899B),
              fontSize: nameFs,
              fontWeight: FontWeight.w400,
              height: 1.1,
            ),
          ),
        if (focusedSubtitle.isNotEmpty)
          Text(
            focusedSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: subtitleFs,
              fontWeight: FontWeight.w400,
              height: 1.15,
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
        if (_flowArticles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSelectedFootwearHeader(
              _flowArticles,
              layoutScale: 1,
              fontSize: 16,
              iconSize: 52,
              carousel: _isRepairFlow || _flowArticles.length > 1,
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
    if (s == 'wash' || s == 'maintenance') {
      return [
        _sectionTitle(
          'How can we help you today?',
          'Select one or more care options.',
        ),
        const SizedBox(height: 14),
        _buildCareOptionsList(1),
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

class _DropOffLocation {
  final String name;
  final String address;
  final String distanceLabel;
  final String phone;
  final String closesAt;
  final bool isOpen;

  const _DropOffLocation({
    required this.name,
    required this.address,
    required this.distanceLabel,
    required this.phone,
    required this.closesAt,
    required this.isOpen,
  });
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
