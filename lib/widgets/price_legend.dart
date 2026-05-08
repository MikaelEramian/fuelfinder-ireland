import 'package:flutter/material.dart';

class PriceLegend extends StatefulWidget {
  const PriceLegend({super.key});

  @override
  State<PriceLegend> createState() => _PriceLegendState();
}

class _PriceLegendState extends State<PriceLegend> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _isVisible = false;
        });
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Great deal', const Color(0xFF00C853)),
            const SizedBox(width: 12),
            _buildLegendItem('Below avg', const Color(0xFFFFD600)),
            const SizedBox(width: 12),
            _buildLegendItem('Above avg', const Color(0xFFFF9100)),
            const SizedBox(width: 12),
            _buildLegendItem('Expensive', const Color(0xFFFF1744)),
            const SizedBox(width: 8),
            Icon(
              Icons.close,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
