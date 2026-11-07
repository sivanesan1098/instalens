import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/extraction_result.dart';

/// Service for client-side scraping and link extraction from Instagram public URLs.
class InstagramScraperService {
  // Regex matching URLs in text (mirrors backend.py)
  static final RegExp urlRegex = RegExp(
    r'(?<!@)(?:https?://|www\.)[^\s<>"{}|\\^`\[\]]+|'
    r'(?<!@)\b(?:[a-zA-Z0-9-]+\.)+(?:com|io|ai|dev|org|net|co|app|me|ly|gg|sh|xyz|ee|tv|so|link|notion|substack|gumroad|patreon|etsy|shopify|spotify|soundcloud|bandcamp|vimeo|dailymotion|loom|streamable|clips|cdn|store)(?:/[^\s<>"{}|\\^`\[\]]*)?\b',
    caseSensitive: false,
  );

  /// Normalizes a URL for deduplication.
  static String normalizeForDedup(String url) {
    var u = url.toLowerCase().replaceAll(RegExp(r'[/.,;:!?)]+$'), '');
    String scheme = '';
    if (u.startsWith('https://')) {
      scheme = 'https://';
      u = u.substring(8);
    } else if (u.startsWith('http://')) {
      scheme = 'http://';
      u = u.substring(7);
    }
    if (u.startsWith('www.')) {
      u = u.substring(4);
    }
    return scheme + u;
  }

  /// Extracts structured ExtractedLink objects from text (e.g. caption, OCR).
  static List<ExtractedLink> extractUrlsFromText(
    String text,
    String source, {
    String? timestamp,
  }) {
    if (text.isEmpty) return [];
    final found = <ExtractedLink>[];
    final seen = <String>{};

    for (final match in urlRegex.allMatches(text)) {
      final raw = match.group(0)?.replaceAll(RegExp(r'[.,;:!?)]+$'), '') ?? '';
      if (raw.isEmpty) continue;

      final norm = raw.toLowerCase().startsWith('http://') ||
              raw.toLowerCase().startsWith('https://')
          ? raw
          : 'https://$raw';
      final key = normalizeForDedup(norm);

      if (!seen.contains(key)) {
        seen.add(key);
        found.add(
          ExtractedLink(
            url: raw,
            normalizedUrl: norm,
            source: source,
            timestamp: timestamp,
            context: text.length > 140 ? '${text.substring(0, 140)}...' : text,
          ),
        );
      }
    }
    return found;
  }

  /// Extracts shortcode from an Instagram URL.
  static String extractShortcode(String url) {
    final match = RegExp(r'/(?:p|reel|tv)/([A-Za-z0-9_-]+)').firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return 'instagram_content';
  }

  /// Unescapes common HTML entities and numeric/hex code points.
  static String unescapeHtml(String text) {
    if (text.isEmpty) return text;
    var result = text
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&amp;', '&');

    // Decimal entities: &#123;
    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    // Hexadecimal entities: &#x1f4c8;
    result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    return result;
  }

