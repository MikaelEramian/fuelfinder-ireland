import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fuel_preference_provider.dart';
import '../utils/constants.dart';

class FuelSelectorScreen extends ConsumerWidget {
  const FuelSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const Icon(
                Icons.local_gas_station,
                size: 56,
                color: kPrimaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to\nFuelFinder Ireland',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'What fuel are you looking for?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 40),
              _FuelOption(
                icon: Icons.water_drop,
                label: 'Petrol',
                subtitle: 'Show petrol prices only',
                onTap: () => _selectAndContinue(context, ref, FuelType.petrol),
              ),
              const SizedBox(height: 12),
              _FuelOption(
                icon: Icons.water_drop,
                label: 'Diesel',
                subtitle: 'Show diesel prices only',
                onTap: () => _selectAndContinue(context, ref, FuelType.diesel),
              ),
              const SizedBox(height: 12),
              _FuelOption(
                icon: Icons.compare_arrows,
                label: 'Both',
                subtitle: 'Show petrol and diesel prices',
                onTap: () => _selectAndContinue(context, ref, FuelType.both),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAndContinue(
    BuildContext context,
    WidgetRef ref,
    FuelType type,
  ) {
    ref.read(fuelPreferenceProvider.notifier).setFuelType(type);
    Navigator.of(context).pushReplacementNamed('/home');
  }
}

class _FuelOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _FuelOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kPrimaryGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
