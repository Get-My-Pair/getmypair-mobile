import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/home/presentation/pages/select_location_page.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/profile/domain/usecases/get_user_profile.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../utils/service_flow_article.dart';
import '../utils/service_flow_layout.dart';
import 'request_summary_page.dart';
import 'select_address_page.dart';
import 'service_selection_page.dart';

/// Post-selection steps for donation (details → optional pickup → summary).
/// Entry screen matches [MaintainMyPairPage] / [WashMyPairPage]: use [DonateMyPairPage],
/// which wraps [RepairMyPairPage] with `allowedServiceTypes: ['donate']`.

const int _kMaxDonatePhotos = 5;

/// Step 2 — reason, photos, pickup mode (full-screen page).
class DonateMyPairDetailsPage extends StatefulWidget {
  final String articleId;
  final String articleName;
  final String articleImageUrl;
  final List<ServiceFlowArticle> selectedArticles;

  DonateMyPairDetailsPage({
    super.key,
    required this.articleId,
    required this.articleName,
    required this.articleImageUrl,
    List<ServiceFlowArticle>? selectedArticles,
  }) : selectedArticles = selectedArticles ??
            [
              ServiceFlowArticle(
                id: articleId,
                name: articleName,
                imageUrl: articleImageUrl,
              ),
            ];

  @override
  State<DonateMyPairDetailsPage> createState() => _DonateMyPairDetailsPageState();
}

class _DonateMyPairDetailsPageState extends State<DonateMyPairDetailsPage> {
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  bool _loading = true;
  bool _busy = false;
  String? _error;
  Address? _selectedAddress;

