import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';
import 'profile_completion_page.dart';

/// Post-OTP AI intro: one scaffold, five steps, shared animated sky background.
class AiOnboardingPage extends StatefulWidget {
  const AiOnboardingPage({
    super.key,
    required this.mobile,
    required this.requiresProfileCompletion,
  });

  final String mobile;
  final bool requiresProfileCompletion;

  @override
  State<AiOnboardingPage> createState() => _AiOnboardingPageState();
}

class _AiOnboardingPageState extends State<AiOnboardingPage>
    with TickerProviderStateMixin {
  static const int _pageCount = 5;

  late final PageController _pageController;
  late final AnimationController _skyController;
  late final AnimationController _meshController;

  int _index = 0;

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _gender;

  final Set<String> _rackChoices = {};
  final Set<String> _troubleChoices = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _skyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _pageController.dispose();
    _skyController.dispose();
    _meshController.dispose();
    super.dispose();
  }

  String get _displayName {
    final n = _nicknameController.text.trim();
    return n.isEmpty ? 'there' : n;
  }

  bool get _canGoNext {
    switch (_index) {
      case 0:
        return _nicknameController.text.trim().length >= 2;
      case 1:
        final age = int.tryParse(_ageController.text.trim());
        return age != null && age > 0 && age < 130 && _gender != null;
      case 2:
        return _rackChoices.isNotEmpty;
      case 3:
        return _troubleChoices.isNotEmpty;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _goPrev() {
    if (_index <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    if (!_canGoNext) return;
    if (_index >= _pageCount - 1) {
      _finishToHome();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finishToHome() {
    if (widget.requiresProfileCompletion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileCompletionPage(mobile: widget.mobile),
        ),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerDashboardPage()),
        (route) => false,
      );
    }
  }

  void _toggleSkyMotion() {
    if (_skyController.isAnimating) {
      _skyController.stop();
      _meshController.stop();
    } else {
      _skyController.repeat();
      _meshController.repeat();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AnimatedSkyBackground(
            skyAnimation: _skyController,
            meshAnimation: _meshController,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: IconButton(
                      onPressed: _toggleSkyMotion,
                      icon: Icon(
                        _skyController.isAnimating ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFFDFE7E9),
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      _StepWelcome(
                        nicknameController: _nicknameController,
                        onChanged: () => setState(() {}),
                      ),
                      _StepAgeGender(
                        displayName: _displayName,
                        ageController: _ageController,
                        gender: _gender,
                        onAgeChanged: () => setState(() {}),
                        onGender: (g) => setState(() => _gender = g),
                      ),
                      _StepRackSetup(
                        selected: _rackChoices,
                        onChanged: () => setState(() {}),
                      ),
                      _StepShoeTroubles(
                        rackChoices: _rackChoices,
                        selected: _troubleChoices,
                        onChanged: () => setState(() {}),
                      ),
                      const _StepFootIntro(),
                    ],
                  ),
                ),
                _AiBottomPanel(
                  bottomInset: bottomInset,
                  pageIndex: _index,
                  pageCount: _pageCount,
                  canGoBack: _index > 0,
                  canGoNext: _canGoNext,
                  isLast: _index == _pageCount - 1,
                  onPrev: _goPrev,
                  onNext: _goNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSkyBackground extends StatelessWidget {
  const _AnimatedSkyBackground({
    required this.skyAnimation,
    required this.meshAnimation,
  });

  final Animation<double> skyAnimation;
  final Animation<double> meshAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([skyAnimation, meshAnimation]),
      builder: (context, child) {
        final t = skyAnimation.value * 2 * math.pi;
        final t2 = meshAnimation.value * 2 * math.pi;
        final t3 = (skyAnimation.value * 0.5 + meshAnimation.value * 0.5) * 2 * math.pi;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.sin(t) * 0.35 - 0.5,
                      -1.05 + math.cos(t * 0.9) * 0.14,
                    ),
                    end: Alignment(
                      math.cos(t * 0.65) * 0.38 + 0.42,
                      1.08 + math.sin(t * 0.55) * 0.12,
                    ),
                    colors: const [
                      Color(0xFF041E22),
                      Color(0xFF062F35),
                      Color(0xFF0F6876),
                      Color(0xFF2EC4D9),
                      Color(0xFFB8EAEF),
                    ],
                    stops: const [0.0, 0.22, 0.45, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SkyDriftPainter(phase: t3),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SkyMeshPainter(phase: t2),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Soft drifting “cloud” blobs for extra sky motion (parallax layer).
class _SkyDriftPainter extends CustomPainter {
  _SkyDriftPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paints = [
      Paint()..color = Colors.white.withValues(alpha: 0.07),
      Paint()..color = const Color(0xFF7FE8F5).withValues(alpha: 0.06),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    ];
    for (var i = 0; i < 5; i++) {
      final ox = math.sin(phase * 0.4 + i * 0.9) * size.width * 0.22;
      final oy = math.cos(phase * 0.35 + i * 0.7) * size.height * 0.14;
      final cx = size.width * (0.15 + (i % 3) * 0.28) + ox;
      final cy = size.height * (0.12 + (i % 2) * 0.18) + oy;
      final r = 55.0 + i * 38 + math.sin(phase + i) * 12;
      canvas.drawCircle(Offset(cx, cy), r, paints[i % paints.length]);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyDriftPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _SkyMeshPainter extends CustomPainter {
  _SkyMeshPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5 + math.sin(phase) * 42;
    final cy = size.height * 0.30 + math.cos(phase * 0.9) * 32;
    final wobble = math.sin(phase * 0.35) * 0.04;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Concentric oval “tunnel” lines (design reference).
    for (var i = 1; i <= 6; i++) {
      final rx = 42.0 * i + math.cos(phase * 0.5 + i) * 6;
      final ry = 28.0 * i + math.sin(phase * 0.45 + i * 0.7) * 5;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(wobble * i);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        paint,
      );
      canvas.restore();
    }

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;
    final ox = math.cos(phase * 0.4) * 40;
    for (double x = -size.width; x < size.width * 2; x += 44) {
      canvas.drawLine(
        Offset(x + ox, 0),
        Offset(x + ox + 20, size.height),
        grid,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyMeshPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Dark footer: visible **Previous / Next** controls + step dots + Voice row (same bg as design).
class _AiBottomPanel extends StatelessWidget {
  const _AiBottomPanel({
    required this.bottomInset,
    required this.pageIndex,
    required this.pageCount,
    required this.canGoBack,
    required this.canGoNext,
    required this.isLast,
    required this.onPrev,
    required this.onNext,
  });

  final double bottomInset;
  final int pageIndex;
  final int pageCount;
  final bool canGoBack;
  final bool canGoNext;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const Color _mint = Color(0xFFAFEDD6);
  static const Color _panel = Color(0xFF062F35);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _panel,
      elevation: 8,
      shadowColor: Colors.black45,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 0, maxWidth: constraints.maxWidth),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: canGoBack ? onPrev : null,
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 22,
                                  color: canGoBack ? _mint : _mint.withValues(alpha: 0.35),
                                ),
                                label: Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: canGoBack ? Colors.white : Colors.white.withValues(alpha: 0.38),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  minimumSize: const Size(80, 44),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(pageCount, (i) {
                                final active = i == pageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 20 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: active ? _mint : Colors.white.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonal(
                                onPressed: canGoNext ? onNext : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: canGoNext ? _mint : _mint.withValues(alpha: 0.35),
                                  foregroundColor: _panel,
                                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
                                  disabledForegroundColor: Colors.white38,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  minimumSize: const Size(84, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: canGoNext ? 2 : 0,
                                ),
                                child: Text(
                                  isLast ? 'Continue' : 'Next',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0x33FFFFFF)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    color: _mint.withValues(alpha: 0.95),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Voice',
                    style: TextStyle(
                      color: _mint,
                      fontSize: 16,
                      fontFamily: 'Boldonse',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepWelcome extends StatelessWidget {
  const _StepWelcome({
    required this.nicknameController,
    required this.onChanged,
  });

  final TextEditingController nicknameController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _body(
            "Welcome, Collector!\n\n"
            "I'm your AI friend here to help you nail the perfect fit, discover brands that work for you, and vibe with your style.\n\n"
            "But first let's get to know you better!",
          ),
          const SizedBox(height: 18),
          const _BoldQuestion(
            'What should we call you? Do you go by a nickname?',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nicknameController,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 18,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFFAFEDD6),
            decoration: InputDecoration(
              hintText: 'Your name or nickname',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontFamily: 'Montserrat',
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFAFEDD6), width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepAgeGender extends StatelessWidget {
  const _StepAgeGender({
    required this.displayName,
    required this.ageController,
    required this.gender,
    required this.onAgeChanged,
    required this.onGender,
  });

  final String displayName;
  final TextEditingController ageController;
  final String? gender;
  final VoidCallback onAgeChanged;
  final ValueChanged<String> onGender;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _body("$displayName! That's a great name!!"),
          const SizedBox(height: 18),
          const _BoldQuestion(
            "Now, let's get to know your age and gender...",
          ),
          const SizedBox(height: 20),
          const Text(
            'Age',
            style: TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 16,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            onChanged: (_) => onAgeChanged(),
            style: const TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 18,
              fontFamily: 'Montserrat',
            ),
            cursorColor: const Color(0xFFAFEDD6),
            decoration: InputDecoration(
              hintText: 'e.g. 28',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontFamily: 'Montserrat',
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFAFEDD6), width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Gender',
            style: TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 16,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Female', 'Male', 'Non-binary', 'Prefer not to say']
                .map(
                  (g) => ChoiceChip(
                    label: Text(g),
                    selected: gender == g,
                    onSelected: (_) => onGender(g),
                    selectedColor: const Color(0xFF0F6876),
                    labelStyle: TextStyle(
                      color: gender == g ? const Color(0xFFDFE7E9) : Colors.white70,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: gender == g
                          ? const Color(0xFFAFEDD6)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StepRackSetup extends StatelessWidget {
  const _StepRackSetup({
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final VoidCallback onChanged;

  static const _options = [
    'Just Me',
    'My Partner',
    'My Kids',
    'Elderly',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _body("Awesome! Let's start setting up the rack..."),
          const SizedBox(height: 18),
          const _BoldQuestion(
            'Is this rack just for you, or are we setting it up for your loved ones too?',
          ),
          const SizedBox(height: 22),
          ..._options.map((label) {
            final isOn = selected.contains(label);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (isOn) {
                    selected.remove(label);
                  } else {
                    selected.add(label);
                  }
                  onChanged();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOn
                          ? const Color(0xFFAFEDD6)
                          : Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(4),
                            color: isOn ? Colors.white : Colors.transparent,
                          ),
                          child: isOn
                              ? const Icon(Icons.check, size: 16, color: Color(0xFF062F35))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFFDFE7E9),
                            fontSize: 17,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepShoeTroubles extends StatelessWidget {
  const _StepShoeTroubles({
    required this.rackChoices,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> rackChoices;
  final Set<String> selected;
  final VoidCallback onChanged;

  static const _options = [
    'Hard to find the right fit!',
    'No strong support at heel.',
    'No extra room for toe',
    'Insole cushioning',
  ];

  String get _rackPhrase {
    if (rackChoices.contains('My Kids')) return 'Kids rack';
    if (rackChoices.contains('My Partner')) return 'Shared rack';
    if (rackChoices.contains('Elderly')) return 'Elderly rack';
    return 'Your rack';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _body(
            "$_rackPhrase, huh? That's awesome! We get to style you all up.\n\n"
            "But first, let's get you sorted before the others.",
          ),
          const SizedBox(height: 18),
          const _BoldQuestion('What shoe troubles do you run into most?'),
          const SizedBox(height: 22),
          ..._options.map((label) {
            final isOn = selected.contains(label);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (isOn) {
                    selected.remove(label);
                  } else {
                    selected.add(label);
                  }
                  onChanged();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOn
                          ? const Color(0xFFAFEDD6)
                          : Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(4),
                            color: isOn ? Colors.white : Colors.transparent,
                          ),
                          child: isOn
                              ? const Icon(Icons.check, size: 16, color: Color(0xFF062F35))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFFDFE7E9),
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepFootIntro extends StatelessWidget {
  const _StepFootIntro();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _body(
            "That sounds really frustrating.. we get it, and we're here to help fix those fit struggles.",
          ),
          const SizedBox(height: 18),
          const _BoldQuestion(
            "Let's get to know your foot type and size!",
          ),
        ],
      ),
    );
  }
}

class _BoldQuestion extends StatelessWidget {
  const _BoldQuestion(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFDFE7E9),
        fontSize: 22,
        fontFamily: 'Boldonse',
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
    );
  }
}

Widget _body(String text) {
  return Text(
    text,
    style: const TextStyle(
      color: Color(0xFFDFE7E9),
      fontSize: 16,
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
  );
}
