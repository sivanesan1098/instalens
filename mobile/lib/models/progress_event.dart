/// Represents a pipeline progress event during extraction.
class ProgressEvent {
  final String stage;
  final int step;
  final int totalSteps;
  final String message;
  final String timestamp;
  final Map<String, dynamic>? data;

  const ProgressEvent({
    required this.stage,
    required this.step,
    required this.totalSteps,
    required this.message,
    required this.timestamp,
    this.data,
  });

  factory ProgressEvent.fromJson(Map<String, dynamic> json) {
    return ProgressEvent(
      stage: json['stage'] as String? ?? 'init',
      step: json['step'] as int? ?? 1,
      totalSteps: json['total_steps'] as int? ?? 5,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'step': step,
    'total_steps': totalSteps,
    'message': message,
    'timestamp': timestamp,
    if (data != null) 'data': data,
  };
}

