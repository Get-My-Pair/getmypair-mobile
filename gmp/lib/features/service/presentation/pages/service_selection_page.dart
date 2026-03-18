import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/profile/domain/usecases/get_user_profile.dart';
import 'package:gmp/injection_container.dart';

class ServiceSelectionPage extends StatefulWidget {
  final String articleId;

  const ServiceSelectionPage({super.key, required this.articleId});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String? _token;
  List<Address> _addresses = const [];
  Address? _selectedAddress;

  _ServiceOption? _selectedService;

  static const List<_ServiceOption> _options = [
    _ServiceOption(
      value: 'repair',
      title: 'Repair',
      subtitle: 'Fix soles, stitches, tears',
      icon: Icons.build_outlined,
    ),
    _ServiceOption(
      value: 'maintenance',
      title: 'Maintenance',
      subtitle: 'Polish, protect, refresh',
      icon: Icons.handyman_outlined,
    ),
    _ServiceOption(
      value: 'wash',
      title: 'Wash',
      subtitle: 'Deep clean and deodorize',
      icon: Icons.local_laundry_service_outlined,
    ),
    _ServiceOption(
      value: 'donate',
      title: 'Donate',
      subtitle: 'Give your pair a second life',
      icon: Icons.volunteer_activism_outlined,
    ),
    _ServiceOption(
      value: 'dispose',
      title: 'Dispose',
      subtitle: 'Responsible recycling',
      icon: Icons.delete_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
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
            _token = token;
            _addresses = profile.addresses;
            _selectedAddress = profile.addresses.isNotEmpty ? profile.addresses.first : null;
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
    if (_addresses.isEmpty) return;

    final picked = await showModalBottomSheet<Address>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pickup address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._addresses.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  title: Text(
                    a.addressLine1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${a.city}, ${a.state} - ${a.pincode}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: (_selectedAddress?.id == a.id)
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => Navigator.pop(ctx, a),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedAddress = picked);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_token == null) {
      setState(() => _error = 'Please sign in again');
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup address')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await sl<DioClient>().post(
        ApiEndpoints.serviceCreate,
        accessToken: _token,
        body: {
          'articleId': widget.articleId,
          'serviceType': _selectedService!.value,
          'addressId': _selectedAddress!.id,
          'photos': <String>[],
          'videos': <String>[],
        },
      );

      final requestId = (res['data'] is Map && (res['data'] as Map)['request'] is Map)
          ? ((res['data'] as Map)['request'] as Map)['_id']?.toString()
          : null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(requestId != null ? 'Request created ($requestId)' : 'Request created'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);

    if (_loading) {
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
            'Select Service',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Service',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _submitting ? null : _load,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
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
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose one service to create a request.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (_, i) {
              final opt = _options[i];
              final selected = _selectedService?.value == opt.value;
              return _ServiceCard(
                option: opt,
                selected: selected,
                onTap: _submitting ? null : () => setState(() => _selectedService = opt),
              );
            },
          ),
          const SizedBox(height: 18),
          _addressCard(),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Create Request',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
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
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
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
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              TextButton(
                onPressed: (!hasAddresses || _submitting) ? null : _pickAddress,
                child: Text(hasAddresses ? 'Change' : 'Add', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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

class _ServiceOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ServiceOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceOption option;
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
    final bg = selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected ? 2 : 1),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(option.icon, color: selected ? Colors.white : AppColors.textPrimary),
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.success)
                else
                  const Icon(Icons.radio_button_unchecked, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              option.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              option.subtitle,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

