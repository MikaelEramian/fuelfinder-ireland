import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fuel_preference_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stations_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelType = ref.watch(fuelPreferenceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);
    final defaultZoom = ref.watch(defaultZoomProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Fuel Preference'),
            const SizedBox(height: 8),
            _SegmentedControl<FuelType>(
              values: FuelType.values,
              selected: fuelType,
              labelOf: (v) => v.name[0].toUpperCase() + v.name.substring(1),
              onChanged: (v) =>
                  ref.read(fuelPreferenceProvider.notifier).setFuelType(v),
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Appearance'),
            const SizedBox(height: 8),
            _SegmentedControl<AppThemeMode>(
              values: AppThemeMode.values,
              selected: themeMode,
              labelOf: (v) => v.name[0].toUpperCase() + v.name.substring(1),
              onChanged: (v) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(v),
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Distance Unit'),
            const SizedBox(height: 8),
            _SegmentedControl<DistanceUnit>(
              values: DistanceUnit.values,
              selected: distanceUnit,
              labelOf: (v) => v == DistanceUnit.km ? 'Kilometres' : 'Miles',
              onChanged: (v) =>
                  ref.read(distanceUnitProvider.notifier).setUnit(v),
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Default Map Zoom'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Far'),
                Expanded(
                  child: Slider(
                    value: defaultZoom,
                    min: kMinMapZoom,
                    max: kMaxMapZoom,
                    divisions: ((kMaxMapZoom - kMinMapZoom) * 2).toInt(),
                    activeColor: kPrimaryGreen,
                    onChanged: (v) =>
                        ref.read(defaultZoomProvider.notifier).setZoom(v),
                  ),
                ),
                const Text('Close'),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Data'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Clear Cache',
              subtitle: 'Remove cached station data',
              onTap: () async {
                final repo = ref.read(stationRepositoryProvider);
                await repo.clearCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared.')),
                  );
                }
              },
            ),
            _SettingsTile(
              icon: Icons.restore,
              title: 'Restore Purchase',
              subtitle: 'Restore your premium subscription',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'About'),
            const SizedBox(height: 8),
            const _SettingsTile(
              icon: Icons.info_outline,
              title: 'FuelFinder Ireland',
              subtitle: 'Version 1.0.0',
              onTap: null,
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: '',
              onTap: () => _showPlaceholderPage(context, 'Privacy Policy'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: '',
              onTap: () => _showPlaceholderPage(context, 'Terms of Service'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderPage(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '$title content coming soon.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kPrimaryGreen,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _SegmentedControl({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkCard
            : Colors.grey.shade200,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: values.map((v) {
          final isSelected = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labelOf(v),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing:
          onTap != null ? const Icon(Icons.chevron_right, size: 20) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
