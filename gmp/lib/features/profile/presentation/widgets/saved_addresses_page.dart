import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/user_profile.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';

class SavedAddressesPage extends StatelessWidget {
  final UserProfile profile;
  final String accessToken;

  const SavedAddressesPage({
    super.key,
    required this.profile,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    : profile;

        final isLoading = state is AddressActionLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Saved Addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: currentProfile.addresses.isEmpty
              ? _buildEmpty(context)
              : ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  children: [
                    ...currentProfile.addresses.map((address) =>
                        _AddressCard(
                          address: address,
                          isLoading: isLoading,
                          onEdit: () => _showAddressDialog(
                              context, address: address),
                          onDelete: () => _confirmDelete(
                              context, address),
                        )),
                    const SizedBox(height: 80),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isLoading
                ? null
                : () => _showAddressDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined,
              size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No saved addresses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an address to get started',
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddressDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Address address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              context.read<ProfileBloc>().add(AddressDeleteRequested(
                    accessToken: accessToken,
                    addressId: address.id,
                  ));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _AddressFormSheet(
          accessToken: accessToken,
          existing: address,
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.addressLine1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${address.city}, ${address.state} - ${address.pincode}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              TextButton(
                onPressed: isLoading ? null : onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 32),
                ),
                child: const Text('Edit',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: isLoading ? null : onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 32),
                ),
                child: const Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
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
      context.read<ProfileBloc>().add(AddressUpdateRequested(
            accessToken: widget.accessToken,
            addressId: widget.existing!.id,
            addressLine1: _line1.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            pincode: _pincode.text.trim(),
          ));
    } else {
      context.read<ProfileBloc>().add(AddressAddRequested(
            accessToken: widget.accessToken,
            addressLine1: _line1.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            pincode: _pincode.text.trim(),
          ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null ? 'Edit Address' : 'Add Address',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _field(_line1, 'Address Line 1', 'e.g. 28, Anna Nagar'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field(_city, 'City', 'e.g. Chennai')),
              const SizedBox(width: 12),
              Expanded(child: _field(_state, 'State', 'e.g. Tamil Nadu')),
            ]),
            const SizedBox(height: 14),
            _field(_pincode, 'Pincode', '6 digits', isNumeric: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.existing != null ? 'Update Address' : 'Save Address',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {bool isNumeric = false}) {
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}
