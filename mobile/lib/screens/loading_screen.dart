import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/extraction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/step_progress_stepper.dart';

/// Loading and extraction in-progress screen mirroring Stitch Screen 3 (screen_3_loading.png).
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExtractionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('InstaLens'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            provider.cancelExtraction();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Glowing Circular Progress Indicator
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.25),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          backgroundColor: AppTheme.surfaceContainerHigh,
                        ),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceContainer,
                        ),
                        child: const Icon(
                          Icons.movie_filter_rounded,
                          color: AppTheme.primary,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Header & URL
              const Text(
                'Extracting Reel Content...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                provider.currentUrl,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 32),

              // Live 5-Step Stepper Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                ),
                child: StepProgressStepper(
                  currentEvent: provider.currentProgress,
                ),
              ),

              const SizedBox(height: 24),

              // Informative Tip Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x12FFFFFF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppTheme.tertiary, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tip: OCR scans on-screen frames and captions for domain patterns without requiring login cookies.',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Cancel Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurfaceVariant,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    provider.cancelExtraction();
                  },
                  child: const Text('Cancel Extraction'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

