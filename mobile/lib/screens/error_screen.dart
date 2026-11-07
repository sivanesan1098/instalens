import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/extraction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/settings_dialog.dart';

/// Extraction Failed / Error screen mirroring Stitch Screen 4 (screen_4_error.png).
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExtractionProvider>();
    final isPrivate = provider.errorStatusCode == 403 ||
        (provider.errorMessage?.toLowerCase().contains('private') ?? false);
    final errorText = provider.errorMessage ?? 'An unexpected extraction error occurred.';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => provider.resetToIdle(),
        ),
        title: const Text('Extraction Failed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Error Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                ),
                child: Column(
                  children: [
                    // Glowing Warning Badge
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        border: Border.all(color: AppTheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.primary,
                        size: 38,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Could Not Extract Content',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'The Instagram URL could not be processed by the extraction engine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Error Reason Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPrivate
                                      ? '403 Forbidden / Private Post'
                                      : 'Extraction Engine Error',
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPrivate
                                ? 'Reason: This post is from a private account or requires authentication. Public Instagram reels and posts only are supported without cookies.'
                                : 'Details: $errorText',
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Troubleshooting Checklist Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x12FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Troubleshooting Checklist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      icon: Icons.public_rounded,
                      text: 'Verify the Instagram link is publicly viewable in a browser without logging in.',
                    ),
                    const SizedBox(height: 10),
                    _buildChecklistItem(
                      icon: Icons.link_rounded,
                      text: 'Ensure the link starts with instagram.com/reel/ or instagram.com/p/.',
                    ),
                    const SizedBox(height: 10),
                    _buildChecklistItem(
                      icon: Icons.dns_rounded,
                      text: 'If using backend mode, check if the FastAPI server is running on the configured host.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Primary Action: Try Another URL
              GradientButton(
                text: 'Try Another URL',
                icon: Icons.refresh_rounded,
                onPressed: () => provider.resetToIdle(),
              ),

              const SizedBox(height: 12),

              // Secondary Action: Retry
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x2EFFFFFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    provider.startExtraction(provider.currentUrl);
                  },
                  child: const Text('Retry Extraction'),
                ),
              ),

              const SizedBox(height: 10),

              // Tertiary Action: Server Settings
              TextButton.icon(
                icon: const Icon(Icons.settings_rounded, size: 16, color: AppTheme.primary),
                label: const Text(
                  'Server & Engine Settings',
                  style: TextStyle(color: AppTheme.primary, fontSize: 13),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog(),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

