import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';

import 'profile_completion_page.dart';

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

class _AiOnboardingPageState extends State<AiOnboardingPage> {
  static const int _pageCount = 7;
  static const Color _primary = Color(0xFF062F35);
  static const Color _text = Color(0xFFDFE7E9);
  static const Color _mint = Color(0xFFAFEDD6);

  static const String _orbAsset =
      'https://www.figma.com/api/mcp/asset/95f21855-ca3e-4a72-b797-54cbc89cd676';
  static const String _pauseIcon =
      'https://www.figma.com/api/mcp/asset/ed44b649-c0c0-47d6-a6ab-f0acfdb23466';
  static const String _voiceIcon =
      'https://www.figma.com/api/mcp/asset/62419914-36bc-4d5a-9e4b-2aeed47dd5b7';

  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();

  int _index = 0;
  String? _gender;
  bool _voiceAllowed = false;
  bool _listening = false;
  bool _cameraAllowed = false;
  final Set<String> _rack = <String>{};
  final Set<String> _troubles = <String>{};

  @override
  void dispose() {
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

  Future<bool?> _permissionDialog(String title, String body) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(body),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text("Don't Allow"),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onVoiceTap() async {
    if (!_voiceAllowed) {
      final ok = await _permissionDialog(
        '"GetMyPair" Would Like to Access the Microphone',
        'Please allow GetMyPair to access your microphone.',
      );
      if (ok != true) return;
      setState(() => _voiceAllowed = true);
    }

    setState(() => _listening = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    if (_index == 0) _name.text = 'Aashi';
    if (_index == 1) {
      _age.text = '26';
      _gender = 'Female';
    }
    if (_index == 2) {
      _rack
        ..clear()
        ..add('My Kids');
    }
    if (_index == 3) {
      _troubles
        ..clear()
        ..add('Hard to find the right fit!')
        ..add('No strong support at heel.');
    }
    setState(() => _listening = false);
  }

  Future<void> _onCameraTap() async {
    if (_cameraAllowed) return;
    setState(() => _cameraAllowed = true);
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      _Step(
        text:
            "Welcome, Collector!\n\nI’m your AI friend XXX!\n\nI’m here to help you nail the perfect fit, discover brands that work for you, and vibe with your style.\n\nBut first let’s get to know you better!",
        title: 'What should we call you?\nDo you go by a nickname?',
        child: _Input(
          controller: _name,
          hint: 'Enter nickname',
          onChanged: () => setState(() {}),
        ),
      ),
      _Step(
        text: "${_name.text.trim().isEmpty ? 'Aashi' : _name.text.trim()}! That’s a great name!!",
        title: 'Now, let’s get to know\nyour age and gender...',
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
              children: ['Female', 'Male', 'Other'].map((g) {
                return ChoiceChip(
                  label: Text(g),
                  selected: _gender == g,
                  onSelected: (_) => setState(() => _gender = g),
                  selectedColor: const Color(0xFF0F6876),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      _Step(
        text: "Awesome!\nLet’s start setting up the rack...",
        title: 'Is this rack just for you, or\nare we setting it up for\nyour loved ones too?',
        child: _Checks(
          options: const ['Just Me', 'My Partner', 'My Kids', 'Elderly'],
          selected: _rack,
          onChanged: () => setState(() {}),
        ),
      ),
      _Step(
        text:
            "Kids rack, huh?\nThat’s awesome! We get to style you all up.\n\nBut first, let’s get you sorted before the others.",
        title: 'What shoe troubles do you run into most?',
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
      const _Step(
        text:
            'Looks like your size is\nUS 10\nUK 09\nEU 41\n\nAnd it seems like you have wide feet...\n\nNot to worry we know the right brands that will fit you...',
        title: 'Before that let’s\nunderstand your kids needs too...',
      ),
      const _Step(
        text:
            'That sounds really frustrating..\nwe get it, and we’re here to help\nfix those fit struggles.',
        title: 'Let’s get to know your\nfoot type and size!',
      ),
      _Step(
        text:
            'That sounds really frustrating..\nwe get it, and we’re here to help\nfix those fit struggles.',
        title: 'Let’s get to know your\nfoot type and size!',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _cameraAllowed ? null : _onCameraTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: _text,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(_cameraAllowed ? 'Camera Allowed' : 'Allow Camera Access'),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.9, -1),
                end: Alignment(-0.4, 1),
                colors: [
                  Color(0xFF141C1D),
                  Color(0xFF0F6876),
                  Color(0xFF09E0FF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0, .45, .76, 1],
              ),
            ),
            child: Align(
              alignment: const Alignment(0, .1),
              child: Opacity(
                opacity: .28,
                child: _SafeNetworkImage(_orbAsset, width: 420),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xCCDFE7E9),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _SafeNetworkImage(_pauseIcon),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _index = i),
                    children: steps,
                  ),
                ),
                Material(
                  color: _primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              TextButton(
                                onPressed: _index > 0 ? _prev : null,
                                child: Text(
                                  'Prev',
                                  style: TextStyle(
                                    color: _index > 0 ? Colors.white : Colors.white38,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_pageCount, (i) {
                                    final active = i == _index;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: active ? 18 : 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? _mint
                                            : Colors.white.withValues(alpha: .35),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              TextButton(
                                onPressed: _canNext ? _next : null,
                                child: Text(
                                  _index == _pageCount - 1 ? 'Done' : 'Next',
                                  style: TextStyle(
                                    color: _canNext ? _mint : Colors.white38,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1, color: Color(0x33FFFFFF)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _onVoiceTap,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 28,
                                  child: _SafeNetworkImage(_voiceIcon),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _listening ? 'Listening...' : 'Voice',
                                  style: const TextStyle(
                                    color: _mint,
                                    fontSize: 16,
                                    fontFamily: 'Boldonse',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
  });

  final String text;
  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 24,
              fontFamily: 'Montserrat',
              height: 1.25,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 24,
              fontFamily: 'Boldonse',
              height: 1.25,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 24),
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
      onChanged: (_) => onChanged(),
      style: const TextStyle(
        color: Color(0xFFDFE7E9),
        fontSize: 18,
        fontFamily: 'Montserrat',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: .55)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: .18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .25)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
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
                    style: const TextStyle(
                      color: Color(0xFFDFE7E9),
                      fontSize: 24,
                      fontFamily: 'Boldonse',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SafeNetworkImage extends StatelessWidget {
  const _SafeNetworkImage(
    this.url, {
    this.width,
  });

  final String url;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
      ),
    );
  }
}
 