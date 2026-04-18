import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
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

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAllAddresses = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
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

        final statusTop = MediaQuery.paddingOf(context).top;

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
                        gradient: BgTheme.authMarketingSweep,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          statusTop + 24,
                          20,
                          112,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: GoogleFonts.boldonse(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFDFE7E9),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSearchBar(),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    iconAsset:
                                        'assets/images/icons/profile/toggle-left.svg',
                                    label: 'Turn on Location',
                                    onTap: () {},
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
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _searchController,
        readOnly: true,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF2A2A2A),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search an area or address',
          hintStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0x57000000),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0x57000000)),
        ),
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
  final String iconAsset;
  final String label;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: const Color(0x33D9D9D9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 16,
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x33D9D9D9),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
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
                  children: [
                    Text(
                      _label,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 6,
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/icons/profile/edit.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF202124),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Edit',
                                style: TextStyle(color: Color(0xFF202124)),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/icons/profile/trash-2.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF202124),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFF202124)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fullAddress,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.25,
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
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  gradient: BgTheme.authMarketingSweep,
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, statusTop + 16, 20, 120),
                    child: Column(
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
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          previewAddress.isNotEmpty
                              ? previewAddress
                              : 'Enter address details',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFFDFE7E9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
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
                                height: 14,
                              ),
                              const SizedBox(height: 6),
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
                        const SizedBox(height: 28),
                        SizedBox(
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
                            ),
                            child: Text(
                              widget.existing != null
                                  ? 'Update Address'
                                  : 'Save Address',
                              style: GoogleFonts.boldonse(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: const Color(0xFF12899B),
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
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
              child: const DashboardLinkedBottomNav(selectedTabIndex: 2),
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
        border: Border.all(color: Colors.white),
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
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: hintColor ?? Colors.black54,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        errorStyle: GoogleFonts.montserrat(color: const Color(0xFFFFB4B4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      validator:
          validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}
