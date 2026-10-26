import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/service/data/service_proof_upload.dart';
import 'package:gmp/injection_container.dart';
import 'package:image_picker/image_picker.dart';

import 'service_selection_page.dart';

class RequestSummaryPage extends StatefulWidget {
  final List<String> articleIds;
  final ServiceOptionData service;
  final Address address;
  final List<XFile> proofImages;
  final List<XFile> proofVideos;
  final int estimatedCostRupees;
  final MaintenancePlanData? maintenancePlan;
  final String? problemDescription;
  final String? pickupModeLabel;
  final String? pickupScheduleLabel;
  /// Matches API `pickupMode`: home pickup vs cobbler nearby.
  final bool homePickup;
  /// Matches API `requestedPickupAt` (ISO 8601) from the selected day + slot.
  final DateTime? requestedPickupAt;

  RequestSummaryPage({
    super.key,
    String? articleId,
    List<String>? articleIds,
    required this.service,
    required this.address,
    required this.proofImages,
    required this.proofVideos,
    required this.estimatedCostRupees,
    this.maintenancePlan,
    this.problemDescription,
    this.pickupModeLabel,
    this.pickupScheduleLabel,
    this.homePickup = true,
    this.requestedPickupAt,
  }) : assert(articleIds != null || articleId != null),
       articleIds = articleIds ?? [articleId!];

  @override
  State<RequestSummaryPage> createState() => _RequestSummaryPageState();
}

