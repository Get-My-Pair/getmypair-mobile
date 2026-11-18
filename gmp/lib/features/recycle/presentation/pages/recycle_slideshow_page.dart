import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/recycle/data/recycle_remote_datasource.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

class RecycleSlideshowPage extends StatefulWidget {
  const RecycleSlideshowPage({super.key});

  @override
  State<RecycleSlideshowPage> createState() => _RecycleSlideshowPageState();
}

class _RecycleSlideshowPageState extends State<RecycleSlideshowPage> {
  final _controller = PageController();
  List<RecycleSlide> _slides = kRecycleSlidesFallback;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    final token = tokenResult.fold<String?>((_) => null, (value) => value);
    if (token == null) return;
    final slides = await sl<RecycleRemoteDataSource>().getSlides(token);
    if (!mounted || slides.isEmpty) return;
    setState(() => _slides = slides);
  }

  void _go(int next) {
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index >= _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...BgTheme.background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                        ),
                        Text(
                          'RecycleMyPair',
                          style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 20),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: i <= _index ? const Color(0xFF0F6876) : const Color(0xFFD0D0D0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _slides.length,
                        onPageChanged: (value) => setState(() => _index = value),
                        itemBuilder: (context, index) {
                          final slide = _slides[index];
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                            children: [
                              Text(
                                'Step ${slide.step == 0 ? index + 1 : slide.step} of ${_slides.length}',
                                style: GoogleFonts.montserrat(color: const Color(0xFF0F6876), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide.title,
                                style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 26),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide.summary,
                                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                              const SizedBox(height: 12),
                              Text(slide.body, style: GoogleFonts.montserrat(fontSize: 15, height: 1.45)),
                              const SizedBox(height: 16),
                              for (final point in slide.points)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                        child: Icon(Icons.circle, size: 8, color: Color(0xFF0F6876)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(point, style: GoogleFonts.montserrat(fontSize: 14, height: 1.35)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          if (_index > 0)
                            OutlinedButton(
                              onPressed: () => _go(_index - 1),
                              child: const Text('Back'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              if (last) {
                                Navigator.maybePop(context);
                              } else {
                                _go(_index + 1);
                              }
                            },
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F6876)),
                            child: Text(last ? 'Done' : 'Next'),
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
    );
  }
}
