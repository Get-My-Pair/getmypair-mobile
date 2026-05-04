import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/features/auth/presentation/pages/onboarding/onboarding_bottom_progress.dart';
import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';

import 'profile_completion_page.dart';

/// Display fonts (e.g. Boldonse) use tall metrics; without this, labels can clip in Material buttons.
const TextHeightBehavior _kOnboardingButtonTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

String _normalizeSpeech(String raw) {
  return raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _aiOnboardingBody(int index, String nickname) {
  switch (index) {
    case 0:
      return 'Welcome, Collector!\n\nI\u2019m your AI friend KIX!\n\nI\u2019m here to help you nail the perfect fit, discover brands that work for you, and vibe with your style.\n\nBut first let\u2019s get to know you better!';
    case 1:
      return '$nickname! That\u2019s a great name!!';
    case 2:
      return 'Awesome!\nLet\u2019s start setting up the rack...';
    case 3:
      return 'Kids rack, huh?\nThat\u2019s awesome! We get to style you all up.\n\nBut first, let\u2019s get you sorted before the others.';
    case 4:
      return 'Looks like your size is\nUS 10\nUK 09\nEU 41\n\nAnd it seems like you have wide feet...\n\nNot to worry we know the right brands that will fit you...';
    case 5:
      return 'That sounds really frustrating..\nwe get it, and we\u2019re here to help\nfix those fit struggles.';
    case 6:
      return 'That sounds really frustrating..\nwe get it, and we\u2019re here to help\nfix those fit struggles.\n\n'
          'When you are ready, use the button below to allow camera access so we can help measure your feet.';
    default:
      return '';
  }
}

String _aiOnboardingTitle(int index) {
  switch (index) {
    case 0:
      return 'What should we call you?\nDo you go by a nickname?';
    case 1:
      return 'Now, let\u2019s get to know\nyour age and gender...';
    case 2:
      return 'Is this rack just for you, or\nare we setting it up for\nyour loved ones too?';
    case 3:
      return 'What shoe troubles do you run into most?';
    case 4:
      return 'Before that let\u2019s\nunderstand your kids needs too...';
    case 5:
    case 6:
      return 'Let\u2019s get to know your\nfoot type and size!';
    default:
      return '';
  }
}

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
    with SingleTickerProviderStateMixin {
  static const int _pageCount = 7;

  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  AnimationController? _bgGradientController;

  int _index = 0;
  String? _gender;
  bool _cameraAllowed = false;
  final Set<String> _rack = <String>{};
  final Set<String> _troubles = <String>{};
  bool _ttsReady = false;
  String? _ttsError;
  String? _selectedVoiceName;

  /// True while audio is actively playing (not paused).
  bool _ttsPlaying = false;

  /// True after user paused mid-utterance (resume uses same full text).
  bool _ttsPaused = false;

  /// Full utterance for the current page (used for Android resume after pause).
  String _fullUtterance = '';

  @override
  void initState() {
    super.initState();
    _ensureBgGradientController();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_initTts()));
  }

  Future<void> _initTts() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _ttsReady = false;
          _ttsError = null;
        });
      }
      return;
    }
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _setPreferredFemaleVoice();
      _tts.setStartHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsPlaying = true;
          _ttsPaused = false;
        });
      });
      _tts.setPauseHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = true;
        });
      });
      _tts.setContinueHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsPlaying = true;
          _ttsPaused = false;
        });
      });
      _tts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = false;
        });
      });
      _tts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = false;
        });
      });
      _tts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _ttsPlaying = false;
            _ttsPaused = false;
            _ttsError = msg;
          });
        }
      });
      if (mounted) {
        setState(() {
          _ttsReady = true;
          _ttsError = null;
        });
        unawaited(_autoSpeakCurrentPage());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ttsReady = false;
          _ttsError = 'Text-to-speech is not available on this device';
        });
      }
    }
  }

  Future<void> _setPreferredFemaleVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List || voices.isEmpty) return;

      final candidates = voices.whereType<Map>().toList();
      if (candidates.isEmpty) return;

      final preferredNameHints = <String>[
        'female',
        'woman',
        'samantha',
        'victoria',
        'karen',
        'moira',
        'allison',
        'ava',
        'aria',
        'jenny',
        'zira',
        'hazel',
      ];

      Map? selected;
      for (final voice in candidates) {
        final locale = (voice['locale'] ?? '').toString().toLowerCase();
        final name = (voice['name'] ?? '').toString().toLowerCase();
        final isEnglishUs = locale.contains('en-us') || locale.contains('en_us');
        final isPreferredName = preferredNameHints.any(name.contains);
        if (isEnglishUs && isPreferredName) {
          selected = voice;
          break;
        }
      }

      selected ??= candidates.firstWhere(
        (voice) {
          final locale = (voice['locale'] ?? '').toString().toLowerCase();
          final name = (voice['name'] ?? '').toString().toLowerCase();
          final isEnglishUs = locale.contains('en-us') || locale.contains('en_us');
          final isPreferredName = preferredNameHints.any(name.contains);
          return isEnglishUs && isPreferredName;
        },
        orElse: () => candidates.firstWhere(
          (voice) {
            final locale = (voice['locale'] ?? '').toString().toLowerCase();
            return locale.contains('en-us') || locale.contains('en_us');
          },
          orElse: () => candidates.first,
        ),
      );

      final selectedName = (selected['name'] ?? '').toString();
      final selectedLocale = (selected['locale'] ?? '').toString();

      if (selectedName.isEmpty || selectedLocale.isEmpty) return;

      await _tts.setVoice({'name': selectedName, 'locale': selectedLocale});

      if (mounted) {
        setState(() {
          _selectedVoiceName = selectedName;
        });
      }
    } catch (_) {
      // Keep default system voice if a specific female voice is unavailable.
    }
  }

  String _speakableContentFor(int index) {
    final nickname = _name.text.trim().isEmpty ? 'Aashi' : _name.text.trim();
    final body = _aiOnboardingBody(index, nickname);
    final title = _aiOnboardingTitle(index);
    return _normalizeSpeech('$body $title');
  }

  Future<void> _stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _ttsPlaying = false;
        _ttsPaused = false;
      });
    }
  }

  Future<void> _safeStopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _autoSpeakCurrentPage() async {
    if (!_ttsReady || !mounted) return;
    final text = _speakableContentFor(_index);
    if (text.isEmpty) return;
    _fullUtterance = text;
    try {
      final result = await _tts.speak(text);
      if (result != 1 && mounted) {
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to play voice on this device'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to play voice on this device'),
          ),
        );
      }
    }
  }

  Future<void> _replayUtteranceFromStart() async {
    if (!_ttsReady) return;
    final text = _speakableContentFor(_index);
    if (text.isEmpty) return;
    await _stopSpeaking();
    if (!mounted) return;
    setState(() {
      _fullUtterance = text;
    });
    unawaited(_autoSpeakCurrentPage());
  }

  Future<void> _onVoiceControlTap() async {
    if (!_ttsReady) return;
    if (_ttsPlaying) {
      try {
        await _tts.pause();
      } catch (_) {}
      return;
    }
    if (_ttsPaused) {
      if (_fullUtterance.isEmpty) return;
      try {
        final result = await _tts.speak(_fullUtterance);
        if (result != 1 && mounted) {
          setState(() {
            _ttsPlaying = false;
            _ttsPaused = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to resume voice on this device'),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _ttsPlaying = false;
            _ttsPaused = false;
          });
        }
      }
      return;
    }
    await _replayUtteranceFromStart();
  }

  Future<void> _onPageChanged(int i) async {
    await _stopSpeaking();
    if (!mounted) return;
    final spoken = _speakableContentFor(i);
    setState(() {
      _index = i;
      _fullUtterance = spoken;
    });
    unawaited(_autoSpeakCurrentPage());
  }

  void _ensureBgGradientController() {
    _bgGradientController ??=
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3000),
        )..repeat(reverse: true);
  }

  @override
  void dispose() {
    unawaited(_safeStopTts());
    _bgGradientController?.dispose();
    _name.dispose();
    _age.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_index) {
      case 0:
        return _name.text.trim().isNotEmpty;
      case 1:
        return _age.text.trim().isNotEmpty && _gender != null;
      case 2:
        return _rack.isNotEmpty;
      case 3:
        return _troubles.isNotEmpty;
      case 4:
      case 5:
        return true;
      case 6:
        return _cameraAllowed;
      default:
        return false;
    }
  }

  void _prev() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (!_canNext) return;
    if (_index == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    if (widget.requiresProfileCompletion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileCompletionPage(mobile: widget.mobile),
        ),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerDashboardPage()),
        (_) => false,
      );
    }
  }

  Future<void> _onCameraTap() async {
    if (_cameraAllowed) return;
    setState(() => _cameraAllowed = true);
  }

  @override
  Widget build(BuildContext context) {
    _ensureBgGradientController();
    final bgGradientController = _bgGradientController!;
    final nick = _name.text.trim().isEmpty ? 'Aashi' : _name.text.trim();
    final steps = <Widget>[      _Step(
        text: _aiOnboardingBody(0, nick),
        title: _aiOnboardingTitle(0),
        child: _Input(
          controller: _name,
          hint: 'Enter nickname',
          onChanged: () => setState(() {}),
        ),
      ),
      _Step(
        text: _aiOnboardingBody(1, nick),
        title: _aiOnboardingTitle(1),
        child: Column(
          children: [
            _Input(
              controller: _age,
              hint: 'Age',
              numeric: true,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Female', 'Male', 'Other'].map((g) {
                final selected = _gender == g;
                return ElevatedButton(
                  onPressed: () => setState(() => _gender = g),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    foregroundColor: selected
                        ? const Color(0xFF12899B)
                        : const Color(0xFFDFE7E9),
                    elevation: selected ? 2 : 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF09DFFF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    g,
                    textHeightBehavior: _kOnboardingButtonTextHeight,
                    style: GoogleFonts.boldonse(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      _Step(
        text: _aiOnboardingBody(2, nick),
        title: _aiOnboardingTitle(2),
        child: _Checks(
          options: const ['Just Me', 'My Partner', 'My Kids', 'Elderly'],
          selected: _rack,
          onChanged: () => setState(() {}),
        ),
      ),
      _Step(
        text: _aiOnboardingBody(3, nick),
        title: _aiOnboardingTitle(3),
        child: _Checks(
          options: const [
            'Hard to find the right fit!',
            'No strong support at heel.',
            'No extra room for toe',
            'Insole cushioning',
          ],
          selected: _troubles,
          onChanged: () => setState(() {}),
        ),
      ),
      _Step(
        text: _aiOnboardingBody(4, nick),
        title: _aiOnboardingTitle(4),
      ),
      _Step(
        text: _aiOnboardingBody(5, nick),
        title: _aiOnboardingTitle(5),
      ),
      _Step(
        text: _aiOnboardingBody(6, nick),
        title: _aiOnboardingTitle(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _cameraAllowed ? null : _onCameraTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cameraAllowed
                    ? const Color(0xFFABABAB)
                    : Colors.white,
                foregroundColor: _cameraAllowed
                    ? const Color(0xFF5A5A5A)
                    : const Color(0xFF12899B),
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                side: const BorderSide(
                  color: Color(0xFF09DFFF),
                  width: 1,
                ),
              ),
              child: Text(
                _cameraAllowed ? 'Camera Allowed' : 'Allow Camera Access',
                textAlign: TextAlign.center,
                textHeightBehavior: _kOnboardingButtonTextHeight,
                style: GoogleFonts.boldonse(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),

    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: bgGradientController,
            builder: (context, child) {
              final t = bgGradientController.value;
              final begin =
                  Alignment.lerp(Alignment.topLeft, Alignment.bottomLeft, t)!;
              final end =
                  Alignment.lerp(Alignment.bottomRight, Alignment.topRight, t)!;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: [
                      Color.lerp(
                        const Color(0xFF061F40),
                        const Color(0xFF12355F),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF16517C),
                        const Color(0xFF2A73A5),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF4EA8C5),
                        const Color(0xFF82CDE4),
                        t,
                      )!,
                    ],
                    stops: const [0.0, 0.52, 1.0],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: bgGradientController,
            builder: (context, child) {
              final t = bgGradientController.value;
              final glowA = Color.lerp(
                const Color(0x66B8EEFF),
                const Color(0x3D8AD7F2),
                t,
              )!;
              final glowB = Color.lerp(
                const Color(0x3D59BFE8),
                const Color(0x6678D8FF),
                t,
              )!;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.lerp(
                      const Alignment(-0.7, -0.95),
                      const Alignment(0.75, -0.8),
                      t,
                    )!,
                    radius: 1.1,
                    colors: [glowA, glowB, Colors.transparent],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                child: Opacity(
                  opacity: 0.55,
                  child: Image.asset(
                    'assets/images/bg/ai-onbording.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Tooltip(
                        message: _ttsError ??
                            (_ttsPlaying
                                ? 'Pause reading'
                                : _ttsPaused
                                    ? 'Resume reading'
                                    : _selectedVoiceName == null
                                        ? 'Read this screen aloud'
                                        : 'Read this screen aloud (${_selectedVoiceName!})'),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _ttsReady
                                ? () => unawaited(_onVoiceControlTap())
                                : null,
                            child: Opacity(
                              opacity: _ttsReady ? 1 : 0.45,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppColors.footwearHeroStart.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _ttsPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 28,
                                  color: AppColors.footwearHeroStart,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => unawaited(_onPageChanged(i)),
                    children: steps,
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(37, 14, 37, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _NavCircleButton(
                          enabled: _index > 0,
                          onTap: _prev,
                          flipX: true,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: OnboardingBottomProgress(
                              currentIndex: _index,
                              totalSteps: _pageCount,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        _NavCircleButton(
                          enabled: _canNext,
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.text,
    required this.title,
    this.child,
    this.titleFontSize,
    this.titleTopSpacing,
  });

  final String text;
  final String title;
  final Widget? child;
  final double? titleFontSize;
  final double? titleTopSpacing;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bodySize = screenWidth < 360 ? 20.0 : 23.0;
    final titleSize = titleFontSize ?? (screenWidth < 360 ? 20.0 : 23.0);
    final bodyStyle = GoogleFonts.montserrat(
      color: const Color(0xFFDFE7E9),
      fontSize: bodySize,
      fontWeight: FontWeight.w300,
      height: 1.25,
    );
    final titleStyle = GoogleFonts.boldonse(
      color: const Color(0xFFDFE7E9),
      fontSize: titleSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.59,
    );

    final bodyWidget = Text(text, style: bodyStyle);
    final titleWidget = Text(title, style: titleStyle);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bodyWidget,
          SizedBox(height: titleTopSpacing ?? 50),
          titleWidget,
          if (child != null) ...[
            const SizedBox(height: 80),
            child!,
          ],
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      textInputAction: TextInputAction.done,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: (_) => onChanged(),
      style: GoogleFonts.montserrat(
        color: const Color(0xFFDFE7E9),
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: .55)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: .18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .45)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: .6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: .8)),
        ),
      ),
    );
  }
}

class _Checks extends StatelessWidget {
  const _Checks({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final optionSize = screenWidth < 360 ? 20.0 : 24.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose multiple options',
          style: GoogleFonts.montserrat(
            color: const Color(0xFFDFE7E9).withValues(alpha: 0.8),
            fontSize: screenWidth < 360 ? 14.0 : 15.0,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        ...options.map((option) {
          final active = selected.contains(option);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                if (active) {
                  selected.remove(option);
                } else {
                  selected.add(option);
                }
                onChanged();
              },
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFDFE7E9),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: active
                          ? const Color(0xFFDFE7E9).withValues(alpha: .2)
                          : Colors.transparent,
                    ),
                    child: active
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFFDFE7E9),
                            size: 22,
                          )
                        : null,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      option,
                      textHeightBehavior: _kOnboardingButtonTextHeight,
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFFDFE7E9),
                        fontSize: optionSize,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({
    required this.enabled,
    required this.onTap,
    this.flipX = false,
  });

  final bool enabled;
  final VoidCallback onTap;
  final bool flipX;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      flipX ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      color: AppColors.primaryDark,
      size: 28,
    );

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFDFE7E9),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF09DFFF),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

 