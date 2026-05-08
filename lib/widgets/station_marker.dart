import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StationMarkerWidget extends StatelessWidget {
  final double? price;
  final FuelType fuelType;
  final Color color;
  final VoidCallback? onTap;
  final double scale;
  final bool hasPrice;

  const StationMarkerWidget({
    super.key,
    this.price,
    required this.fuelType,
    this.color = kPrimaryGreen,
    this.scale = 1.0,
    this.hasPrice = true,
    this.onTap,
  });

  String get _displayPrice {
    if (!hasPrice || price == null) return 'No price yet';
    return '€${price!.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasPrice ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: hasPrice ? null : Border.all(color: color, width: 1.5),
                  boxShadow: hasPrice ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: hasPrice ? Colors.white : color,
                    fontSize: hasPrice ? 11 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                  child: Text(_displayPrice),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasPrice ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: hasPrice ? null : Border.all(color: color, width: 2),
                  boxShadow: hasPrice ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ] : null,
                ),
                child: Icon(
                  Icons.local_gas_station,
                  color: hasPrice ? Colors.white : color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget used inside marker clusters to show count.
class ClusterMarkerWidget extends StatelessWidget {
  final int count;
  final Color color;

  const ClusterMarkerWidget({
    super.key,
    required this.count,
    this.color = kPrimaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