  /// Scrapes public post metadata via oEmbed or OpenGraph scraping.
  Future<Map<String, dynamic>> scrapePublicInstagramPost(String url) async {
    final shortcode = extractShortcode(url);
    String author = 'Instagram Creator';
    String title = 'Instagram Reel';
    String caption = '';
    String? thumbnail;
    String? videoUrl;

    // 1. Attempt oEmbed API
    try {
      final oembedUrl = Uri.parse(
        'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(url)}',
      );
      final resp = await http.get(oembedUrl, headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        author = data['author_name'] as String? ?? author;
        title = data['title'] as String? ?? title;
        thumbnail = data['thumbnail_url'] as String?;
      }
    } catch (_) {
      // Continue to HTML scraping fallback
    }

    // 2. Direct public page scraping using OpenGraph crawlers (Instagram permits rich OG meta)
    final crawlerUserAgents = [
      'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      'Twitterbot/1.0',
    ];

    for (final ua in crawlerUserAgents) {
      if (caption.isNotEmpty && thumbnail != null) break;

      try {
        final pageResp = await http.get(Uri.parse(url), headers: {
          'User-Agent': ua,
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        }).timeout(const Duration(seconds: 10));

        if (pageResp.statusCode == 200) {
          final html = pageResp.body;

          // Extract og:title
          final titleMatch = RegExp(
            r'''<meta\s+(?:property|name)=["']og:title["']\s+content=["']([^"']*)["']''',
            caseSensitive: false,
          ).firstMatch(html);
          if (titleMatch != null && titleMatch.groupCount >= 1) {
            final rawTitle = unescapeHtml(titleMatch.group(1)!);
            // Check for author in "User on Instagram: ..."
            final authorMatch = RegExp(r'''^(.*?)\s+on Instagram:''').firstMatch(rawTitle);
            if (authorMatch != null && authorMatch.groupCount >= 1) {
              final parsed = authorMatch.group(1)!.trim();
              if (parsed.isNotEmpty && author == 'Instagram Creator') {
                author = parsed;
              }
            }
            if (title == 'Instagram Reel' && rawTitle.isNotEmpty) {
              title = rawTitle;
            }
          }

          // Extract og:description
          final descMatch = RegExp(
            r'''<meta\s+(?:property|name)=["']og:description["']\s+content=["']([^"']*)["']''',
            caseSensitive: false,
          ).firstMatch(html);
          if (descMatch != null && descMatch.groupCount >= 1) {
            var rawDesc = unescapeHtml(descMatch.group(1)!);

            // Extract author from description if still default: e.g. "- @username on September..."
            final descAuthorMatch = RegExp(r'''-\s*@?([A-Za-z0-9_.]+)\s+on\s+[A-Za-z]+''').firstMatch(rawDesc);
            if (descAuthorMatch != null && descAuthorMatch.groupCount >= 1) {
              final parsed = descAuthorMatch.group(1)!.trim();
              if (parsed.isNotEmpty && (author == 'Instagram Creator' || !author.contains('.'))) {
                author = parsed;
              }
            }

            // Instagram often formats reels as: '7 likes, 0 comments - user on Date: "Actual caption..."'
            final innerQuoteMatch = RegExp(r''':\s*"(.*)"''', dotAll: true).firstMatch(rawDesc);
            if (innerQuoteMatch != null && innerQuoteMatch.groupCount >= 1) {
              caption = innerQuoteMatch.group(1)!.trim();
            } else {
              caption = rawDesc.trim();
            }
          }

          // Extract og:video
          final videoMatch = RegExp(
            r'''<meta\s+property=["']og:video(?::secure_url)?["']\s+content=["']([^"']*)["']''',
            caseSensitive: false,
          ).firstMatch(html);
          if (videoMatch != null && videoMatch.groupCount >= 1) {
            videoUrl = unescapeHtml(videoMatch.group(1)!);
          }

          // Extract og:image
          final imageMatch = RegExp(
            r'''<meta\s+property=["']og:image["']\s+content=["']([^"']*)["']''',
            caseSensitive: false,
          ).firstMatch(html);
          if (imageMatch != null && imageMatch.groupCount >= 1) {
            thumbnail ??= unescapeHtml(imageMatch.group(1)!);
          }
        }
      } catch (_) {
        // Fallback to next crawler
      }
    }

    // Clean up title: if it contains 'on Instagram: "..."', extract the quote
    final titleQuoteMatch = RegExp(r'''on Instagram:\s*"(.*)"''', dotAll: true).firstMatch(title);
    if (titleQuoteMatch != null && titleQuoteMatch.groupCount >= 1) {
      final inner = titleQuoteMatch.group(1)!.trim();
      final firstSentence = inner.split(RegExp(r'\n|\. ')).first.trim();
      if (firstSentence.isNotEmpty) {
        title = firstSentence;
      }
    }

    // If caption is still empty, synthesize from title
    if (caption.isEmpty && title.isNotEmpty) {
      caption = title;
    }

    // If title is still default, use the first sentence of caption
    if ((title == 'Instagram Reel' || title.isEmpty) && caption.isNotEmpty) {
      final firstLine = caption.split(RegExp(r'\n|\. ')).first.trim();
      if (firstLine.isNotEmpty) {
        title = firstLine.length > 60 ? '${firstLine.substring(0, 57)}...' : firstLine;
      }
    }

    return {
      'shortcode': shortcode,
      'author': author.startsWith('@') ? author : '@$author',
      'title': title,
      'caption': caption,
      'thumbnail_url': thumbnail,
      'video_url': videoUrl,
    };
  }

  /// Extracts an executive TL;DR and key bullets from text.
  static Map<String, dynamic> generateExtractiveSummary(String text) {
    if (text.isEmpty) {
      return {
        'tldr': 'No description or transcript available for this content.',
        'key_points': <String>['Content extracted without explicit caption.'],
      };
    }

    // Clean up hashtag spam from caption
    final cleanText = text
        .replaceAll(RegExp(r'#\w+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final sentences = cleanText
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().length > 10)
        .toList();

    String tldr = '';
    List<String> keyPoints = [];

    if (sentences.isNotEmpty) {
      tldr = sentences.first.trim();
      keyPoints = sentences
          .skip(1)
          .take(4)
          .map((s) => s.trim())
          .toList();
    }

    if (tldr.isEmpty) {
      tldr = cleanText.length > 180
          ? '${cleanText.substring(0, 180)}...'
          : cleanText;
    }

    if (keyPoints.isEmpty) {
      keyPoints = [
        'Extracted from Instagram public post content',
        'Scanned for on-screen link occurrences and handles',
      ];
    }

    return {
      'tldr': tldr,
      'key_points': keyPoints,
    };
  }
}

