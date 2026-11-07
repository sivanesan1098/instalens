import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/extraction_provider.dart';
import '../theme/app_theme.dart';

/// Settings modal for configuring the hybrid extraction engine and backend URLs.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;
  late bool _useBackend;
  bool _testingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExtractionProvider>();
    _urlController = TextEditingController(text: provider.backendBaseUrl);
    _useBackend = provider.useBackendFallback;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = null;
    });

    final provider = context.read<ExtractionProvider>();
    final isHealthy = await provider.coordinator.apiService.checkHealth();

    setState(() {
      _testingConnection = false;
      _connectionStatus = isHealthy
          ? 'Connected! FastAPI backend is running.'
          : 'Could not connect. Verify host and port.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Extraction Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hybrid Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
                title: const Text(
                  'Backend Service Fallback',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Use local/remote FastAPI backend (yt-dlp, Whisper) when available',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
                value: _useBackend,
                onChanged: (val) {
                  setState(() => _useBackend = val);
                },
              ),

              const Divider(color: Color(0x1AFFFFFF), height: 24),

              // Backend URL
              const Text(
                'FastAPI Backend URL',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                enabled: _useBackend,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'http://10.0.2.2:8000',
                  prefixIcon: Icon(Icons.dns_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: 8),

              // Preset shortcut chips
              Wrap(
                spacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    onPressed: _useBackend
                        ? () => _urlController.text = 'http://10.0.2.2:8000'
                        : null,
                  ),
                  ActionChip(
                    label: const Text('Localhost (8000)', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    onPressed: _useBackend
                        ? () => _urlController.text = 'http://localhost:8000'
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Test connection action
              if (_useBackend) ...[
                OutlinedButton.icon(
                  onPressed: _testingConnection ? null : _testConnection,
                  icon: _testingConnection
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        )
                      : const Icon(Icons.network_check_rounded, size: 16),
                  label: const Text('Test Backend Connection'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_connectionStatus != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _connectionStatus!,
                    style: TextStyle(
                      color: _connectionStatus!.contains('Connected')
                          ? AppTheme.success
                          : AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],

              const Divider(color: Color(0x1AFFFFFF), height: 24),

              // Clear History
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 20),
                title: const Text(
                  'Clear Extraction History',
                  style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  context.read<ExtractionProvider>().clearHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recent extraction history cleared.')),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    context.read<ExtractionProvider>().updateSettings(
                          useBackendFallback: _useBackend,
                          backendBaseUrl: _urlController.text.trim(),
                        );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save & Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

