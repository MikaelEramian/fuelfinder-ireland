import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AdBannerPlaceholder extends StatelessWidget {
  final bool showAd;

  const AdBannerPlaceholder({super.key, this.showAd = true});

  @override
  Widget build(BuildContext context) {
    if (!showAd) return const SizedBox.shrink();

    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkCard.withValues(alpha: 0.9)
            : Colors.grey.shade200,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Center(
        child: Text(
          'Ad space',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
