import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/service/presentation/utils/care_active_job.dart';
import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Your Pair's Progress" — Masteradmin problem-wise steps; 1 step / estimate day.
class PairProgressPage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic>? initialRequest;

  const PairProgressPage({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  @override
  State<PairProgressPage> createState() => _PairProgressPageState();
}

class _PairProgressPageState extends State<PairProgressPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _request;
  List<CareProgressStep> _steps = const [];
  int _estimateDays = CareActiveJob.defaultEstimateDays;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    final type = (_request?['serviceType'] ?? 'repair').toString();
    _steps = CareActiveJob.fallbackProgressSteps(type);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _request == null;
      _error = null;
    });
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final res = await sl<DioClient>().get(
            ApiEndpoints.serviceById(widget.requestId),
            accessToken: token,
          );
          final req =
              ((res['data'] as Map<String, dynamic>?)?['request'] as Map?) ??
                  ((res['data'] as Map?)?['serviceRequest'] as Map?);
          final request = req == null
              ? _request
              : Map<String, dynamic>.from(req);

          var steps = CareActiveJob.fallbackProgressSteps(
            (request?['serviceType'] ?? 'repair').toString(),
          );
          var estimateDays = CareActiveJob.defaultEstimateDays;

          final code = request == null ? '' : CareActiveJob.problemCodeOf(request);
          final serviceType = (request?['serviceType'] ?? '').toString();
          if (code.isNotEmpty) {
            try {
              final prog = await sl<DioClient>().get(
                ApiEndpoints.serviceCareProgress(
                  code: code,
                  serviceType: serviceType,
                ),
                accessToken: token,
              );
              final data = (prog['data'] is Map)
                  ? Map<String, dynamic>.from(prog['data'] as Map)
                  : <String, dynamic>{};
              final rawSteps = data['progressSteps'] ??
                  (data['item'] is Map
                      ? (data['item'] as Map)['progressSteps']
                      : null);
              steps = CareActiveJob.parseProgressSteps(
                rawSteps,
                serviceType: serviceType,
              );
              final daysRaw = data['estimateDays'] ??
                  (data['item'] is Map
                      ? (data['item'] as Map)['estimateDays']
                      : null);
              if (daysRaw is num && daysRaw >= 1) {
                estimateDays = daysRaw.round();
              } else {
                final parsed = int.tryParse(daysRaw?.toString() ?? '');
                if (parsed != null && parsed >= 1) estimateDays = parsed;
              }
            } catch (_) {
              // Keep fallbacks when progress API is unavailable.
            }
          }

          if (!mounted) return;
          setState(() {
            _request = request;
            _steps = steps;
            _estimateDays = estimateDays;
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            if (_request == null) {
              _error = e.toString().replaceFirst('Exception: ', '');
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final r = _request;
    final steps = _steps.isEmpty
        ? CareActiveJob.fallbackProgressSteps(
            (r?['serviceType'] ?? 'repair').toString(),
          )
        : _steps;
    final current = r == null
        ? 0
        : CareActiveJob.currentProgressIndex(
            r,
            stepCount: steps.length,
            estimateDays: _estimateDays,
          );
    final inProgress = r != null && CareActiveJob.isActiveCareRequest(r);

    final bottomPad = 16.0 + bottomSafe;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ...ServiceRequestBgLayer.stackBehind(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 30, 10, bottomPad),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: ServiceRequestBgLayer.panelFill,
                  shape: const RoundedRectangleBorder(
                    borderRadius: PairProgressPage._panelRadius,
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
                  borderRadius: PairProgressPage._panelRadius,
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
                                "Your Pair's Progress",
                                style: GoogleFonts.boldonse(
                                  color: const Color(0xFF062F35),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                        child: Row(
                          children: [
                            _pill(
                              label: 'Timeline',
                              filled: true,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: CustomPaint(
                                  painter: _DashedLinePainter(
                                    color: Colors.black.withValues(alpha: 0.30),
                                  ),
                                  child: const SizedBox(height: 1),
                                ),
                              ),
                            ),
                            _pill(
                              label: inProgress ? 'In Progress' : 'Done',
                              filled: true,
                              color: inProgress
                                  ? const Color(0xFF0FB700)
                                  : const Color(0xFF12899B),
                              leading: _ProgressCheckIcon(
                                size: 16,
                                style: inProgress
                                    ? _ProgressCheckStyle.inProgress
                                    : _ProgressCheckStyle.done,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading && r == null
                            ? const AppSkeletonCards()
                            : _error != null && r == null
                                ? Center(
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.montserrat(
                                        color: const Color(0xFFB00020),
                                      ),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      const topPad = 28.0;
                                      const bottomListPad = 24.0;
                                      // ~row content height (icon + 1–2 lines)
                                      const rowContent = 40.0;
                                      final usable = (constraints.maxHeight -
                                              topPad -
                                              bottomListPad)
                                          .clamp(0.0, double.infinity);
                                      final gaps =
                                          (steps.length - 1).clamp(1, 100);
                                      final fillMid = (usable -
                                              steps.length * rowContent) /
                                          gaps;
                                      // Equal gaps between steps; bump min a little.
                                      final midSpace =
                                          fillMid.clamp(28.0, 84.0).toDouble();

                                      return RefreshIndicator(
                                        color: const Color(0xFF11999E),
                                        onRefresh: _load,
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            topPad,
                                            18,
                                            bottomListPad,
                                          ),
                                          itemCount: steps.length,
                                          itemBuilder: (_, i) {
                                            final step = steps[i];
                                            final done = i < current;
                                            final active = i == current;
                                            final pending = i > current;
                                            final when = r == null
                                                ? null
                                                : CareActiveJob
                                                    .stepCompletedAt(
                                                    r,
                                                    i,
                                                    stepCount: steps.length,
                                                    estimateDays:
                                                        _estimateDays,
                                                  );
                                            return _TimelineRow(
                                              title: step.title,
                                              subtitle: i == 0
                                                  ? (step.subtitle ??
                                                      CareActiveJob
                                                          .serviceLabel(
                                                        (r?['serviceType'] ??
                                                                '')
                                                            .toString(),
                                                      ))
                                                  : step.subtitle,
                                              timeLabel: pending
                                                  ? '.....'
                                                  : CareActiveJob
                                                      .formatStepTime(
                                                      when,
                                                    ),
                                              done: done,
                                              active: active,
                                              isLast: i == steps.length - 1,
                                              midSpace: midSpace,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool filled,
    required Color color,
    Widget? leading,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 12,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProgressCheckStyle { done, pending, inProgress }

/// Matches Figma: filled teal + white check (done), grey ring + grey check
/// (pending), green ring + green check (in progress badge).
class _ProgressCheckIcon extends StatelessWidget {
  final double size;
  final _ProgressCheckStyle style;

  const _ProgressCheckIcon({
    required this.size,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _ProgressCheckStyle.done:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF12899B),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: size * 0.62,
            color: Colors.white,
          ),
        );
      case _ProgressCheckStyle.inProgress:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingCheckPainter(
              color: const Color(0xFF0FB700),
              strokeWidth: size * 0.09,
            ),
          ),
        );
      case _ProgressCheckStyle.pending:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingCheckPainter(
              color: const Color(0xFFB0B0B0),
              strokeWidth: size * 0.08,
            ),
          ),
        );
    }
  }
}

class _RingCheckPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _RingCheckPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, ring);

    final check = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.34);
    canvas.drawPath(path, check);
  }

  @override
  bool shouldRepaint(covariant _RingCheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String timeLabel;
  final bool done;
  final bool active;
  final bool isLast;
  final double midSpace;

  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.done,
    required this.active,
    required this.isLast,
    required this.midSpace,
  });

  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF12899B);
    final muted = const Color(0xFF9AA4A6);
    final titleColor = (done || active) ? teal : muted;
    final timeColor = (done || active) ? const Color(0xFF5A6B6E) : muted;
    final gap = isLast ? 0.0 : midSpace;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _ProgressCheckIcon(
                  size: 22,
                  style: done || active
                      ? _ProgressCheckStyle.done
                      : _ProgressCheckStyle.pending,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF898989),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.montserrat(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeLabel,
                    style: GoogleFonts.montserrat(
                      color: timeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