  bool _homePickup = true;
  final TextEditingController _reasonController = TextEditingController();
  final List<XFile> _proofImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<bool> _validateDonateDetails() async {
    if (_reasonController.text.trim().isEmpty) {
      await showAppFeedbackAlert(
        context,
        message: 'Please describe why you are donating',
        type: AppFeedbackType.warning,
      );
      return false;
    }
    if (_proofImages.isEmpty) {
      await showAppFeedbackAlert(
        context,
        message: 'Please upload at least one photo',
        type: AppFeedbackType.warning,
      );
      return false;
    }
    return true;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final profile = await sl<GetUserProfile>().call(token);
          if (!mounted) return;
          setState(() {
            _selectedAddress =
                profile.addresses.isNotEmpty ? profile.addresses.first : null;
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

  Future<void> _pickImages() async {
    if (_proofImages.length >= _kMaxDonatePhotos) return;
    try {
      final list = await _picker.pickMultiImage(imageQuality: 85);
      if (list.isEmpty || !mounted) return;
      setState(() {
        for (final f in list) {
          if (_proofImages.length >= _kMaxDonatePhotos) break;
          _proofImages.add(f);
        }
      });
    } catch (_) {
      final single = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (single != null &&
          mounted &&
          _proofImages.length < _kMaxDonatePhotos) {
        setState(() => _proofImages.add(single));
      }
    }
  }

  Future<void> _takePicture() async {
    if (_proofImages.length >= _kMaxDonatePhotos) return;
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null &&
        mounted &&
        _proofImages.length < _kMaxDonatePhotos) {
      setState(() => _proofImages.add(photo));
    }
  }

  Future<void> _onNext() async {
    if (_busy || !mounted) return;
    if (!await _validateDonateDetails()) return;
    if (_selectedAddress == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please add a pickup address in your profile',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() => _busy = true);
    final reason = _reasonController.text.trim();

    try {
      if (_homePickup) {
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => DonateMyPairPickupPage(
              selectedArticles: widget.selectedArticles,
              reason: reason,
              proofImages: List<XFile>.from(_proofImages),
              selectedAddress: _selectedAddress!,
            ),
          ),
        );
        if (!mounted) return;
        if (created == true) {
          Navigator.of(context).pop(true);
        }
      } else {
        ProfileBloc profileBloc;
        try {
          profileBloc = BlocProvider.of<ProfileBloc>(context);
        } catch (_) {
          profileBloc = sl<ProfileBloc>();
        }
        final selectedLocation = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
            builder: (_) => SelectLocationPage(profileBloc: profileBloc),
          ),
        );
        if (!mounted) return;
        if (selectedLocation == null || selectedLocation.trim().isEmpty) {
          setState(() => _busy = false);
          return;
        }

        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RequestSummaryPage(
              articleIds: widget.selectedArticles.map((a) => a.id).toList(),
              service: _donateService,
              address: _selectedAddress!,
              proofImages: List<XFile>.from(_proofImages),
              proofVideos: const [],
              estimatedCostRupees: 0,
              problemDescription: reason.isEmpty ? null : reason,
              pickupModeLabel: 'Cobblers Nearby',
              pickupScheduleLabel: selectedLocation.trim(),
              homePickup: false,
              requestedPickupAt: null,
            ),
          ),
        );
        if (!mounted) return;
        if (created == true) {
          Navigator.of(context).pop(true);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _panelRadius,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF11999E),
                            ),
                          )
                        : _buildDonateDetailsBody(context),
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

  Widget _buildDonateDetailsBody(BuildContext context) {
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
                onPressed: _busy ? null : () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF062F35),
                  size: (24 * layoutScale).clamp(18.0, 24.0),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              ),
              SizedBox(width: 6 * layoutScale),
              Expanded(
                child: Text(
                  'DonateMyPair',
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
          if (widget.articleName.trim().isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.articleName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF11899B),
                  fontSize: fs,
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
                      child: widget.articleImageUrl.isEmpty
                          ? Icon(
                              Icons.checkroom_outlined,
                              color: const Color(0xFF8D8D8D),
                              size: iconSz,
                            )
                          : ArticleRackShoeImage(
                              imageUrl: widget.articleImageUrl,
                              width: imgW,
                              height: imgH,
                              fit: BoxFit.contain,
                              placeholder: Icon(
                                Icons.checkroom_outlined,
                                color: const Color(0xFF8D8D8D),
                                size: iconSz,
                              ),
                              errorPlaceholder: Icon(
                                Icons.checkroom_outlined,
                                color: const Color(0xFF8D8D8D),
                                size: iconSz,
                              ),
                            ),
                    ),
                  ),
                );
              },
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
                    'Reason for donation',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF062F35),
                      fontSize: fs,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4 * layoutScale),
                  TextField(
                    controller: _reasonController,
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
                      hintText: 'Type Here',
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
                  SizedBox(height: 8 * layoutScale),
                  Text(
                    'Upload photos for donation',
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
                      onTap: _busy ? null : _pickImages,
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
                              onTap: _busy ? null : _pickImages,
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
                              onTap: _busy ? null : _takePicture,
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
                          child: _pickupPill(
                            label: 'Home Pickup',
                            selected: _homePickup,
                            height: pillH,
                            fontSize: pillFs,
                            onTap: () {
                              if (_busy) return;
                              setState(() => _homePickup = true);
                            },
                          ),
                        ),
                        SizedBox(width: 12 * layoutScale),
                        Expanded(
                          child: _pickupPill(
                            label: 'Cobblers Nearby',
                            selected: !_homePickup,
                            height: pillH,
                            fontSize: pillFs,
                            onTap: () {
                              if (_busy) return;
                              setState(() => _homePickup = false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          onPressed: _busy ? null : _onNext,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: _busy
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
                                      size:
                                          (16 * layoutScale).clamp(13.0, 16.0),
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
        ],
      ),
    );
  }

  Widget _pickupPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double height = 48,
    double fontSize = 14,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF0CADC5), Color(0xFF063239)],
                )
              : null,
          color: selected ? null : const Color(0xFFDFE7E9),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            width: 1,
            color: selected ? Colors.transparent : const Color(0xFF0F6876),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.boldonse(
            color: selected ? Colors.white : const Color(0xFF062F35),
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Step 3 — home pickup schedule + address (full-screen page).
class DonateMyPairPickupPage extends StatefulWidget {
  final List<ServiceFlowArticle> selectedArticles;
  final String reason;
  final List<XFile> proofImages;
  final Address selectedAddress;

  const DonateMyPairPickupPage({
    super.key,
    required this.selectedArticles,
    required this.reason,
    required this.proofImages,
    required this.selectedAddress,
  });

  @override
  State<DonateMyPairPickupPage> createState() => _DonateMyPairPickupPageState();
}

class _DonateMyPairPickupPageState extends State<DonateMyPairPickupPage> {
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  bool _submitting = false;
  int _selectedPickupSlot = -1;
  late Address _selectedAddress = widget.selectedAddress;

  List<DateTime> get _pickupDays {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List.generate(3, (index) => start.add(Duration(days: index)));
  }

  List<String> get _pickupDayLabels => _pickupDays
      .map(
        (d) =>
            '${d.day}${_dayOrdinal(d.day)} ${DateFormat('EEEE').format(d)}',
      )
      .toList();

  List<DateTime> get _pickupSlotDateTimes {
    final selectedDay = _pickupDays.first;
    final now = DateTime.now();
    final isToday = selectedDay.year == now.year &&
        selectedDay.month == now.month &&
        selectedDay.day == now.day;

    DateTime base;
    if (isToday) {
      final roundedMinutes = now.minute < 30 ? 30 : 60;
      base = DateTime(now.year, now.month, now.day, now.hour, 0)
          .add(Duration(minutes: roundedMinutes));
    } else {
      base = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        9,
        0,
      );
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

  Future<void> _pickAddress() async {
    final picked = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) =>
            SelectAddressPage(selectedAddressId: _selectedAddress.id),
      ),
    );
    if (picked != null && mounted) setState(() => _selectedAddress = picked);
  }

  Future<void> _goSummary() async {
    if (_submitting) return;
    if (_selectedPickupSlot < 0) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a pickup time slot',
        type: AppFeedbackType.warning,
      );
      return;
    }
    setState(() => _submitting = true);
    final scheduleLabel =
        '${_pickupDayLabels.first}, '
        '${_pickupSlotLabels[_selectedPickupSlot.clamp(0, _pickupSlotLabels.length - 1)]}';
    final pickupAt = _pickupSlotDateTimes[
        _selectedPickupSlot.clamp(0, _pickupSlotDateTimes.length - 1)];

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RequestSummaryPage(
          articleIds: widget.selectedArticles.map((a) => a.id).toList(),
          service: _donateService,
          address: _selectedAddress,
          proofImages: List<XFile>.from(widget.proofImages),
          proofVideos: const [],
          estimatedCostRupees: 0,
          problemDescription:
              widget.reason.isEmpty ? null : widget.reason,
          pickupModeLabel: 'Home Pickup',
          pickupScheduleLabel: scheduleLabel,
          homePickup: true,
          requestedPickupAt: pickupAt,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (created == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    const topInset = 52.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
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
                  topInset,
                  horizontalInset,
                  0,
                ),
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _panelRadius,
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          _buildDonatePickupBody(context, constraints),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DashboardLinkedBottomNav(selectedTabIndex: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDonatePickupBody(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final navH = dashboardLinkedBottomNavStackHeight(context);
    final maxH = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final layoutScale = math
        .min(uiScale, ((maxH - navH) / 560).clamp(0.55, 1.0))
        .toDouble();
    final fs = (16 * layoutScale).clamp(12.0, 16.0);
    final titleFs = (24 * layoutScale).clamp(17.0, 24.0);
    final pillH = (48 * layoutScale).clamp(40.0, 52.0);
    final slotFs = (13 * layoutScale).clamp(9.0, 13.0);
    final crossSpacing = (14 * layoutScale).clamp(6.0, 16.0);
    final mainSpacing = (16 * layoutScale).clamp(6.0, 18.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, navH + 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF062F35),
                  size: (24 * layoutScale).clamp(18.0, 24.0),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              ),
              SizedBox(width: 6 * layoutScale),
              Expanded(
                child: Text(
                  'DonateMyPair',
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
          SizedBox(height: 12 * layoutScale),
          Text(
            'Home Pickup',
            style: GoogleFonts.boldonse(
              color: const Color(0xFF062F35),
              fontSize: fs,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 6 * layoutScale),
          Text(
            'Please choose a time slot from the options below',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF062F35),
              fontSize: fs,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12 * layoutScale),
          Row(
            children: [
              Text(
                _pickupDayLabels.first,
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF12899B),
                  fontSize: (14 * layoutScale).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 8 * layoutScale),
              SvgPicture.asset(
                'assets/images/calendar.svg',
                width: (18 * layoutScale).clamp(14.0, 20.0),
                height: (18 * layoutScale).clamp(14.0, 20.0),
              ),
            ],
          ),
          SizedBox(height: 10 * layoutScale),
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                const cross = 3;
                final rows =
                    (_pickupSlotLabels.length + cross - 1) ~/ cross;
                final gw = inner.maxWidth;
                final gh = inner.maxHeight;
                final cellW =
                    (gw - crossSpacing * (cross - 1)) / cross;
                final cellH =
                    (gh - mainSpacing * (rows - 1)) / rows;
                final aspect =
                    (cellW / cellH.clamp(1e-6, double.infinity))
                        .clamp(0.85, 3.2)
                        .toDouble();
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pickupSlotLabels.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                    childAspectRatio: aspect,
                  ),
                  itemBuilder: (_, index) {
                    final selected = _selectedPickupSlot == index;
                    return InkWell(
                      onTap: _submitting
                          ? null
                          : () => setState(() => _selectedPickupSlot = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
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
                          color: selected ? null : const Color(0xFFDFE7E9),
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
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.boldonse(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF12899B),
                            fontSize: slotFs,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 12 * layoutScale),
          Text(
            'Pickup Address',
            style: GoogleFonts.boldonse(
              color: const Color(0xFF062F35),
              fontSize: fs,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 6 * layoutScale),
          Flexible(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                8 * layoutScale,
                6 * layoutScale,
                8 * layoutScale,
                8 * layoutScale,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: (30 * layoutScale).clamp(24.0, 34.0),
                    height: (30 * layoutScale).clamp(24.0, 34.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF11899B),
                      ),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: const Color(0xFF11899B),
                      size: (17 * layoutScale).clamp(14.0, 20.0),
                    ),
                  ),
                  SizedBox(width: 10 * layoutScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedAddress.addressLine1.isNotEmpty
                              ? _selectedAddress.addressLine1
                              : 'Home',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF12899B),
                            fontSize: (13 * layoutScale).clamp(10.0, 14.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2 * layoutScale),
                        Text(
                          '${_selectedAddress.addressLine1}, ${_selectedAddress.city}, ${_selectedAddress.state}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF4E7F8A),
                            fontSize: (13 * layoutScale).clamp(10.0, 14.0),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6 * layoutScale),
                  InkWell(
                    onTap: _submitting ? null : _pickAddress,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (10 * layoutScale).clamp(6.0, 12.0),
                        vertical: (4 * layoutScale).clamp(2.0, 6.0),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11899B),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Change',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: (11 * layoutScale).clamp(9.0, 12.0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  onPressed: _submitting ? null : _goSummary,
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
                                size: (16 * layoutScale).clamp(13.0, 16.0),
                              ),
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
}

const ServiceOptionData _donateService = ServiceOptionData(
  value: 'donate',
  title: 'Donate',
  subtitle: 'Give your pair a second life',
  icon: Icons.volunteer_activism_outlined,
);
