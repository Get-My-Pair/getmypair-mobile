import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../profile_screen_system_ui.dart';

class SavedAddressesPage extends StatefulWidget {
  final UserProfile profile;
  final String accessToken;

  const SavedAddressesPage({
    super.key,
    required this.profile,
    required this.accessToken,
  });

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showAllAddresses = false;

  /// Real phone GPS + app permission status (not a dummy toggle).
  bool _deviceLocationOn = false;
  bool _checkingDeviceLocation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshDeviceLocationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDeviceLocationStatus();
    }
  }

  Future<void> _refreshDeviceLocationStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!mounted) return;
      setState(() {
        _deviceLocationOn = serviceEnabled && granted;
        _checkingDeviceLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceLocationOn = false;
        _checkingDeviceLocation = false;
      });
    }
  }

  Future<void> _onDeviceLocationTap() async {
    if (_checkingDeviceLocation) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      // Already on — open phone location settings so user can turn GPS off.
      if (serviceEnabled && granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location is on. Use phone settings to turn it off.',
            ),
          ),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      // Device GPS / location services off → open system settings.
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on Location in your phone settings.'),
          ),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      // Services on but app permission missing.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to continue.'),
          ),
        );
        await _refreshDeviceLocationStatus();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allow location for GetMyPair in app settings.',
            ),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      await _refreshDeviceLocationStatus();
      if (!mounted) return;
      if (_deviceLocationOn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location is on.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (state is ProfileError) {
          await showAppFeedbackAlert(
            context,
            message: state.message,
            type: AppFeedbackType.failure,
          );
        }
      },
      builder: (context, state) {
        final currentProfile = state is ProfileLoaded
            ? state.profile
            : state is AddressActionLoading
            ? state.profile
            : state is ProfileError && state.profile != null
            ? state.profile!
            : widget.profile;
        final isLoading = state is AddressActionLoading;

        final allAddresses = currentProfile.addresses;
        final visibleAddresses = _showAllAddresses
            ? allAddresses
            : allAddresses.take(2).toList(growable: false);

        final locationLabel = _checkingDeviceLocation
            ? 'Checking…'
            : _deviceLocationOn
                ? 'Location On'
                : 'Turn on Location';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: kProfileGradientHeaderSystemUi,
          child: Scaffold(
            extendBody: true,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: false,
                        radius: const Radius.circular(3.5),
                        thickness: 7,
                        thumbColor: const Color(0x80000000),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding:
                              ArticleStyleHeaderInsets.scrollContentPadding(
                            context,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Row(
                              children: [
                                const ChevronScreenBackButton(
                                  iconColor: Color(0xFFDFE7E9),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Location',
                                  style: GoogleFonts.boldonse(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFFDFE7E9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSearchBar(),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    icon: _deviceLocationOn
                                        ? Icons.location_on_rounded
                                        : Icons.location_off_rounded,
                                    label: locationLabel,
                                    highlighted: _deviceLocationOn,
                                    onTap: _checkingDeviceLocation
                                        ? null
                                        : _onDeviceLocationTap,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionCard(
                                    iconAsset:
                                        'assets/images/icons/profile/plus-square.svg',
                                    label: 'Add New Address',
                                    onTap: isLoading
                                        ? null
                                        : () => _showAddressDialog(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 42),
                            Text(
                              'Saved Address',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (allAddresses.isEmpty)
                              _buildEmptyState()
                            else ...[
                              ...visibleAddresses.map(
                                (address) => _AddressRow(
                                  address: address,
                                  isLoading: isLoading,
                                  onEdit: () => _showAddressDialog(
                                    context,
                                    address: address,
                                  ),
                                  onDelete: () =>
                                      _confirmDelete(context, address),
                                  isHome: address == allAddresses.first,
                                ),
                              ),
                              if (allAddresses.length > 2)
                                Center(
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _showAllAddresses =
                                          !_showAllAddresses,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _showAllAddresses
                                                ? 'View Less'
                                                : 'View All',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            _showAllAddresses
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 24),
                            ],
                          ),
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

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/search.svg',
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              readOnly: true,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Search an area or address',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0x57000000),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        'No saved addresses yet. Tap Add New Address to continue.',
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Address address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileBloc>().add(
                AddressDeleteRequested(
                  accessToken: widget.accessToken,
                  addressId: address.id,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, {Address? address}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: _AddressFormPage(
            accessToken: widget.accessToken,
            existing: address,
            profile: widget.profile,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String? iconAsset;
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  const _ActionCard({
    this.iconAsset,
    this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  }) : assert(iconAsset != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0x550F6876)
              : const Color(0x33D9D9D9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF7FD4E0)
                : Colors.white.withValues(alpha: 0.28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: Colors.white)
            else
              SvgPicture.asset(
                iconAsset!,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final Address address;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isHome;

  const _AddressRow({
    required this.address,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    required this.isHome,
  });

  String get _label {
    final line = address.addressLine1.trim();
    if (line.isEmpty) return isHome ? 'Home' : 'Other';
    return isHome ? 'Home' : 'Other';
  }

  String get _fullAddress {
    final pieces = [
      address.addressLine1.trim(),
      address.city.trim(),
      address.state.trim(),
      address.pincode.trim(),
    ].where((v) => v.isNotEmpty).toList();
    return pieces.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x33D9D9D9),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                isHome
                    ? 'assets/images/icons/profile/home.svg'
                    : 'assets/images/icons/profile/navigation.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _label,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      enabled: !isLoading,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      menuPadding: const EdgeInsets.symmetric(vertical: 4),
                      constraints: const BoxConstraints(minWidth: 98, maxWidth: 98),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 6,
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/icons/profile/edit.svg',
                                width: 22,
                                height: 22,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF202124),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF202124),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w100,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'delete',
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/icons/profile/trash-2.svg',
                                width: 22,
                                height: 22,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF202124),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Color(0xFF202124),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w100,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  _fullAddress,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressFormPage extends StatefulWidget {
  final String accessToken;
  final Address? existing;
  final UserProfile profile;

  const _AddressFormPage({
    required this.accessToken,
    required this.existing,
    required this.profile,
  });

  @override
  State<_AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<_AddressFormPage> {
  late final TextEditingController _receiverName;
  late final TextEditingController _receiverNumber;
  late final TextEditingController _line1;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _saveAs;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _formScrollController = ScrollController();
  bool _useAccountDetails = false;

  @override
  void initState() {
    super.initState();
    _receiverName = TextEditingController(text: widget.profile.name);
    _receiverNumber = TextEditingController(text: widget.profile.phone);
    _line1 = TextEditingController(text: widget.existing?.addressLine1);
    _city = TextEditingController(text: widget.existing?.city);
    _state = TextEditingController(text: widget.existing?.state);
    _pincode = TextEditingController(text: widget.existing?.pincode);
    _saveAs = TextEditingController(text: 'Home');
  }

  @override
  void dispose() {
    _receiverName.dispose();
    _receiverNumber.dispose();
    _line1.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _saveAs.dispose();
    _formScrollController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existing != null) {
      context.read<ProfileBloc>().add(
        AddressUpdateRequested(
          accessToken: widget.accessToken,
          addressId: widget.existing!.id,
          addressLine1: _line1.text.trim(),
          city: _city.text.trim(),
          state: _state.text.trim(),
          pincode: _pincode.text.trim(),
        ),
      );
    } else {
      context.read<ProfileBloc>().add(
        AddressAddRequested(
          accessToken: widget.accessToken,
          addressLine1: _line1.text.trim(),
          city: _city.text.trim(),
          state: _state.text.trim(),
          pincode: _pincode.text.trim(),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final statusTop = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final previewAddress = [
      _line1.text.trim(),
      _city.text.trim(),
      _state.text.trim(),
      _pincode.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kProfileGradientHeaderSystemUi,
      child: Scaffold(
        // Keep layout geometry stable when the keyboard appears. Without
        // this, the body shrinks AND the inner scroll view + bottom-nav
        // already add `bottomInset` themselves, causing a double-shift that
        // pushes content off the top and shows a large blank/white area.
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                child: Form(
                  key: _formKey,
                  child: RawScrollbar(
                    controller: _formScrollController,
                    thumbVisibility: true,
                    trackVisibility: false,
                    radius: const Radius.circular(3.5),
                    thickness: 7,
                    thumbColor: const Color(0x80000000),
                    child: SingleChildScrollView(
                      controller: _formScrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        statusTop + 30,
                        20,
                        // 164 = bottom-nav clearance, + keyboard height so
                        // the focused field can scroll above the keyboard.
                        164 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Color(0xFFDFE7E9),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                previewAddress.isNotEmpty
                                    ? previewAddress
                                    : 'Enter address details',
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFFDFE7E9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Receiver Details'),
                        const SizedBox(height: 14),
                        _buildCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _useAccountDetails,
                                    visualDensity: const VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    checkColor: const Color(0xFF0F6876),
                                    activeColor: Colors.white,
                                    onChanged: (v) {
                                      setState(() {
                                        _useAccountDetails = v ?? false;
                                        if (_useAccountDetails) {
                                          _receiverName.text = widget.profile.name;
                                          _receiverNumber.text = widget.profile.phone;
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'Use my account details',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.3),
                                height: 8,
                              ),
                              const SizedBox(height: 4),
                              _field(
                                _receiverName,
                                'Receiver name*',
                                'Aashritha Mohan',
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              _field(
                                _receiverNumber,
                                'Receiver number*',
                                '9876543210',
                                isNumeric: true,
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Location Details'),
                        const SizedBox(height: 14),
                        _buildCard(
                          child: Column(
                            children: [
                              _field(
                                _line1,
                                'Building/ Floor',
                                'e.g. 996, 1st floor',
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              _field(
                                _city,
                                'Street (Recommended)',
                                'e.g. 25th main, 9th cross',
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              _field(
                                _state,
                                'Area',
                                'e.g. HSR Layout, Bangalore',
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              _field(
                                _pincode,
                                'Pin code',
                                'e.g. 560102',
                                isNumeric: true,
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              _field(
                                _saveAs,
                                'Save Address to',
                                'Home',
                                textColor: Colors.white,
                                hintColor: Colors.white.withValues(alpha: 0.5),
                                validator: (_) => null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _submit,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF09DFFF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 2,
                                shadowColor: Colors.black26,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: Text(
                                widget.existing != null
                                    ? 'Update Address'
                                    : 'Save Address',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.boldonse(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: const Color(0xFF12899B),
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
            // The Scaffold no longer resizes for the keyboard; the keyboard
            // simply overlays the bottom-nav. Adding `bottomInset` here would
            // shift the nav up off-screen, so we use a fixed bottom padding.
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: DashboardLinkedBottomNav(selectedTabIndex: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 0.9,
        ),
      ),
      child: child,
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumeric = false,
    Color textColor = AppColors.textPrimary,
    Color? hintColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextFormField(
                controller: ctrl,
                keyboardType:
                    isNumeric ? TextInputType.number : TextInputType.text,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: hintColor ?? Colors.black54,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: Colors.red.withValues(alpha: 0.65),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: Colors.red.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                  ),
                  errorStyle: GoogleFonts.montserrat(
                    color: const Color(0xFFFFB4B4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                validator:
                    validator ??
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
