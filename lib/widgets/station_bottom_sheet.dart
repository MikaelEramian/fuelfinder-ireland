import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/station.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class StationBottomSheet extends StatelessWidget {
  final Station station;
  final FuelType selectedFuelType;
  final DistanceUnit distanceUnit;
  final double? userLat;
  final double? userLng;
  final Color? dynamicColor;
  final Map<String, double>? nationalAvgs;
  final VoidCallback onReportPrice;

  const StationBottomSheet({
    super.key,
    required this.station,
    required this.selectedFuelType,
    required this.distanceUnit,
    this.userLat,
    this.userLng,
    this.dynamicColor,
    this.nationalAvgs,
    required this.onReportPrice,
  });

  String get _distanceText {
    if (userLat == null || userLng == null) return '';
    final km = calculateDistanceKm(
      userLat!, userLng!, station.latitude, station.longitude,
    );
    return '${formatDistance(km, distanceUnit)} away';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (station.brand != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        station.brand!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_distanceText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _distanceText,
                    style: const TextStyle(
                      color: kPrimaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            station.address,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (station.county != null)
            Text(
              station.county!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          const SizedBox(height: 16),

          Row(
            children: [
              _PriceCard(
                label: 'Petrol',
                price: station.petrolPrice,
                updatedAt: station.petrolUpdatedAt,
                isHighlighted: selectedFuelType == FuelType.petrol ||
                    selectedFuelType == FuelType.both,
                badgeColor: (selectedFuelType == FuelType.petrol || selectedFuelType == FuelType.both) ? dynamicColor : null,
                nationalAverage: nationalAvgs?['petrol'],
              ),
              const SizedBox(width: 12),
              _PriceCard(
                label: 'Diesel',
                price: station.dieselPrice,
                updatedAt: station.dieselUpdatedAt,
                isHighlighted: selectedFuelType == FuelType.diesel ||
                    selectedFuelType == FuelType.both,
                badgeColor: (selectedFuelType == FuelType.diesel || selectedFuelType == FuelType.both) ? dynamicColor : null,
                nationalAverage: nationalAvgs?['diesel'],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onReportPrice,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Report Price'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final lat = station.latitude;
    final lng = station.longitude;
    Uri uri;

    if (Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app.')),
        );
      }
    }
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final double? price;
  final DateTime? updatedAt;
  final bool isHighlighted;
  final Color? badgeColor;
  final double? nationalAverage;

  const _PriceCard({
    required this.label,
    this.price,
    this.updatedAt,
    this.isHighlighted = false,
    this.badgeColor,
    this.nationalAverage,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? kPrimaryGreen.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
              ? Border.all(color: kPrimaryGreen.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isHighlighted ? kPrimaryGreen : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (price != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (badgeColor != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    formatPrice(price),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isHighlighted ? kPrimaryGreen : null,
                    ),
                  ),
                ],
              ),
              if (nationalAverage != null && nationalAverage! > 0) ...[
                Builder(
                  builder: (context) {
                    final diff = price! - nationalAverage!;
                    String diffText;
                    Color diffColor;
                    if (diff < -0.08) {
                      diffText = '€${diff.abs().toStringAsFixed(2)} below average';
                      diffColor = const Color(0xFF00C853);
                    } else if (diff < 0.00) {
                      diffText = '€${diff.abs().toStringAsFixed(2)} below average';
                      diffColor = const Color(0xFFFFD600);
                    } else if (diff <= 0.08) {
                      diffText = '€${diff.toStringAsFixed(2)} above average';
                      diffColor = const Color(0xFFFF9100);
                    } else {
                      diffText = '€${diff.toStringAsFixed(2)} above average';
                      diffColor = const Color(0xFFFF1744);
                    }
                    if (diff.abs() < 0.005) {
                      diffText = 'Matches average exactly';
                      diffColor = const Color(0xFFFFD600);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        diffText,
                        style: TextStyle(
                          fontSize: 12,
                          color: diffColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                ),
              ],
              if (updatedAt != null)
                Text(
                  'Updated ${timeAgo(updatedAt!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ] else
              Text(
                'No price reported\n— be the first!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
