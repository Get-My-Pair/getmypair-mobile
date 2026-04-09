import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

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

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.footwearHeroStart,
                                AppColors.footwearHeroMid,
                                AppColors.footwearHeroEnd,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x38ABABAB),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontFamily: 'Boldonse',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFDFE7E9),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildSearchBar(),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ActionCard(
                                        icon: Icons.my_location_outlined,
                                        label: 'Turn on Location',
                                        onTap: () {},
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ActionCard(
                                        icon: Icons.add_box_outlined,
                                        label: 'Add New Address',
                                        onTap: isLoading
                                            ? null
                                            : () => _showAddressDialog(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 42),
                                const Text(
                                  'Saved Address',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
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
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
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
                                const SizedBox(height: 64),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 12, 0, 18),
                  child: _BottomPillNavigation(),
                ),
              ],
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
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF2A2A2A),
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search an area or address',
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0x57000000),
          ),
          prefixIcon: Icon(Icons.search, color: Color(0x57000000)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Text(
        'No saved addresses yet. Tap Add New Address to continue.',
        style: TextStyle(
          fontFamily: 'Montserrat',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _AddressFormSheet(
          accessToken: widget.accessToken,
          existing: address,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
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
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
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
          bottom: BorderSide(color: Colors.white.withOpacity(0.5)),
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
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(
              isHome ? Icons.home_outlined : Icons.navigation_outlined,
              color: Colors.white,
              size: 22,
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
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
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
                      color: const Color(0xFF10464F),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fullAddress,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
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

class _BottomPillNavigation extends StatelessWidget {
  const _BottomPillNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: 239,
      decoration: BoxDecoration(
        color: const Color(0xFF0B4A53),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Expanded(
              child: Icon(Icons.home_outlined, color: Colors.white),
            ),
            const Expanded(
              child: Icon(Icons.hiking_outlined, color: Colors.white),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF0B4A53),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final String accessToken;
  final Address? existing;

  const _AddressFormSheet({required this.accessToken, this.existing});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late final TextEditingController _line1;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _line1 = TextEditingController(text: widget.existing?.addressLine1);
    _city = TextEditingController(text: widget.existing?.city);
    _state = TextEditingController(text: widget.existing?.state);
    _pincode = TextEditingController(text: widget.existing?.pincode);
  }

  @override
  void dispose() {
    _line1.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing != null ? 'Edit Address' : 'Add Address',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _field(_line1, 'Address line', 'e.g. 996, 1st Floor'),
              const SizedBox(height: 10),
              _field(_city, 'City', 'e.g. Bangalore'),
              const SizedBox(height: 10),
              _field(_state, 'State', 'e.g. Karnataka'),
              const SizedBox(height: 10),
              _field(_pincode, 'Pincode', 'e.g. 560102', isNumeric: true),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.existing != null ? 'Update Address' : 'Save Address',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}
