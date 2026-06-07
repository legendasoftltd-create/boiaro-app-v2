import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Full-screen episode list opened when user taps "See All" on book details.
/// All play logic is handled via [onPlayTrack] callback from the parent.
class EpisodesListPageWidget extends StatelessWidget {
  const EpisodesListPageWidget({
    super.key,
    required this.bookName,
    required this.bookImage,
    required this.tracks,
    required this.onPlayTrack,
  });

  final String bookName;
  final String bookImage;

  /// Full list of track maps (same shape as used in book_detailspage).
  final List<Map<String, dynamic>> tracks;

  /// Called when user taps a track row. Receives the track map.
  final Future<void> Function(Map<String, dynamic> track) onPlayTrack;

  static const routeName = 'EpisodesListPage';
  static const routePath = '/episodesListPage';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: theme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 14, right: 16),
              title: Text(
                bookName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Book cover blurred background
                  if (bookImage.isNotEmpty)
                    Image.network(
                      bookImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.primary,
                      ),
                    ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.primary.withOpacity(0.5),
                          theme.primary.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                  // Episode count badge
                  Positioned(
                    right: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        '${tracks.length} Episodes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Track List ────────────────────────────────────────────────────
          tracks.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headphones_outlined,
                            size: 56,
                            color: theme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No episodes available',
                          style: theme.bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: theme.secondaryText,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        return _EpisodeCard(
                          track: track,
                          index: index,
                          theme: theme,
                          isDark: isDark,
                          onTap: () => onPlayTrack(track),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Episode Card widget — used both in book details and full list page
// ─────────────────────────────────────────────────────────────────────────────

class _EpisodeCard extends StatefulWidget {
  const _EpisodeCard({
    required this.track,
    required this.index,
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> track;
  final int index;
  final dynamic theme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scaleCtrl.reverse();
  void _onTapUp(_) => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final track = widget.track;
    final isPreview = track['is_preview'] == true;
    final num = track['track_number'];
    final title = track['title']?.toString() ?? 'Episode ${widget.index + 1}';
    final dur = track['duration']?.toString() ?? '';
    final isDark = widget.isDark;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E2A35),
                      const Color(0xFF1A2530),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF7FAFD),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPreview
                  ? const Color(0xFF1ABC9C).withOpacity(0.35)
                  : (isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Episode number badge ──────────────────────────────────
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isPreview
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF1ABC9C),
                              Color(0xFF16A085),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              theme.primary.withOpacity(0.8),
                              theme.primary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isPreview
                                ? const Color(0xFF1ABC9C)
                                : (theme.primary as Color))
                            .withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${num ?? widget.index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Title + duration ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A2530),
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (dur.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: theme.secondaryText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              dur,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 11,
                                color: theme.secondaryText,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Status badge + play icon ──────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Free / Lock badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPreview
                            ? const Color(0xFF1ABC9C).withOpacity(0.12)
                            : (isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPreview
                              ? const Color(0xFF1ABC9C).withOpacity(0.4)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPreview
                                ? Icons.headphones_rounded
                                : Icons.lock_outline_rounded,
                            size: 10,
                            color: isPreview
                                ? const Color(0xFF1ABC9C)
                                : theme.secondaryText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isPreview ? 'Free' : 'Paid',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isPreview
                                  ? const Color(0xFF1ABC9C)
                                  : theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Play button
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isPreview
                            ? const Color(0xFF1ABC9C)
                            : theme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPreview
                                    ? const Color(0xFF1ABC9C)
                                    : (theme.primary as Color))
                                .withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
