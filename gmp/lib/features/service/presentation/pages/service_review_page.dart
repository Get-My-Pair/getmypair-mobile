import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/service/presentation/pages/service_review_thanks_page.dart';
import 'package:gmp/features/service/presentation/utils/care_active_job.dart';
import 'package:gmp/features/service/presentation/utils/care_service_review_store.dart';
import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';

/// Rate your pair’s glow-up — stars + optional comment.
class ServiceReviewPage extends StatefulWidget {
  const ServiceReviewPage({super.key, required this.request});

  final Map<String, dynamic> request;

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  State<ServiceReviewPage> createState() => _ServiceReviewPageState();
}

class _ServiceReviewPageState extends State<ServiceReviewPage> {
  int _rating = 0;
  bool _submitting = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _submitting) return;
    setState(() => _submitting = true);
    final id = CareActiveJob.requestId(widget.request);
    await CareServiceReviewStore.save(
      CareServiceReview(
        requestId: id,
        rating: _rating,
        comment: _commentController.text.trim(),
        submittedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (!mounted) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ServiceReviewThanksPage(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(done == true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final r = widget.request;
    final brand = CareActiveJob.brand(r);
    final model = CareActiveJob.modelLine(r);
    final option = CareActiveJob.serviceOptionLabel(r);
    final serviceType = (r['serviceType'] ?? '').toString();
    final badge = CareActiveJob.serviceLabel(serviceType);
    final imageUrl = CareActiveJob.articleImageUrl(r);
    final badgeAsset = CareActiveJob.serviceBadgeAsset(serviceType);
    final canSubmit = _rating >= 1 && !_submitting;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            ...ServiceRequestBgLayer.stackBehind(),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 30, 10, 0),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: ServiceRequestBgLayer.panelFill,
                    shape: const RoundedRectangleBorder(
                      borderRadius: ServiceReviewPage._panelRadius,
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: ServiceReviewPage._panelRadius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 26,
                                  height: 26,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Color(0xFF062F35),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Rate your pair's glow-up",
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              120 + bottomSafe,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            brand,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFF12899B),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            model,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFF062F35),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  option,
                                                  style: GoogleFonts.montserrat(
                                                    color:
                                                        const Color(0xFF062F35),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF062F35),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SvgPicture.asset(
                                                      badgeAsset,
                                                      width: 14,
                                                      height: 14,
                                                      colorFilter:
                                                          const ColorFilter
                                                              .mode(
                                                        Color(0xFF0CADC5),
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      badge,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 72,
                                        height: 56,
                                        child: imageUrl.isEmpty
                                            ? Container(
                                                color: const Color(0xFFE8EEEE),
                                                child: const Icon(
                                                  Icons
                                                      .directions_walk_rounded,
                                                  color: Color(0xFF12899B),
                                                ),
                                              )
                                            : ArticleRackShoeImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.contain,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'Rate your experience',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF5A5A5A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(5, (i) {
                                    final star = i + 1;
                                    final selected = star <= _rating;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () =>
                                            setState(() => _rating = star),
                                        customBorder: const CircleBorder(),
                                        child: Icon(
                                          selected
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 34,
                                          color: selected
                                              ? const Color(0xFF062F35)
                                              : const Color(0xFF8A9496),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Anything that can be improved?',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF5A5A5A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _commentController,
                                  maxLines: 5,
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF062F35),
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type here...',
                                    hintStyle: GoogleFonts.montserrat(
                                      color: const Color(0xFF8ADCE8),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF0F0F0),
                                    contentPadding: const EdgeInsets.all(14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF8ADCE8),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF12899B),
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Center(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: canSubmit ? _submit : null,
                                      borderRadius: BorderRadius.circular(100),
                                      child: Ink(
                                        width: 220,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: canSubmit
                                              ? const LinearGradient(
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                  colors: [
                                                    Color(0xFF0CADC5),
                                                    Color(0xFF063239),
                                                  ],
                                                )
                                              : null,
                                          color: canSubmit
                                              ? null
                                              : const Color(0xFFBDBDBD),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        child: Center(
                                          child: _submitting
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Submit',
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const DashboardLinkedBottomNav(selectedTabIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}
