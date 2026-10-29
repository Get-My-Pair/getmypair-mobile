import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';

/// Payment step after Confirming Service (slide to confirm).
class PurchaseSummaryPage extends StatefulWidget {
  final String serviceTitle;
  /// Base amount before GST (from service estimate / plan price).
  final int advanceRupees;
  /// Returns `null` on success, otherwise an error message.
  final Future<String?> Function() onMakePayment;

  const PurchaseSummaryPage({
    super.key,
    required this.serviceTitle,
    required this.advanceRupees,
    required this.onMakePayment,
  });

  @override
  State<PurchaseSummaryPage> createState() => _PurchaseSummaryPageState();
}

class _PurchaseSummaryPageState extends State<PurchaseSummaryPage> {
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  bool _paying = false;

  int get _taxRupees => ((widget.advanceRupees * 18) / 100).round();
  int get _totalRupees => widget.advanceRupees + _taxRupees;

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    final error = await widget.onMakePayment();
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _paying = false);
    await showAppFeedbackAlert(
      context,
      message: error,
      type: AppFeedbackType.failure,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                  shadows: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: _panelRadius,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _paying ? null : () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF062F35),
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              constraints: const BoxConstraints.tightFor(
                                width: 24,
                                height: 24,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Purchase Summary',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 28),
                      Text(
                        'Payment Details',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFF062F35),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ServiceTypeRow(
                        title: widget.serviceTitle,
                      ),
                      const SizedBox(height: 8),
                      _AmountRow(
                        label: 'Advance Payment',
                        amount: '₹${widget.advanceRupees}',
                      ),
                      _AmountRow(
                        label: 'Taxes (18% GST)',
                        amount: '₹$_taxRupees',
                      ),
                      _AmountRow(
                        label: 'Total Payable Amount',
                        amount: '₹$_totalRupees',
                        amountBold: true,
                        showDivider: false,
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
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(width: 1, color: Color(0xFFD5D5D5)),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomSafe),
              child: SizedBox(
                height: dockContentH,
                child: _paying
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF12899B),
                          ),
                        ),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pay,
                          borderRadius: BorderRadius.circular(100),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFF0CADC5),
                                  Color(0xFF063239),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Make Payment ',
                                      style: GoogleFonts.boldonse(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '₹',
                                      style: GoogleFonts.boldonse(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$_totalRupees',
                                      style: GoogleFonts.boldonse(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }
}

class _ServiceTypeRow extends StatelessWidget {
  final String title;

  const _ServiceTypeRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 20),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0x33D9D9D9),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFF12899B),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/icons/profile/serv.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF12899B),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Type',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF12899B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF5A5A5A),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool amountBold;
  final bool showDivider;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.amountBold = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF12899B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF5A5A5A),
                  fontSize: 16,
                  fontWeight: amountBold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}
