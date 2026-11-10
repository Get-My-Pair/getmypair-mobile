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

/// Rate your pair’s glow-up — Figma Feedback (3398:4915).
class ServiceReviewPage extends StatefulWidget {
  const ServiceReviewPage({super.key, required this.request});

  final Map<String, dynamic> request;

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const _starAsset =
      'assets/images/icons/caremypair/rating_star.svg';

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
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 380;
    final r = widget.request;
    final brand = CareActiveJob.brand(r);
    final model = CareActiveJob.modelLine(r);
    final problemTitle = CareActiveJob.serviceOptionLabel(r);
    final serviceType = (r['serviceType'] ?? '').toString();
    final badge = CareActiveJob.serviceLabel(serviceType);
    final imageUrl = CareActiveJob.articleImageUrl(r);
    final badgeAsset = CareActiveJob.serviceBadgeAsset(serviceType);
    final canSubmit = _rating >= 1 && !_submitting;

    final hPad = narrow ? 16.0 : 22.0;
    final starGap = narrow ? 22.0 : 36.0;
    final imageW = narrow ? 96.0 : 118.0;
    final imageH = narrow ? 52.0 : 63.0;

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
                                  width: 38,
                                  height: 38,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Color(0xFF062F35),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Rate your pair's glow-up",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize: narrow ? 16 : 18,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              24,
                              hPad,
                              120 + bottomSafe,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Same summary block as Service History card (no Rate CTA).
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.boldonse(
                                              color: const Color(0xFF11899B),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            model,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.montserrat(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: imageW,
                                      height: imageH,
                                      child: imageUrl.isEmpty
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8EEEE),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.directions_walk_rounded,
                                                size: 28,
                                                color: Color(0xFF11899B),
                                              ),
                                            )
                                          : ArticleRackShoeImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        problemTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      height: 31,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF062F35),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            badgeAsset,
                                            width: 18,
                                            height: 18,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0xFF09E0FF),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            badge,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFF09E0FF),
                                              fontSize: narrow ? 11 : 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: narrow ? 22 : 26),
                                Text(
                                  'Rate your experience',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(5, (i) {
                                    final star = i + 1;
                                    final selected = star <= _rating;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _rating = star),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: starGap < 28 ? 2 : 0,
                                          vertical: 6,
                                        ),
                                        child: Opacity(
                                          opacity: selected ? 1 : 0.28,
                                          child: SvgPicture.asset(
                                            ServiceReviewPage._starAsset,
                                            width: 24,
                                            height: 23,
                                            colorFilter: ColorFilter.mode(
                                              selected
                                                  ? const Color(0xFF062F35)
                                                  : const Color(0xFF062F35),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                SizedBox(height: narrow ? 20 : 26),
                                Text(
                                  'Anything that can be improved?',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _commentController,
                                  minLines: 3,
                                  maxLines: 5,
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF062F35),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type here...',
                                    hintStyle: GoogleFonts.montserrat(
                                      color: const Color(0x8012899B),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0x1AFFFFFF),
                                    contentPadding: const EdgeInsets.all(12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0x6612899B),
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

                                SizedBox(height: narrow ? 32 : 42),
                                Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: narrow ? double.infinity : 241,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: canSubmit ? _submit : null,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Ink(
                                          width: narrow ? double.infinity : 241,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: canSubmit
                                                ? const LinearGradient(
                                                    begin:
                                                        Alignment.centerRight,
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
                                            boxShadow: canSubmit
                                                ? const [
                                                    BoxShadow(
                                                      color: Color(0x1A000000),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
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
                                                    style:
                                                        GoogleFonts.boldonse(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
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
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DashboardLinkedBottomNav(selectedTabIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}
