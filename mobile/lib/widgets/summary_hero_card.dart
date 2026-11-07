import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reel/Post Summary Hero Card mirroring Stitch Screen 2.
class SummaryHeroCard extends StatelessWidget {
  final String author;
  final String title;
  final double durationSeconds;
  final String? thumbnailUrl;
  final String tldr;
  final List<String> keyPoints;

  const SummaryHeroCard({
    super.key,
    required this.author,
    required this.title,
    required this.durationSeconds,
    this.thumbnailUrl,
    required this.tldr,
    required this.keyPoints,
  });

  String _formatDuration(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Thumbnail / Header
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.surfaceContainerLowest,
                  image: (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (thumbnailUrl == null || thumbnailUrl!.isEmpty)
                    ? Center(
                        child: Icon(
                          Icons.movie_filter_rounded,
                          size: 48,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Colors.transparent, Color(0xCC111317)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
              ),

              // Badges over thumbnail
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        author,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (durationSeconds > 0)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(durationSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            title.isNotEmpty ? title : 'Instagram Content',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          // TL;DR Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                      child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TL;DR Summary',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tldr,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          if (keyPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Key Highlights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...keyPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

