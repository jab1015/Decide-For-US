import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';
import 'screens/decide_screen.dart';
import 'services/age_signals_service.dart';

class DecideApp extends StatefulWidget {
  const DecideApp({super.key});

  @override
  State<DecideApp> createState() => _DecideAppState();
}

class _DecideAppState extends State<DecideApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isCheckingAgeSignals = false;
  bool _verificationDialogIsOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAgeSignals());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAgeSignals();
  }

  Future<void> _checkAgeSignals() async {
    if (_isCheckingAgeSignals) return;
    _isCheckingAgeSignals = true;
    final result = await AgeSignalsService.check();
    _isCheckingAgeSignals = false;

    if (!mounted ||
        result.status != AgeSignalsStatus.verificationRequired ||
        _verificationDialogIsOpen) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) return;
    _verificationDialogIsOpen = true;
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Age verification required'),
        content: const Text(
          'Google Play needs you to verify your age or set up parental '
          'supervision before you continue.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final storeUri = Uri.parse(
                'market://details?id=com.decideforus.app',
              );
              final opened = await launchUrl(
                storeUri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened) {
                await launchUrl(
                  Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.decideforus.app',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Open Google Play'),
          ),
        ],
      ),
    );
    _verificationDialogIsOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Decide For Us',
      theme: AppTheme.light(),
      home: const DecideScreen(),
    );
  }
}
