import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
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

  String get _flowPageTitle {
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

  String get _serviceDisplayTitle {
    switch (widget.service.value) {
      case 'maintenance':
        return 'Maintain My Pair';
      case 'wash':
        return 'Wash My Pair';
      case 'donate':
        return 'Donate My Pair';
      case 'dispose':
        return 'Dispose My Pair';
      default:
        return 'Repair My Pair';
    }
  }

  String get _confirmButtonLabel {
    switch (widget.service.value) {
      case 'donate':
        return 'All Set for Donation';
      case 'dispose':
        return 'All Set for Disposal';
      default:
        return 'Request Quotation';
    }
  }

  bool get _hideEstimationRow =>
      widget.service.value == 'donate' ||
      widget.service.value == 'dispose';

  bool get _articlesLoaded => _articles.isNotEmpty;

  String get _footwearDisplayName {
    if (!_articlesLoaded) return 'Loading...';
    return _articles
        .map((a) => '${a.brand} ${a.model}'.trim())
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  int get _totalEstimatedRupees =>
      widget.estimatedCostRupees * widget.articleIds.length;

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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
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
    final footwearName = _footwearDisplayName;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final problemText = widget.problemDescription?.trim().isNotEmpty == true
        ? widget.problemDescription!.trim()
        : 'Lorem ipsum dolor sit amet consectetur. Ut vitae libero lorem tincidunt egestas congue. Enim ultricies luctus porta ut.';

    const panelRadius = BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(50),
      bottomRight: Radius.circular(50),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
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
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF11999E)),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _submitting ? null : () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Color(0xFF062F35),
                                    size: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                  constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _flowPageTitle,
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Summary',
                              style: GoogleFonts.boldonse(
                                color: const Color(0xFF062F35),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _summaryLine('Type of service:', _serviceDisplayTitle),
                            _summaryLine('Name of my footwear:', footwearName),
                            _summaryLine(
                              'Pickup scheduled on:',
                              widget.pickupScheduleLabel ?? 'Not specified',
                              singleLineValue: true,
                            ),
                            if (!_hideEstimationRow)
                              _summaryLine(
                                'Estimation cost:',
                                widget.articleIds.length > 1
                                    ? '₹${widget.estimatedCostRupees} × ${widget.articleIds.length} = ₹$_totalEstimatedRupees'
                                    : '₹${widget.estimatedCostRupees}',
                              ),
                            _summaryLine('Problem described:', ''),
                            const SizedBox(height: 2),
                            Text(
                              problemText,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildProofPreviewStrip(),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                width: 237,
                                height: 48,
                                child: DecoratedBox(
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
                                  child: TextButton(
                                    onPressed: _submitting || !_articlesLoaded
                                        ? null
                                        : _confirmRequest,
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _confirmButtonLabel,
                                            style: GoogleFonts.boldonse(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DashboardLinkedBottomNav(selectedTabIndex: 1),
          ),
          SizedBox(height: bottomSafe),
        ],
      ),
    );
  }

  Widget _summaryLine(
    String key,
    String value, {
    bool singleLineValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: GoogleFonts.boldonse(
              color: const Color(0xFF12899B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofPreviewStrip() {
    final images = widget.proofImages;
    final videos = widget.proofVideos;
    if (images.isEmpty && videos.isEmpty) {
      return Text(
        'No proof photos or videos attached.',
        style: GoogleFonts.montserrat(
          color: const Color(0xFF8D8D8D),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: FutureBuilder(
                      future: images[index].readAsBytes(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Container(
                            color: const Color(0xFFD6D6D6),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF11999E),
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
                );
              },
            ),
          ),
        if (videos.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 10),
          Text(
            '${videos.length} video(s) attached: ${videos.map((v) => v.name).join(', ')}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
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

