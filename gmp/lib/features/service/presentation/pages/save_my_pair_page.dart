import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/donate/data/donate_remote_datasource.dart';
import 'package:gmp/features/donate/presentation/pages/donate_request_page.dart';
import 'package:gmp/features/recycle/presentation/pages/recycle_slideshow_page.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Save hub — donate and recycle, then how the path works.
/// Donation requests appear below when any exist.
class SaveMyPairPage extends StatefulWidget {
  const SaveMyPairPage({super.key});

  @override
  State<SaveMyPairPage> createState() => _SaveMyPairPageState();
}

class _SaveMyPairPageState extends State<SaveMyPairPage> {
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  List<DonateRequestItem> _requests = const [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    final token = tokenResult.fold<String?>((_) => null, (value) => value);
    if (token == null) return;
    try {
      final requests = await sl<DonateRemoteDataSource>().getMine(token);
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (_) {
      if (!mounted) return;
      setState(() => _requests = const []);
    }
  }

  Future<void> _openDonate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DonateRequestPage()),
    );
    if (mounted) await _loadRequests();
  }

  String _statusLabel(String status) {
    if (status == 'approved') return 'Approved';
    if (status == 'rejected') return 'Rejected';
    return 'Waiting for review';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalInset, 52, horizontalInset, 0),
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
                      padding: const EdgeInsets.fromLTRB(8, 12, 6, 120),
                      children: [
                        _Header(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 24),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ServiceCard(
                                  label: 'Donate\nMyPair',
                                  icon: Icons.volunteer_activism_outlined,
                                  onTap: _openDonate,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ServiceCard(
                                  label: 'Recycle\nMyPair',
                                  icon: Icons.recycling_outlined,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RecycleSlideshowPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _HowSavingWorks(),
                        if (_requests.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            'Your requests',
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF062F35),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final item in _requests)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.imageUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _statusLabel(item.status),
                                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                                        ),
                                        if (item.note.isNotEmpty)
                                          Text(
                                            item.note,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (item.status == 'rejected' &&
                                            (item.rejectReason ?? '').isNotEmpty)
                                          Text(
                                            item.rejectReason!,
                                            style: const TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
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
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 26, height: 26),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF062F35),
            size: 24,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'SaveMyPair',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF062F35),
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _HowSavingWorks extends StatelessWidget {
  const _HowSavingWorks();

  static const _steps = <({String step, String title, String body})>[
    (
      step: '1',
      title: 'Choose the path',
      body:
          'Donate a pair someone can still wear. Recycle a pair that is torn or no longer safe to walk in.',
    ),
    (
      step: '2',
      title: 'Hand the pair in',
      body:
          'Donate starts with a photo. Recycle is a hub drop or a pickup, with both shoes kept together.',
    ),
    (
      step: '3',
      title: 'We confirm it',
      body:
          'Donation requests show on this page while they are reviewed. A recycle drop ends with a confirmation.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How saving works',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF062F35),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Give a wearable pair to someone else, or send a worn-out pair to be recovered.',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF3D5A60),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE6EEF0)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F6876),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _steps[i].step,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _steps[i].title,
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF062F35),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _steps[i].body,
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF3D5A60),
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _PathNote(
                title: 'Donate',
                body: 'Still wearable',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _PathNote(
                title: 'Recycle',
                body: 'Worn out',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PathNote extends StatelessWidget {
  final String title;
  final String body;

  const _PathNote({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE7E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F6876)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.boldonse(
              color: const Color(0xFF062F35),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF062F35),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  static const double _minCardHeight = 86;

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lines = label.split('\n');
    final labelStyle = GoogleFonts.boldonse(
      color: const Color(0xFF062F35),
      fontSize: 15,
      height: 1.1,
      fontWeight: FontWeight.w400,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: _minCardHeight),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFDFE7E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F6876)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF062F35), size: 32),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < lines.length; i++) ...[
                      if (i > 0) const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          lines[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