class _RequestSummaryPageState extends State<RequestSummaryPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Article> _articles = const [];

  bool get _isStyledSingleServiceSummary =>
      widget.service.value == 'repair' ||
      widget.service.value == 'maintenance' ||
      widget.service.value == 'wash' ||
      widget.service.value == 'donate' ||
      widget.service.value == 'dispose';

  String get _serviceDisplayTitle {
    switch (widget.service.value) {
      case 'maintenance':
        return 'MaintainMyPair';
      case 'wash':
        return 'WashMyPair';
      case 'donate':
        return 'DonateMyPair';
      case 'dispose':
        return 'DisposeMyPair';
      default:
        return 'RepairMyPair';
    }
  }

  String get _footwearDetailsLabel {
    if (!_articlesLoaded) return 'Loading...';
    return _articles
        .map((a) {
          final color = a.color.trim();
          final brand = a.brand.trim();
          if (color.isNotEmpty && brand.isNotEmpty) return '$color, $brand';
          if (brand.isNotEmpty) return brand;
          if (a.model.trim().isNotEmpty) return a.model.trim();
          return 'Footwear';
        })
        .join(' · ');
  }

  String get _repairShopLabel {
    final city = widget.address.city.trim();
    if (city.isNotEmpty) return city;
    final line = widget.address.addressLine1.trim();
    if (line.isNotEmpty) return line;
    return 'Nearby';
  }

  bool get _articlesLoaded => _articles.isNotEmpty;

  String get _footwearDisplayName {
    if (!_articlesLoaded) return 'Loading...';
    return _articles
        .map((a) => '${a.brand} ${a.model}'.trim())
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async => setState(() {
        _error = 'Please sign in again';
        _loading = false;
      }),
      (token) async {
        try {
          final loaded = <Article>[];
          for (final id in widget.articleIds) {
            loaded.add(await sl<GetArticleById>().call(token, id));
          }
          if (!mounted) return;
          setState(() {
            _articles = loaded;
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

  Future<void> _confirmRequest() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final photoUrls = <String>[];
          for (final f in widget.proofImages) {
            final url = await ServiceProofUpload.uploadImage(f, token);
            photoUrls.add(url);
          }
          final videoUrls = <String>[];
          for (final f in widget.proofVideos) {
            final url = await ServiceProofUpload.uploadVideo(f, token);
            videoUrls.add(url);
          }

          final desc = widget.problemDescription?.trim();
          final pickupAt = widget.requestedPickupAt;
          final plan = widget.maintenancePlan;
          final createdIds = <String>[];

          for (final articleId in widget.articleIds) {
            final body = <String, dynamic>{
              'articleId': articleId,
              'serviceType': widget.service.value,
              'addressId': widget.address.id,
              'photos': photoUrls,
              'videos': videoUrls,
              'estimatedCost': widget.estimatedCostRupees,
              'pickupMode': widget.homePickup ? 'home_pickup' : 'cobbler_nearby',
            };
            if (desc != null && desc.isNotEmpty) {
              body['problemDescription'] = desc;
            }
            if (pickupAt != null) {
              body['requestedPickupAt'] = pickupAt.toUtc().toIso8601String();
            }
            if (plan != null) {
              body['maintenancePlanId'] = plan.id;
              body['maintenancePlanLabel'] = plan.label;
            }

            final res = await sl<DioClient>().post(
              ApiEndpoints.serviceCreate,
              accessToken: token,
              body: body,
            );

            final requestId =
                (res['data'] is Map && (res['data'] as Map)['request'] is Map)
                    ? ((res['data'] as Map)['request'] as Map)['_id']?.toString()
                    : null;
            if (requestId != null) createdIds.add(requestId);
          }

          if (!mounted) return;
          final count = widget.articleIds.length;
          await showAppFeedbackAlert(
            context,
            message: count > 1
                ? '$count service requests created'
                : createdIds.isNotEmpty
                    ? 'Request created (${createdIds.first})'
                    : 'Request created',
            type: AppFeedbackType.success,
          );
          if (!mounted) return;
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    if (_isStyledSingleServiceSummary) {
      return _buildRepairSummaryPage();
    }

    return GradientPageShell(
      appBar: buildGradientAppBar(
        title: 'RepairMyPair',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: _submitting ? null : () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: _loading
          ? const AppSkeletonCards(
              color: Color(0x66FFFFFF),
            )
          : ListView(
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
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (widget.maintenancePlan != null) ...[
                  const SizedBox(height: 12),
                  _card(
                    title: 'Maintenance plan',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.maintenancePlan!.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '₹${widget.maintenancePlan!.priceRupees}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _card(
                  title: 'Summary',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Type of service', widget.service.title),
                      _row(
                        'Name of footwear',
                        _footwearDisplayName,
                      ),
                      _row(
                        'Pickup scheduled on',
                        widget.pickupScheduleLabel ?? 'Not specified',
                      ),
                      _row(
                        'Pickup mode',
                        widget.pickupModeLabel ?? 'Not specified',
                      ),
                      _row(
                        'Problem described',
                        widget.problemDescription?.isNotEmpty == true
                            ? widget.problemDescription!
                            : 'Not provided',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Request proof',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.proofImages.length} photo(s), ${widget.proofVideos.length} video(s)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (widget.proofImages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.proofImages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: FutureBuilder(
                                    future: widget.proofImages[i].readAsBytes(),
                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return Container(
                                          color: AppColors.surfaceVariant,
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
                      if (widget.proofVideos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...widget.proofVideos.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.videocam_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    v.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Pickup Address',
                  child: Text(
                    '${widget.address.addressLine1}\n${widget.address.city}, ${widget.address.state} - ${widget.address.pincode}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Article',
                  child: Text(
                    !_articlesLoaded
                        ? 'Article details unavailable'
                        : _articles.length == 1
                            ? '${_articles.first.brand} ${_articles.first.model}\n${_articles.first.category}'
                            : _footwearDisplayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_submitting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Uploading proof and creating request…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting || !_articlesLoaded
                        ? null
                        : _confirmRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm Request',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                if (!_articlesLoaded) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loadArticle,
                    child: const Text('Retry loading article'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildRepairSummaryPage() {
    final problemText = widget.problemDescription?.trim().isNotEmpty == true
        ? widget.problemDescription!.trim()
        : '—';

    const panelRadius = BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    );
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    const dockContentH = 58.0;
    final dockH = 14 + dockContentH + 14 + bottomSafe;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 52, 10, dockH - 12),
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  color: Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(borderRadius: panelRadius),
                  shadows: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: panelRadius,
                  child: _loading
                      ? const AppSkeletonCards()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            16,
                            20,
                            24,
                          ),
                          children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _submitting
                                            ? null
                                            : () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Color(0xFF062F35),
                                          size: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 26,
                                          height: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Confirming Service',
                                        style: GoogleFonts.boldonse(
                                          color: const Color(0xFF062F35),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Service Details',
                                    style: GoogleFonts.boldonse(
                                      color: const Color(0xFF062F35),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _detailRow(
                                    icon: Icons.handyman_outlined,
                                    label: 'Service Type',
                                    value: _serviceDisplayTitle,
                                  ),
                                  _detailRow(
                                    icon: Icons.storefront_outlined,
                                    label: widget.service.value == 'repair'
                                        ? 'Repair Shop'
                                        : 'Service Location',
                                    value: _repairShopLabel,
                                  ),
                                  _detailRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Slot Details',
                                    value: widget.pickupScheduleLabel ??
                                        'Not specified',
                                  ),
                                  _detailRow(
                                    icon: Icons.checkroom_outlined,
                                    label: 'Footwear Details',
                                    value: _footwearDetailsLabel,
                                  ),
                                  _detailRow(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: 'Reason for Service',
                                    value: problemText,
                                    multiline: true,
                                  ),
                                  _detailRow(
                                    icon: Icons.photo_camera_outlined,
                                    label: 'Problem Area Photos',
                                    value: '',
                                    trailing: _buildProofPreviewStripCompact(),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _error!,
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                          ],
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
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomSafe),
                child: _submitting
                    ? const SizedBox(
                        height: dockContentH,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF11899B),
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: dockContentH,
                        child: _SlideToConfirm(
                          enabled: _articlesLoaded && !_submitting,
                          onConfirmed: _confirmRequest,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
    Widget? trailing,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE7E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0F6876),
                    width: 1.3,
                  ),
                ),
                child: Icon(icon, color: const Color(0xFF11899B), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF11899B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (value.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: multiline ? 6 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF5A5A5A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 10),
                      trailing,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD7DEE0)),
      ],
    );
  }

  Widget _buildProofPreviewStripCompact() {
    final images = widget.proofImages;
    if (images.isEmpty) {
      return Text(
        'No photos attached',
        style: GoogleFonts.montserrat(
          color: const Color(0xFF8D8D8D),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 96,
              height: 72,
              child: FutureBuilder(
                future: images[index].readAsBytes(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return Container(color: const Color(0xFFDFE7E9));
                  }
                  return Image.memory(snap.data!, fit: BoxFit.cover);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideToConfirm extends StatefulWidget {
  final bool enabled;
  final VoidCallback onConfirmed;

  const _SlideToConfirm({
    required this.enabled,
    required this.onConfirmed,
  });

  @override
  State<_SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<_SlideToConfirm> {
  double _dx = 0;
  bool _fired = false;

  static const double _thumb = 52;
  static const double _height = 58;

  @override
  void didUpdateWidget(covariant _SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _dx != 0) {
      setState(() {
        _dx = 0;
        _fired = false;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDx) {
    if (!widget.enabled || _fired) return;
    setState(() {
      _dx = (_dx + details.delta.dx).clamp(0.0, maxDx);
    });
  }

  void _onDragEnd(double maxDx) {
    if (!widget.enabled || _fired) return;
    if (_dx >= maxDx * 0.85) {
      setState(() {
        _dx = maxDx;
        _fired = true;
      });
      widget.onConfirmed();
    } else {
      setState(() => _dx = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDx = (constraints.maxWidth - _thumb - 8).clamp(0.0, 400.0);
        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: const Color(0xFFE4E4E4),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Slide to confirm',
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF9A9A9A),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Positioned(
                right: 16,
                child: Icon(
                  Icons.storefront_outlined,
                  color: const Color(0xFF11899B).withValues(alpha: 0.85),
                  size: 26,
                ),
              ),
              Positioned(
                left: 4 + _dx,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.enabled
                      ? (d) => _onDragUpdate(d, maxDx)
                      : null,
                  onHorizontalDragEnd:
                      widget.enabled ? (_) => _onDragEnd(maxDx) : null,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.enabled
                            ? const [Color(0xFF09DFFF), Color(0xFF063035)]
                            : const [Color(0xFF9BB5BA), Color(0xFF6A8186)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.checkroom_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

