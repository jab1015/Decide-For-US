import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

enum PaywallResult { subscribed, testerReset }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<Package> _packages = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    try {
      final offerings = await SubscriptionService.getOfferings();
      final packages =
          offerings.current?.availablePackages ?? const <Package>[];
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _error = packages.isEmpty
            ? 'No subscription is currently available.'
            : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Subscriptions are temporarily unavailable.';
        _loading = false;
      });
    }
  }

  Future<void> _subscribe(Package package) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subscribed = await SubscriptionService.purchase(package);
      if (!mounted) return;
      if (subscribed) {
        Navigator.pop(context, PaywallResult.subscribed);
      } else {
        setState(() => _error = 'The purchase did not unlock Premium.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The purchase was not completed.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final restored = await SubscriptionService.restore();
      if (!mounted) return;
      if (restored) {
        Navigator.pop(context, PaywallResult.subscribed);
      } else {
        setState(() => _error = 'No active Premium purchase was found.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Purchases could not be restored.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _packageLabel(Package package) {
    return switch (package.packageType) {
      PackageType.monthly => 'Monthly',
      PackageType.annual => 'Yearly',
      _ => package.storeProduct.title,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Make more\nmemories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Date Night+  •  Local Events+\nTrip planning  •  Unlimited adventures',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
                  ..._packages.map(
                    (package) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FilledButton(
                        onPressed: () => _subscribe(package),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_packageLabel(package)),
                            const SizedBox(width: 8),
                            Text(
                              '— ${package.storeProduct.priceString}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: _loading ? null : _restore,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
