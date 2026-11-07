import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/extraction_result.dart';
import '../providers/extraction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/link_card.dart';
import '../widgets/summary_hero_card.dart';

/// Detailed extraction results screen mirroring Stitch Screen 2 (screen_2_results.png).
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  void _copyAllLinks(BuildContext context, List<ExtractedLink> links) {
    if (links.isEmpty) return;
    final allUrls = links.map((l) => l.normalizedUrl).toSet().join('\n');
    Clipboard.setData(ClipboardData(text: allUrls));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${links.length} links to clipboard!'),
        backgroundColor: AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExtractionProvider>();
    final reel = provider.reelResult;
    final post = provider.postResult;
    final profile = provider.profileResult;

    // Resolve unified data across modes
    final author = reel?.author ?? post?.author ?? profile?.profileName ?? '@instagram_creator';
    final title = reel?.title ?? post?.title ?? profile?.profileName ?? 'Extracted Content';
    final durationSeconds = reel?.durationSeconds ?? post?.durationSeconds ?? 0.0;
    final thumbnail = reel?.thumbnailUrl ?? post?.thumbnail;
    final tldr = reel?.summaryTldr ?? post?.summaryTldr ?? profile?.summaryTldr ?? 'No summary available.';
    final keyPoints = reel?.keyPoints ?? post?.keyPoints ?? <String>[];

    final videoLinks = reel?.videoLinks ?? <ExtractedLink>[];
    final captionLinks = reel?.captionLinks ?? post?.captionLinks ?? profile?.allCaptionLinks ?? <ExtractedLink>[];
    final allLinks = [...videoLinks, ...captionLinks];

    final transcript = reel?.transcript ?? '';
    final caption = reel?.caption ?? post?.caption ?? profile?.profileBio ?? '';
    final ocrSnippets = reel?.ocrSnippets ?? post?.ocrFrames ?? <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => provider.resetToIdle(),
        ),
        title: const Text('Extraction Results'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  author,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Share Results',
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'InstaLens Extraction for $author:\n$tldr\n\nLinks:\n${allLinks.map((l) => l.normalizedUrl).join('\n')}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary and links copied to share!')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Hero Card
            SummaryHeroCard(
              author: author,
              title: title,
              durationSeconds: durationSeconds,
              thumbnailUrl: thumbnail,
              tldr: tldr,
              keyPoints: keyPoints,
            ),

            const SizedBox(height: 24),

            // Extracted Links Header
            Row(
              children: [
                Text(
                  'Extracted Links (${allLinks.length} found)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (allLinks.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy_all_rounded, size: 14),
                    label: const Text('Copy All', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppTheme.primary, width: 0.8),
                      ),
                    ),
                    onPressed: () => _copyAllLinks(context, allLinks),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Video Links (OCR Detected)
            if (videoLinks.isNotEmpty) ...[
              _buildCategoryHeader(
                icon: Icons.movie_filter_rounded,
                title: 'Links in Video (OCR Detected)',
                count: videoLinks.length,
                color: AppTheme.secondary,
              ),
              const SizedBox(height: 8),
              ...videoLinks.map((link) => LinkCard(link: link)),
              const SizedBox(height: 14),
            ],

            // Caption Links
            if (captionLinks.isNotEmpty) ...[
              _buildCategoryHeader(
                icon: Icons.notes_rounded,
                title: 'Links in Caption & Bio',
                count: captionLinks.length,
                color: AppTheme.tertiary,
              ),
              const SizedBox(height: 8),
              ...captionLinks.map((link) => LinkCard(link: link)),
              const SizedBox(height: 14),
            ],

            if (allLinks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No external URLs detected in this content.',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Expandable Accordions
            const Text(
              'Raw Content & Transcripts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Accordion 1: Raw OCR Frames
            _buildAccordion(
              title: 'Raw OCR Detected Frames (${ocrSnippets.length})',
              icon: Icons.photo_camera_rounded,
              child: ocrSnippets.isNotEmpty
                  ? Column(
                      children: ocrSnippets.map((snip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snip['timestamp']?.toString() ?? 'Frame',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  snip['text']?.toString() ?? '',
                                  style: const TextStyle(color: AppTheme.onSurface, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No OCR text frames detected.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                    ),
            ),

            const SizedBox(height: 8),

            // Accordion 2: Audio Transcript
            _buildAccordion(
              title: 'Audio Transcript (Whisper AI)',
              icon: Icons.mic_rounded,
              child: transcript.isNotEmpty
                  ? SelectableText(
                      transcript,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    )
                  : const Text(
                      'No spoken transcript available.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                    ),
            ),

            const SizedBox(height: 8),

            // Accordion 3: Original Caption
            _buildAccordion(
              title: 'Original Caption & Tags',
              icon: Icons.format_quote_rounded,
              child: caption.isNotEmpty
                  ? SelectableText(
                      caption,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    )
                  : const Text(
                      'No caption provided.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAccordion({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: ExpansionTile(
          leading: Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: [
            Align(alignment: Alignment.centerLeft, child: child),
          ],
        ),
      ),
    );
  }
}

