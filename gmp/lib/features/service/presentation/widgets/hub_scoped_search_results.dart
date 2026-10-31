import 'package:flutter/material.dart';
import 'package:gmp/core/utils/hub_search.dart';
import 'package:google_fonts/google_fonts.dart';

class HubSearchHit {
  final String title;
  final String subtitle;
  final List<String> keywords;
  final IconData icon;
  final VoidCallback onTap;

  const HubSearchHit({
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.icon,
    required this.onTap,
  });

  bool matches(String query) => hubSearchMatches(
        query,
        label: title,
        keywords: [...keywords, subtitle],
      );
}

/// In-page "global" search results scoped to one hub (Care / Rehome / Save).
class HubScopedSearchResults extends StatelessWidget {
  final String query;
  final String hubName;
  final List<HubSearchHit> hits;

  const HubScopedSearchResults({
    super.key,
    required this.query,
    required this.hubName,
    required this.hits,
  });

  @override
  Widget build(BuildContext context) {
    final matched = hits.where((h) => h.matches(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Search in $hubName',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF062F35),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          matched.isEmpty
              ? 'No $hubName results for "$query"'
              : '${matched.length} result${matched.length == 1 ? '' : 's'}',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF5C6E73),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        for (final hit in matched) ...[
          _HubResultTile(hit: hit),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HubResultTile extends StatelessWidget {
  final HubSearchHit hit;

  const _HubResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: hit.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE7E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(hit.icon, color: const Color(0xFF0E7C8A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF062F35),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hit.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF5C6E73),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5C6E73),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
