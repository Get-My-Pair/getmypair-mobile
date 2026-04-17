import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/theme/app_colors.dart';
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
  static const Color _primary = AppColors.footwearHeroStart;
  static const Color _text = Color(0xFFDFE7E9);
  static const Color _mint = AppColors.onboardingTrulyFits;

  static const String _orbAsset =
      'https://www.figma.com/api/mcp/asset/95f21855-ca3e-4a72-b797-54cbc89cd676';

  /// Wireframe orb over the gradient (~10–15% visible per mockup).
  static const double _orbImageOpacity = 0.12;

  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();

  int _index = 0;
  String? _gender;
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

  Future<void> _onCameraTap() async {
    if (_cameraAllowed) return;
    setState(() => _cameraAllowed = true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final orbWidth = (screenWidth * 1.08).clamp(280.0, 420.0);

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
                  selectedColor: AppColors.footwearHeroMid,
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
          RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        AppColors.footwearHeroStart,
                        AppColors.footwearHeroMid,
                        AppColors.footwearHeroEnd,
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.sizeOf(context).height * 0.14,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: orbWidth * 1.35,
                        height: orbWidth * 1.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.footwearHeroEnd.withValues(alpha: 0.14),
                              AppColors.footwearHeroMid.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .1),
                  child: Opacity(
                    opacity: _orbImageOpacity,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        AppColors.secondaryLight,
                        BlendMode.modulate,
                      ),
                      child: _SafeNetworkImage(_orbAsset, width: orbWidth),
                    ),
                  ),
                ),
              ],
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
                      Container(
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
                        child: const Icon(
                          Icons.pause,
                          size: 16,
                          color: AppColors.footwearHeroStart,
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
                      child: Row(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: bodySize,
              fontWeight: FontWeight.w300,
              height: 1.25,
            ),
          ),
          SizedBox(height: titleTopSpacing ?? 50),
          Text(
            title,
            style: GoogleFonts.boldonse(
              color: const Color(0xFFDFE7E9),
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              height: 1.59,
            ),
          ),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final optionSize = screenWidth < 360 ? 20.0 : 24.0;
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
                    style: GoogleFonts.boldonse(
                      color: const Color(0xFFDFE7E9),
                      fontSize: optionSize,
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
 