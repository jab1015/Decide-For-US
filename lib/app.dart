import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/decide_screen.dart';
import 'screens/forced_update_screen.dart';
import 'services/age_signals_service.dart';
import 'services/forced_update_service.dart';
import 'theme/app_theme.dart';

class DecideApp extends StatefulWidget {
  const DecideApp({
    super.key,
    this.forcedUpdateCheck = ForcedUpdateService.check,
  });

  final Future<ForcedUpdateResult> Function() forcedUpdateCheck;

  @override
  State<DecideApp> createState() => _DecideAppState();
}

class _DecideAppState extends State<DecideApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  bool _isCheckingAgeSignals = false;
  bool _verificationDialogIsOpen = false;
  bool _isCheckingForcedUpdate = true;
  ForcedUpdateResult? _forcedUpdateResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupChecks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForcedUpdate().then((_) {
        if (_forcedUpdateResult?.isRequired != true) {
          _checkAgeSignals();
        }
      });
    }
  }

  Future<void> _runStartupChecks() async {
    await _checkForcedUpdate();
    if (_forcedUpdateResult?.isRequired != true) {
      await _checkAgeSignals();
    }
  }

  Future<void> _checkForcedUpdate() async {
    if (mounted) {
      setState(() => _isCheckingForcedUpdate = true);
    }

    final result = await widget.forcedUpdateCheck();

    if (!mounted) return;
    setState(() {
      _forcedUpdateResult = result;
      _isCheckingForcedUpdate = false;
    });
  }

  Future<void> _checkAgeSignals() async {
    if (_isCheckingAgeSignals || _forcedUpdateResult?.isRequired == true) {
      return;
    }
    _isCheckingAgeSignals = true;
    final result = await AgeSignalsService.check();
    _isCheckingAgeSignals = false;

    if (!mounted ||
        result.status != AgeSignalsStatus.verificationRequired ||
        _verificationDialogIsOpen ||
        _forcedUpdateResult?.isRequired == true) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) return;
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

  Widget _home() {
    if (_isCheckingForcedUpdate && _forcedUpdateResult == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final forcedUpdate = _forcedUpdateResult;
    if (forcedUpdate?.isRequired == true) {
      return ForcedUpdateScreen(
        message: forcedUpdate!.message,
        storeUrl: forcedUpdate.storeUrl,
        currentVersion: forcedUpdate.currentVersion,
        minimumVersion: forcedUpdate.minimumVersion,
      );
    }

    return const DecideScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Decide For Us',
      theme: AppTheme.light(),
      home: _home(),
    );
  }
}
