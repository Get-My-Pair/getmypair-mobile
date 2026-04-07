import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/profile/domain/usecases/get_user_profile.dart';
import 'package:gmp/injection_container.dart';
import 'package:image_picker/image_picker.dart';

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
  final String articleId;

  const ServiceSelectionPage({super.key, required this.articleId});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
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

  final List<XFile> _proofImages = [];
  final List<XFile> _proofVideos = [];
  final ImagePicker _picker = ImagePicker();

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
            _addresses = profile.addresses;
            _selectedAddress = profile.addresses.isNotEmpty
                ? profile.addresses.first
                : null;
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
      if (list.isEmpty || !mounted) return;
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
      if (single != null && mounted && _proofImages.length < kMaxProofImages) {
        setState(() => _proofImages.add(single));
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

  void _removeImage(int index) {
    setState(() => _proofImages.removeAt(index));
  }

  void _removeVideo(int index) {
    setState(() => _proofVideos.removeAt(index));
  }

  void _onSelectService(ServiceOptionData opt) {
    setState(() {
      _selectedService = opt;
      if (opt.value != 'maintenance') {
        _selectedMaintenancePlan = null;
      }
    });
  }

  int? _resolvedEstimatedRupees() {
    final s = _selectedService?.value;
    switch (s) {
      case 'repair':
        return kRepairEstimateRupees;
      case 'wash':
        return kWashEstimateRupees;
      case 'maintenance':
        return _selectedMaintenancePlan?.priceRupees;
      case 'donate':
      case 'dispose':
        return 0;
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }
    if (_selectedService!.value == 'maintenance' &&
        _selectedMaintenancePlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a maintenance plan')),
      );
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup address')),
      );
      return;
    }

    final est = _resolvedEstimatedRupees();
    if (est == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resolve price for this service'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RequestSummaryPage(
          articleId: widget.articleId,
          service: _selectedService!,
          address: _selectedAddress!,
          proofImages: List<XFile>.from(_proofImages),
          proofVideos: List<XFile>.from(_proofVideos),
          estimatedCostRupees: est,
          maintenancePlan: _selectedService!.value == 'maintenance'
              ? _selectedMaintenancePlan
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

    if (_loading) {
      return GradientPageShell(
        appBar: buildGradientAppBar(
          title: 'Select Service',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GradientPageShell(
      appBar: buildGradientAppBar(
        title: 'Select Service',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
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
      return [
        _estimationCard(
          title: 'Estimated cost',
          amountRupees: 0,
          subtitle: 'No charge for this service type',
        ),
      ];
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
                separatorBuilder: (_, __) => const SizedBox(width: 8),
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
