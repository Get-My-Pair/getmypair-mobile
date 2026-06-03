import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_event.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_state.dart';
import 'package:gmp/features/auth/presentation/pages/onboarding/onboarding_bottom_progress.dart';
import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';

/// Display fonts (e.g. Boldonse) use tall metrics; without this, labels can clip in Material buttons.
const TextHeightBehavior _kOnboardingButtonTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

String _normalizeSpeech(String raw) {
  return raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Global app-session guard: show voice-audibility hint only once.
bool _hasShownVoicePlaybackHintGlobally = false;

// Footwear / foot-scan steps hidden in flow — keep for re-enable:
// /// Foot blueprint size rows (table UI + TTS).
// const List<(String, String)> _kFootSizeRows = [
//   ('United States & Canada', '10'),
//   ('United Kingdom', '8'),
//   ('Europe (EU)', '40.5 \u2013 41'),
//   ('Japan (CM)', '26.5 cm'),
//   ('Australia', '10'),
// ];
//
// String _speakableFootSizes() {
//   return _kFootSizeRows
//       .map((r) => '${r.$1} \u2014 ${r.$2}')
//       .join('\n');
// }

/// Body on the step after rack selection (index 3), driven by step-3 choices.
String _bodyAfterRackSelection(Set<String> rack) {
  // MVP: single profile — restore family rack branches when multi-profile ships.
  // if (rack.contains('My Partner')) {
  //   return 'Crafting a curated masterpiece for two? Let\u2019s design this rack '
  //       'to perfectly balance your personal rotation with your partner\u2019s '
  //       'favourites.\n\nBut first, let\u2019s set you up together...';
  // }
  // if (rack.contains('My Kids')) {
  //   return 'Building a fun and family-ready shoe collection? Let\u2019s create a rack '
  //       'that keeps up with your style while making space for your kids\u2019 everyday '
  //       'adventures, school days, and tiny trendsetters.\n\nBut first, let\u2019s set you up...';
  // }
  // if (rack.contains('Elderly')) {
  //   return 'Creating a thoughtful shared collection for you and your elders? Let\u2019s design '
  //       'a comfortable and organized rack that blends your personal style with everyday comfort, '
  //       'accessibility, and timeless favourites for the family.\n\nBut first, let\u2019s set you up...';
  // }
  return 'Going for a solo masterpiece, I see! Keeping this entire rack strictly '
      'for your own personal rotation?';
}

/// Reassurance copy on the final step (index 4) when the rack includes partner, kids, or elders.
String _rackReassuranceClosingStep(Set<String> rack) {
  // MVP: single profile — restore when family rack options return.
  // if (rack.contains('My Partner')) {
  //   return 'Don\u2019t worry, we haven\u2019t forgotten about your partner! '
  //       'We\u2019ll get their side of the rack styled and ready to go as soon as '
  //       'we\u2019ve finished perfecting your fit.';
  // }
  // if (rack.contains('My Kids')) {
  //   return 'Don\u2019t worry, the little ones aren\u2019t left out! We\u2019ll set up '
  //       'their side of the rack with styles ready for school days, playtime, and '
  //       'every family adventure once your fit is complete.';
  // }
  // if (rack.contains('Elderly')) {
  //   return 'Don\u2019t worry, we haven\u2019t forgotten about your elders! We\u2019ll '
  //       'thoughtfully arrange their side of the rack with comfort-first styles and '
  //       'everyday essentials right after we perfect your setup.';
  // }
  return '';
}

/// Extra closing step only when the rack includes partner, kids, or elders.
bool _rackNeedsClosingReassurance(Set<String> rack) {
  // MVP: single profile only — no extra closing step.
  return false;
  // return rack.contains('My Partner') ||
  //     rack.contains('My Kids') ||
  //     rack.contains('Elderly');
}

String _householdTypeFromRack(Set<String> rack) {
  if (rack.contains('My Partner')) return 'with_partner';
  if (rack.contains('My Kids')) return 'with_children';
  if (rack.contains('Elderly')) return 'with_elder';
  return 'just_me';
}

String _aiOnboardingBody(
  int index,
  String nickname, {
  Set<String> rack = const {},
}) {
  switch (index) {
    case 0:
      return 'Welcome, Collector!\n\nI\u2019m your AI friend KIX!\n\nI\u2019m here to help you nail the perfect fit, discover brands that work for you, and vibe with your style.\n\nBut first let\u2019s get to know you better!';
    case 1:
      return '$nickname! That\u2019s a great name!!';
    case 2:
      return 'That\u2019s the spirit! Let\u2019s get your personalized rack ready!';
    case 3:
      return _bodyAfterRackSelection(rack);
    case 4:
      return '';
    // Footwear steps (old index 4–5) — hidden:
    // case 4:
    //   return 'That sounds like a total nightmare, but don\'t worry! We\'ve got your back (and your feet) covered.';
    // case 5:
    //   return '';
    // case 6:
    //   return '';
    default:
      return '';
  }
}

String _aiOnboardingTitle(int index, {Set<String> rack = const {}}) {
  switch (index) {
    case 0:
      return 'What should we call you?\nDo you go by a nickname?';
    case 1:
      return 'Since I\'m all about getting to know the real you, tell me: when were you born, and what are your preferred pronouns?';
    case 2:
      // MVP: solo rack only.
      return 'Let\u2019s set up your personal shoe rack!';
      // return 'Will this be a solo collection, or are we making room for the whole crew?';
    case 3:
      return 'Time for some shoe therapy: what\u2019s the ultimate dealbreaker that usually stands between you and the perfect fit?';
    case 4:
      return _rackReassuranceClosingStep(rack);
    // Footwear steps (old index 4–5) — hidden:
    // case 4:
    //   return 'Let\u2019s dive in and find your perfect match by getting the lowdown on your unique foot shape and size!';
    // case 5:
    //   return 'Here it is: the blueprint of your feet! Check out your custom foot type and size breakdown right here.';
    // case 6:
    //   return _rackReassuranceClosingStep(rack);
    default:
      return '';
  }
}

// String _aiOnboardingTrailingTitle(int index) {
//   switch (index) {
//     case 5:
//       return 'Detected Foot Profile: The \u201CHigh Arch\u201D';
//     default:
//       return '';
//   }
// }

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
  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  AnimationController? _bgGradientController;

  int _index = 0;
  DateTime? _birthDate;
  String? _gender;
  // bool _cameraAllowed = false;
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

  /// True while [AuthCompleteProfile] is in flight after the last onboarding step.
  bool _isSubmittingProfile = false;

  // With footwear steps: ? 7 : 6
  int get _pageCount => _rackNeedsClosingReassurance(_rack) ? 5 : 4;

  void _clampPageIndexIfNeeded() {
    final last = _pageCount - 1;
    if (_index <= last) return;
    if (!_controller.hasClients) {
      setState(() => _index = last);
      return;
    }
    _controller.jumpToPage(last);
    unawaited(_onPageChanged(last));
  }

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
    final body = _aiOnboardingBody(index, nickname, rack: _rack);
    final title = _aiOnboardingTitle(index, rack: _rack);
    return _normalizeSpeech('$body $title');
  }

  // Footwear TTS (old index 5) — hidden:
  // String _speakableContentForFootwear(int index) {
  //   final nickname = _name.text.trim().isEmpty ? 'Aashi' : _name.text.trim();
  //   final body = index == 5
  //       ? _speakableFootSizes()
  //       : _aiOnboardingBody(index, nickname, rack: _rack);
  //   final title = _aiOnboardingTitle(index, rack: _rack);
  //   final trailing = _aiOnboardingTrailingTitle(index);
  //   if (index == 5) {
  //     return _normalizeSpeech('$title $body $trailing');
  //   }
  //   return _normalizeSpeech('$body $title $trailing');
  // }

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

  void _showVoicePlaybackHintOnce() {
    if (!mounted || _hasShownVoicePlaybackHintGlobally) return;
    _hasShownVoicePlaybackHintGlobally = true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Voice is not audible. Please increase media volume or turn off silent mode.',
          ),
        ),
      );
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
        _showVoicePlaybackHintOnce();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = false;
        });
        _showVoicePlaybackHintOnce();
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
          _showVoicePlaybackHintOnce();
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
    _controller.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_index) {
      case 0:
        return _name.text.trim().isNotEmpty;
      case 1:
        return _birthDate != null && _gender != null;
      case 2:
        return _rack.isNotEmpty;
      case 3:
        return _troubles.isNotEmpty;
      case 4:
        return true;
      // Footwear steps — hidden:
      // case 4:
      //   return _cameraAllowed;
      // case 5:
      // case 6:
      //   return true;
      default:
        return false;
    }
  }

  void _prev() {
    if (_index == 0 || _isSubmittingProfile) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (!_canNext || _isSubmittingProfile) return;
    if (_index == _pageCount - 1) {
      unawaited(_finish());
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (widget.requiresProfileCompletion) {
      final name = _name.text.trim();
      if (name.length < 2 || _birthDate == null || _gender == null) {
        if (!mounted) return;
        await showAppFeedbackAlert(
          context,
          message:
              'Profile details are incomplete. Go back and fill your name, birthday, and gender.',
          type: AppFeedbackType.warning,
        );
        return;
      }
      if (!mounted) return;
      setState(() => _isSubmittingProfile = true);
      context.read<AuthBloc>().add(
            AuthCompleteProfile(
              mobile: widget.mobile,
              name: name,
              dateOfBirth: _birthDate!,
              gender: _gender!.toLowerCase(),
              householdType: _householdTypeFromRack(_rack),
              location: null,
            ),
          );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerDashboardPage()),
      (_) => false,
    );
  }

  // Future<void> _onCameraTap() async {
  //   if (_cameraAllowed) return;
  //   setState(() => _cameraAllowed = true);
  // }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BirthdayPill(
              date: _birthDate,
              onTap: _pickBirthDate,
            ),
            const SizedBox(height: 20),
            _GenderRadios(
              selected: _gender,
              onSelected: (value) => setState(() => _gender = value),
            ),
          ],
        ),
      ),
      _Step(
        text: _aiOnboardingBody(2, nick),
        title: _aiOnboardingTitle(2),
        child: _Checks(
          // MVP: single profile — restore family rack options later.
          options: const ['Just Me'],
          // options: const ['Just Me', 'My Partner', 'My Kids', 'Elderly'],
          selected: _rack,
          onChanged: () {
            setState(() {});
            _clampPageIndexIfNeeded();
          },
        ),
      ),
      _Step(
        text: _aiOnboardingBody(3, nick, rack: _rack),
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
      // Footwear steps (camera + foot blueprint) — hidden:
      // _Step(
      //   text: _aiOnboardingBody(4, nick),
      //   title: _aiOnboardingTitle(4),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.stretch,
      //     children: [
      //       ElevatedButton(
      //         onPressed: _cameraAllowed ? null : _onCameraTap,
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: _cameraAllowed
      //               ? const Color(0xFFABABAB)
      //               : Colors.white,
      //           foregroundColor: _cameraAllowed
      //               ? const Color(0xFF5A5A5A)
      //               : const Color(0xFF12899B),
      //           elevation: 2,
      //           padding: const EdgeInsets.symmetric(
      //             horizontal: 24,
      //             vertical: 14,
      //           ),
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(100),
      //           ),
      //           side: const BorderSide(
      //             color: Color(0xFF09DFFF),
      //             width: 1,
      //           ),
      //         ),
      //         child: Text(
      //           _cameraAllowed ? 'Camera Allowed' : 'Allow Camera Access',
      //           textAlign: TextAlign.center,
      //           textHeightBehavior: _kOnboardingButtonTextHeight,
      //           style: GoogleFonts.boldonse(
      //             fontSize: 14,
      //             fontWeight: FontWeight.w400,
      //             height: 1.2,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      // _Step(
      //   text: _aiOnboardingBody(5, nick),
      //   title: _aiOnboardingTitle(5),
      //   trailingTitle: _aiOnboardingTrailingTitle(5),
      //   leadingTitleFirst: true,
      //   child: const _FootSizeTable(),
      // ),
      // MVP: family closing reassurance step disabled (single profile).
      // if (_rackNeedsClosingReassurance(_rack))
      //   _Step(
      //     text: _aiOnboardingBody(4, nick, rack: _rack),
      //     title: _aiOnboardingTitle(4, rack: _rack),
      //   ),
      // Closing reassurance (old index 6) when footwear steps enabled:
      // if (_rackNeedsClosingReassurance(_rack))
      //   _Step(
      //     text: _aiOnboardingBody(6, nick, rack: _rack),
      //     title: _aiOnboardingTitle(6, rack: _rack),
      //   ),
    ];

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthProfileCompleted) {
          if (!mounted) return;
          setState(() => _isSubmittingProfile = false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CustomerDashboardPage()),
            (_) => false,
          );
        } else if (state is AuthError) {
          if (!_isSubmittingProfile) return;
          if (!mounted) return;
          setState(() => _isSubmittingProfile = false);
          await showAppFeedbackAlert(
            context,
            message: state.message,
            type: AppFeedbackType.failure,
          );
        }
      },
      child: Scaffold(
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
                          enabled: _index > 0 && !_isSubmittingProfile,
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
                          enabled: _canNext && !_isSubmittingProfile,
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSubmittingProfile)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  // Non-const: const ctors block hot reload when widget fields are added/removed.
  // ignore: prefer_const_constructors_in_immutables
  _Step({
    required this.text,
    required this.title,
    this.trailingTitle = '',
    this.leadingTitleFirst = false,
    this.child,
    this.prominentBody = false,
  });

  final String text;
  final String title;
  final String trailingTitle;

  /// When true, [title] is shown above [text] (e.g. foot blueprint step).
  final bool leadingTitleFirst;
  final Widget? child;

  /// Boldonse body at the same size as [title] (e.g. foot blueprint headline).
  final bool prominentBody;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bodySize = screenWidth < 360 ? 19.0 : 22.0;
    final titleSize = screenWidth < 360 ? 19.0 : 22.0;
    final titleStyle = GoogleFonts.boldonse(
      color: const Color(0xFFDFE7E9),
      fontSize: titleSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.59,
    );
    final bodyStyle = prominentBody
        ? titleStyle
        : GoogleFonts.montserrat(
            color: const Color(0xFFDFE7E9),
            fontSize: bodySize,
            fontWeight: FontWeight.w300,
            height: 1.25,
          );

    final bodyWidget = Text(
      text,
      style: bodyStyle,
      textHeightBehavior:
          prominentBody ? _kOnboardingButtonTextHeight : null,
    );
    final titleWidget = Text(
      title,
      style: titleStyle,
      textHeightBehavior: _kOnboardingButtonTextHeight,
    );
    final trailingTitleWidget = Text(
      trailingTitle,
      style: titleStyle,
      textHeightBehavior: _kOnboardingButtonTextHeight,
    );
    final hasTitle = title.trim().isNotEmpty;
    final hasBodyText = text.trim().isNotEmpty;
    final hasTrailingTitle = trailingTitle.trim().isNotEmpty;

    final columnChildren = leadingTitleFirst
        ? <Widget>[
            if (hasTitle) ...[
              titleWidget,
              const SizedBox(height: 50),
            ],
            if (hasBodyText) bodyWidget,
            if (child != null) ...[
              if (hasBodyText) const SizedBox(height: 24),
              child!,
            ],
            if (hasTrailingTitle) ...[
              const SizedBox(height: 24),
              trailingTitleWidget,
            ],
          ]
        : <Widget>[
            if (hasBodyText) bodyWidget,
            if (hasTitle) ...[
              const SizedBox(height: 50),
              titleWidget,
            ],
            if (child != null) ...[
              SizedBox(height: hasTitle ? 80 : 24),
              child!,
            ],
            if (hasTrailingTitle) ...[
              const SizedBox(height: 24),
              trailingTitleWidget,
            ],
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    );
  }
}

