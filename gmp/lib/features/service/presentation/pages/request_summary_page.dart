import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/service/data/service_proof_upload.dart';
import 'package:gmp/injection_container.dart';
import 'package:image_picker/image_picker.dart';

import 'service_selection_page.dart';

class RequestSummaryPage extends StatefulWidget {
  final String articleId;
  final ServiceOptionData service;
  final Address address;
  final List<XFile> proofImages;
  final List<XFile> proofVideos;
  final int estimatedCostRupees;
  final MaintenancePlanData? maintenancePlan;

  const RequestSummaryPage({
    super.key,
    required this.articleId,
    required this.service,
    required this.address,
    required this.proofImages,
    required this.proofVideos,
    required this.estimatedCostRupees,
    this.maintenancePlan,
  });

  @override
  State<RequestSummaryPage> createState() => _RequestSummaryPageState();
}

class _RequestSummaryPageState extends State<RequestSummaryPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Article? _article;
  num? _serviceCost;
  _CostDecision _costDecision = _CostDecision.pending;

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
          final a = await sl<GetArticleById>().call(token, widget.articleId);
          final defaultsRes =
              await sl<DioClient>().get(ApiEndpoints.serviceEstimationDefaults, accessToken: token);
          final defaults = ((defaultsRes['data'] as Map?)?['estimationDefaults'] as Map?) ?? const {};
          final currentServiceCost = defaults[widget.service.value];
          if (!mounted) return;
          setState(() {
            _article = a;
            _serviceCost = currentServiceCost is num ? currentServiceCost : null;
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

  String _formatCost(num? value) {
    if (value == null) return 'Not available';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  }

  Future<void> _confirmRequest() async {
    if (_submitting) return;
    if (_costDecision != _CostDecision.accepted) {
      setState(() {
        _error = 'Please accept the cost before continuing';
      });
      return;
    }
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

          final res = await sl<DioClient>().post(
            ApiEndpoints.serviceCreate,
            accessToken: token,
            body: {
              'articleId': widget.articleId,
              'serviceType': widget.service.value,
              'addressId': widget.address.id,
              'photos': photoUrls,
              'videos': videoUrls,
              'estimatedCost': widget.estimatedCostRupees,
            },
          );

          final requestId =
              (res['data'] is Map && (res['data'] as Map)['request'] is Map)
              ? ((res['data'] as Map)['request'] as Map)['_id']?.toString()
              : null;

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                requestId != null
                    ? 'Request created ($requestId)'
                    : 'Request created',
              ),
              backgroundColor: AppColors.success,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    return GradientPageShell(
      appBar: buildGradientAppBar(
        title: 'Request Summary',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
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
                _card(
                  title: 'Cost Approval',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actual cost: ${_formatCost(_serviceCost)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please accept to continue workflow details.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() {
                                        _costDecision = _CostDecision.rejected;
                                      }),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _costDecision == _CostDecision.rejected
                                      ? AppColors.error
                                      : AppColors.border,
                                ),
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() {
                                        _costDecision = _CostDecision.accepted;
                                      }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _costDecision == _CostDecision.accepted
                                    ? AppColors.success
                                    : AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                              ),
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_costDecision == _CostDecision.rejected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'You rejected this article request.',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (_costDecision == _CostDecision.accepted) ...[
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
                  title: 'Estimated cost',
                  child: Text(
                    widget.estimatedCostRupees == 0
                        ? '₹0 (no charge)'
                        : '₹${widget.estimatedCostRupees}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
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
                            separatorBuilder: (_, __) =>
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
                    _article == null
                        ? 'Article details unavailable'
                        : '${_article!.brand} ${_article!.model}\n${_article!.category}',
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
                    onPressed: _submitting || _article == null
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
                if (_article == null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loadArticle,
                    child: const Text('Retry loading article'),
                  ),
                ],
                ],
              ],
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
}

enum _CostDecision { pending, accepted, rejected }

