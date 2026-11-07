import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/extraction_result.dart';
import '../theme/app_theme.dart';

/// Interactive card for an extracted URL with Copy and Open actions.
class LinkCard extends StatelessWidget {
  final ExtractedLink link;

  const LinkCard({super.key, required this.link});

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(link.normalizedUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${link.normalizedUrl}')),
        );
      }
    }
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: link.normalizedUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: ${link.normalizedUrl}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOcr = link.source == 'video_ocr';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOcr
                      ? AppTheme.secondary.withValues(alpha: 0.2)
                      : AppTheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOcr
                        ? AppTheme.secondary.withValues(alpha: 0.5)
                        : AppTheme.tertiary.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOcr ? Icons.visibility_rounded : Icons.text_snippet_rounded,
                      size: 13,
                      color: isOcr ? AppTheme.secondary : AppTheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOcr
                          ? (link.timestamp != null
                              ? 'OCR Frame ${link.timestamp}'
                              : 'Video OCR')
                          : 'In Caption',
                      style: TextStyle(
                        color: isOcr ? const Color(0xFFD99DFF) : const Color(0xFFFFB596),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: AppTheme.onSurfaceVariant,
                tooltip: 'Copy Link',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copyLink(context),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                color: AppTheme.primary,
                tooltip: 'Open in Browser',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _openLink(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            link.normalizedUrl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (link.context != null && link.context!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              link.context!,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