// /// Region / size grid for the foot blueprint step (small type, fits teal gradient).
// class _FootSizeTable extends StatelessWidget {
//   const _FootSizeTable();
//
//   static Widget _cell(
//     String label,
//     double fontSize, {
//     bool header = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       child: Text(
//         label,
//         style: GoogleFonts.montserrat(
//           color: const Color(0xFFDFE7E9),
//           fontSize: header ? fontSize + 0.75 : fontSize,
//           fontWeight: header ? FontWeight.w600 : FontWeight.w400,
//           height: 1.25,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final dataFont = screenWidth < 360 ? 9.5 : 10.5;
//     final borderColor = Colors.white.withValues(alpha: 0.28);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.black.withValues(alpha: 0.22),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
//       ),
//       padding: const EdgeInsets.all(8),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: Table(
//           defaultColumnWidth: const FlexColumnWidth(1),
//           border: TableBorder.all(color: borderColor, width: 1),
//           children: [
//             TableRow(
//               decoration: BoxDecoration(
//                 color: Colors.white.withValues(alpha: 0.08),
//               ),
//               children: [
//                 _cell('Region', dataFont, header: true),
//                 _cell('Size Equivalent', dataFont, header: true),
//               ],
//             ),
//             for (final row in _kFootSizeRows)
//               TableRow(
//                 children: [
//                   _cell(row.$1, dataFont),
//                   _cell(row.$2, dataFont),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _BirthdayPill extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _BirthdayPill({
    required this.date,
    required this.onTap,
  });

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? 'Your Birthday'
                        : DateFormat.yMMMd().format(date!),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFDFE7E9),
                      fontSize: 18,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: const Color(0xFFDFE7E9).withValues(alpha: 0.95),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _Input({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
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

/// Single-select gender list: same layout as [_Checks] (header + rows), radio circles on the left.
class _GenderRadios extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _GenderRadios({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  static const _options = ['Female', 'Male'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final labelSize = screenWidth < 360 ? 20.0 : 24.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your Gender',
          style: GoogleFonts.montserrat(
            color: const Color(0xFFDFE7E9).withValues(alpha: 0.8),
            fontSize: screenWidth < 360 ? 14.0 : 15.0,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        ..._options.map((option) {
          final active = selected == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelected(option),
              child: Semantics(
                label: option,
                checked: active,
                inMutuallyExclusiveGroup: true,
                button: true,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDFE7E9),
                          width: 3,
                        ),
                        color: active
                            ? const Color(0xFFDFE7E9).withValues(alpha: .2)
                            : Colors.transparent,
                      ),
                      child: active
                          ? Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFDFE7E9),
                                ),
                              ),
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
                          fontSize: labelSize,
                          height: 1.5,
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
    );
  }
}

class _Checks extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _Checks({
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
          'You Choose multiple options',
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
  // ignore: prefer_const_constructors_in_immutables
  _NavCircleButton({
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

 