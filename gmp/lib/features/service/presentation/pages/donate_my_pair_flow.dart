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

  const DonateMyPairDetailsPage({
    super.key,
    required this.articleId,
    required this.articleName,
    required this.articleImageUrl,
  });

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
              articleId: widget.articleId,
              articleName: widget.articleName,
              articleImageUrl: widget.articleImageUrl,
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
              articleId: widget.articleId,
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
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF11999E),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                            children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.maybePop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Color(0xFF062F35),
                                    size: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 26,
                                    height: 26,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DonateMyPair',
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (widget.articleName.trim().isNotEmpty) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.articleName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF11899B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 230,
                                height: 96,
                                child: Center(
                                  child: widget.articleImageUrl.isEmpty
                                      ? const Icon(
                                          Icons.checkroom_outlined,
                                          color: Color(0xFF8D8D8D),
                                          size: 58,
                                        )
                                      : ArticleRackShoeImage(
                                          imageUrl: widget.articleImageUrl,
                                          width: 230,
                                          height: 96,
                                          fit: BoxFit.contain,
                                          placeholder: const Icon(
                                            Icons.checkroom_outlined,
                                            color: Color(0xFF8D8D8D),
                                            size: 58,
                                          ),
                                          errorPlaceholder: const Icon(
                                            Icons.checkroom_outlined,
                                            color: Color(0xFF8D8D8D),
                                            size: 58,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB00020),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            Text(
                              'Reason for donation',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF062F35),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _reasonController,
                              minLines: 4,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Type Here',
                                hintStyle: GoogleFonts.montserrat(
                                  color: const Color(0xFFABABAB),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
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
                            const SizedBox(height: 16),
                            Text(
                              'Upload photos for donation',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF062F35),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: _busy ? null : _pickImages,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 101,
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
                                  children: [
                                    GestureDetector(
                                      onTap: _busy ? null : _pickImages,
                                      child: Text(
                                        'Upload Photos ',
                                        style: GoogleFonts.boldonse(
                                          color: const Color(0xFF12899B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'or',
                                      style: GoogleFonts.boldonse(
                                        color: const Color(0xFFABABAB),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _busy ? null : _takePicture,
                                      child: Text(
                                        ' Take Pictures',
                                        style: GoogleFonts.boldonse(
                                          color: const Color(0xFF12899B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How would you like to send us your footwear?',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF062F35),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _pickupPill(
                                    label: 'Home Pickup',
                                    selected: _homePickup,
                                    onTap: () {
                                      if (_busy) return;
                                      setState(() => _homePickup = true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _pickupPill(
                                    label: 'Cobblers Nearby',
                                    selected: !_homePickup,
                                    onTap: () {
                                      if (_busy) return;
                                      setState(() => _homePickup = false);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: SizedBox(
                                width: 164,
                                height: 48,
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white,
                                                size: 16,
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

  Widget _pickupPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 48,
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
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Step 3 — home pickup schedule + address (full-screen page).
class DonateMyPairPickupPage extends StatefulWidget {
  final String articleId;
  final String articleName;
  final String articleImageUrl;
  final String reason;
  final List<XFile> proofImages;
  final Address selectedAddress;

  const DonateMyPairPickupPage({
    super.key,
    required this.articleId,
    required this.articleName,
    required this.articleImageUrl,
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
  int _selectedPickupSlot = 0;
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
    setState(() => _submitting = true);
    final scheduleLabel =
        '${_pickupDayLabels.first}, '
        '${_pickupSlotLabels[_selectedPickupSlot.clamp(0, _pickupSlotLabels.length - 1)]}';
    final pickupAt = _pickupSlotDateTimes[
        _selectedPickupSlot.clamp(0, _pickupSlotDateTimes.length - 1)];

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RequestSummaryPage(
          articleId: widget.articleId,
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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF062F35),
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 26,
                              height: 26,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DonateMyPair',
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF062F35),
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Home Pickup',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please choose a time slot from the options below',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF062F35),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            _pickupDayLabels.first,
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF12899B),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/images/calendar.svg',
                            width: 18,
                            height: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pickupSlotLabels.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.1,
                        ),
                        itemBuilder: (_, index) {
                          final selected = _selectedPickupSlot == index;
                          return InkWell(
                            onTap: _submitting
                                ? null
                                : () => setState(
                                      () => _selectedPickupSlot = index,
                                    ),
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
                                color:
                                    selected ? null : const Color(0xFFDFE7E9),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pickup Address',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF11899B),
                                ),
                              ),
                              child: const Icon(
                                Icons.home_outlined,
                                color: Color(0xFF11899B),
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAddress.addressLine1.isNotEmpty
                                        ? _selectedAddress.addressLine1
                                        : 'Home',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFF12899B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_selectedAddress.addressLine1}, ${_selectedAddress.city}, ${_selectedAddress.state}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFF4E7F8A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _submitting ? null : _pickAddress,
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11899B),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Change',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: 164,
                          height: 48,
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.white,
                                          size: 16,
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
}

const ServiceOptionData _donateService = ServiceOptionData(
  value: 'donate',
  title: 'Donate',
  subtitle: 'Give your pair a second life',
  icon: Icons.volunteer_activism_outlined,
);
