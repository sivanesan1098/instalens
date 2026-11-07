import 'package:flutter_test/flutter_test.dart';
import 'package:insta_lens_mobile/services/instagram_scraper_service.dart';

void main() {
  group('InstagramScraperService URL Normalization & Regex Parity Tests', () {
    test('Canonical deduplication matches backend.py rules', () {
      final cases = [
        ('https://github.com/a/b', 'https://github.com/a/b'),
        ('https://github.com/a/b/', 'https://github.com/a/b'),
        ('https://www.example.com', 'https://example.com'),
        ('https://x.com/path.', 'https://x.com/path'),
      ];

      for (final (raw, want) in cases) {
        final got = InstagramScraperService.normalizeForDedup(raw);
        expect(got, equals(want), reason: '$raw failed to normalize to $want');
      }

      expect(
        InstagramScraperService.normalizeForDedup('https://github.com/a/b'),
        equals(InstagramScraperService.normalizeForDedup('https://www.github.com/a/b/')),
      );

      expect(
        InstagramScraperService.normalizeForDedup('https://x.com'),
        equals(InstagramScraperService.normalizeForDedup('https://www.x.com')),
      );
    });

    test('Regex does not match bare email addresses as URLs', () {
      final text = 'reach me at hello@example.com today';
      final links = InstagramScraperService.extractUrlsFromText(text, 'caption');
      expect(links, isEmpty);
    });

    test('Regex correctly extracts various affiliate and social link formats', () {
      final text = '''
      Check out my desk setup gear:
      1. Monitor arm: https://amzn.to/3xyzDesk.
      2. Notion hub: notion.so/setup-template!
      3. Linktree in bio: linktr.ee/creator, or gumroad.com/l/assets?
      And visit https://www.example.com/page/
      ''';

      final links = InstagramScraperService.extractUrlsFromText(text, 'caption');
      final normalizedUrls = links.map((l) => l.normalizedUrl).toList();

      expect(normalizedUrls, contains('https://amzn.to/3xyzDesk'));
      expect(normalizedUrls, contains('https://notion.so/setup-template'));
      expect(normalizedUrls, contains('https://linktr.ee/creator'));
      expect(normalizedUrls, contains('https://gumroad.com/l/assets'));
      expect(normalizedUrls, contains('https://www.example.com/page/'));
    });

    test('Extractive summary extracts TL;DR and key points', () {
      final caption = '''
      The best 3 productivity desk accessories for 2025.
      First is an ergonomic monitor mount with cable routing.
      Second is a magnetic dual device fast charger.
      Third is an auto-dimming smart bar lamp.
      #desksetup #workspace #tech
      ''';

      final summary = InstagramScraperService.generateExtractiveSummary(caption);
      expect(summary['tldr'], isNotEmpty);
      expect(summary['tldr'], contains('best 3 productivity'));
      final points = summary['key_points'] as List<String>;
      expect(points.length, greaterThanOrEqualTo(2));
    });

    test('Shortcode extractor correctly parses reel and post URLs', () {
      expect(
        InstagramScraperService.extractShortcode('https://www.instagram.com/reel/C3b4X9yZ123/'),
        equals('C3b4X9yZ123'),
      );
      expect(
        InstagramScraperService.extractShortcode('https://instagram.com/p/DF987654321?igsh=abc'),
        equals('DF987654321'),
      );
    });

    test('HTML unescape converts entities and hex code points correctly', () {
      final input = 'Claude &amp; SEO &#x1f4c8; &quot;quote&quot; &apos;single&apos; &#x201c;smart&#x201d;';
      final output = InstagramScraperService.unescapeHtml(input);
      expect(output, contains('Claude & SEO'));
      expect(output, contains('"quote"'));
      expect(output, contains("'single'"));
      expect(output, contains('“smart”'));
    });

    test('Regex extracts links from real reel captions with ai domains', () {
      final text = '''
      This skill turns Claude into your own customer research team. 🔎
      Install Gooseworks (one command), then in Claude Code type: “mine the best ad angles for my brand.”
      ▶️ Get it free at skills.gooseworks.ai
      Powerful Claude Skills — Pt. 9 #copywriting #claude
      ''';
      final links = InstagramScraperService.extractUrlsFromText(text, 'caption');
      expect(links.length, equals(1));
      expect(links.first.normalizedUrl, equals('https://skills.gooseworks.ai'));
    });
  });
}
