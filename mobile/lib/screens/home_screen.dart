import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/extraction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/settings_dialog.dart';

/// Main Extraction Input screen mirroring Stitch Screen 1 (screen_1_home.png).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  void _triggerExtract() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      context.read<ExtractionProvider>().startExtraction(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste or enter an Instagram URL first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExtractionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(Icons.lens_blur_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'InstaLens',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Extraction Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
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
            // Subtitle
            const Text(
              'Extract links, transcripts & AI summaries from any public Instagram content.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Mode Selector Segmented Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Row(
                children: [
                  _buildModeTab(
                    title: 'Reel / Video',
                    mode: ExtractionMode.reel,
                    activeMode: provider.mode,
                  ),
                  _buildModeTab(
                    title: 'Single Post',
                    mode: ExtractionMode.post,
                    activeMode: provider.mode,
                  ),
                  _buildModeTab(
                    title: 'Profile',
                    mode: ExtractionMode.profile,
                    activeMode: provider.mode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // URL Input Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instagram URL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // TextField with Paste Chip
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _getPlaceholderForMode(provider.mode),
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_urlController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: AppTheme.onSurfaceVariant,
                              onPressed: () {
                                setState(() {
                                  _urlController.clear();
                                });
                              },
                            ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              onPressed: _pasteFromClipboard,
                              icon: const Icon(Icons.paste_rounded, size: 14),
                              label: const Text('Paste', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceContainerHighest,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Supports public Instagram Reels, Posts, Carousels, and Profile URLs.',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Primary Extract Action Button
            GradientButton(
              text: 'Extract Links & Summary',
              icon: Icons.auto_awesome_rounded,
              isLoading: provider.status == ExtractionStatus.loading,
              onPressed: _triggerExtract,
            ),

            const SizedBox(height: 28),

            // Feature Highlights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x12FFFFFF)),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.document_scanner_rounded,
                    title: 'On-Screen OCR Link Detection',
                    subtitle: 'Detects URLs embedded directly inside video frames',
                    accentColor: AppTheme.primary,
                  ),
                  const Divider(color: Color(0x14FFFFFF), height: 20),
                  _buildFeatureRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Audio Transcription',
                    subtitle: 'Converts spoken dialogue to searchable text context',
                    accentColor: AppTheme.secondary,
                  ),
                  const Divider(color: Color(0x14FFFFFF), height: 20),
                  _buildFeatureRow(
                    icon: Icons.summarize_rounded,
                    title: 'AI Executive Summary',
                    subtitle: 'Synthesizes high-impact key points and concise TL;DR',
                    accentColor: AppTheme.tertiary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Recent Extractions List
            if (provider.recentExtractions.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Recent Extractions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => provider.clearHistory(),
                    child: const Text('Clear', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...provider.recentExtractions.map((item) {
                return _buildRecentCard(item, provider);
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required ExtractionMode mode,
    required ExtractionMode activeMode,
  }) {
    final isSelected = mode == activeMode;

    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ExtractionProvider>().setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getPlaceholderForMode(ExtractionMode mode) {
    switch (mode) {
      case ExtractionMode.reel:
        return 'https://www.instagram.com/reel/C3b4X...';
      case ExtractionMode.post:
        return 'https://www.instagram.com/p/C9v8Y...';
      case ExtractionMode.profile:
        return 'https://www.instagram.com/username';
    }
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(Map<String, dynamic> item, ExtractionProvider provider) {
    final title = item['title'] as String? ?? 'Instagram Reel';
    final author = item['author'] as String? ?? '@creator';
    final linkCount = item['linkCount'] as int? ?? 0;
    final url = item['url'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.movie_rounded, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$author • $linkCount links found',
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.onSurfaceVariant, size: 14),
        onTap: () {
          _urlController.text = url;
          provider.startExtraction(url);
        },
      ),
    );
  }
}

