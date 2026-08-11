import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForcedUpdateScreen extends StatelessWidget {
  const ForcedUpdateScreen({
    super.key,
    required this.message,
    required this.storeUrl,
    required this.currentVersion,
    required this.minimumVersion,
  });

  final String message;
  final String storeUrl;
  final String currentVersion;
  final String minimumVersion;

  Future<void> _openStore(BuildContext context) async {
    if (storeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The update link is not available yet. Please try again shortly.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(storeUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the app store. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.system_update_alt, size: 72),
                    const SizedBox(height: 24),
                    Text(
                      'Update Required',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Installed: $currentVersion   Required: $minimumVersion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openStore(context),
                        icon: const Icon(Icons.open_in_new),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Update Now'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You must install the latest required version before continuing.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
