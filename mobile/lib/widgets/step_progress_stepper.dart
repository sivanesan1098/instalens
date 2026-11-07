import 'package:flutter/material.dart';
import '../models/progress_event.dart';
import '../theme/app_theme.dart';

/// 5-Stage extraction pipeline stepper mirroring Stitch Screen 3.
class StepProgressStepper extends StatelessWidget {
  final ProgressEvent? currentEvent;

  const StepProgressStepper({super.key, this.currentEvent});

  static const List<Map<String, String>> steps = [
    {
      'stage': 'download',
      'title': 'Downloading Instagram Media',
      'desc': 'Fetching public stream and metadata',
    },
    {
      'stage': 'transcribe',
      'title': 'Whisper Audio Transcription',
      'desc': 'Processing audio context and captions',
    },
    {
      'stage': 'ocr',
      'title': 'Running Video OCR Analysis',
      'desc': 'Scanning video frames for on-screen text',
    },
    {
      'stage': 'links',
      'title': 'Parsing & Verifying Links',
      'desc': 'Detecting URLs and matching domains',
    },
    {
      'stage': 'summary',
      'title': 'Generating AI Summary',
      'desc': 'Extracting TL;DR and key points',
    },
  ];

  int _getActiveStepIndex() {
    if (currentEvent == null) return 0;
    if (currentEvent!.stage == 'complete') return steps.length;
    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['stage'] == currentEvent!.stage) {
        return i;
      }
    }
    return (currentEvent!.step - 1).clamp(0, steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getActiveStepIndex();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        final isPending = index > activeIndex;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper Line & Indicator
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppTheme.success.withValues(alpha: 0.2)
                          : (isActive
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : AppTheme.surfaceContainerHighest),
                      border: Border.all(
                        color: isCompleted
                            ? AppTheme.success
                            : (isActive ? AppTheme.primary : Colors.transparent),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, color: AppTheme.success, size: 16)
                          : (isActive
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isCompleted
                            ? AppTheme.success.withValues(alpha: 0.5)
                            : AppTheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and Description
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: TextStyle(
                          color: isPending
                              ? AppTheme.onSurfaceVariant
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (isActive && currentEvent?.message != null && currentEvent!.message.isNotEmpty)
                            ? currentEvent!.message
                            : step['desc']!,
                        style: TextStyle(
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

