import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PriceReportForm extends StatefulWidget {
  final String stationName;
  final Function(String fuelType, double price) onSubmit;

  const PriceReportForm({
    super.key,
    required this.stationName,
    required this.onSubmit,
  });

  @override
  State<PriceReportForm> createState() => _PriceReportFormState();
}

class _PriceReportFormState extends State<PriceReportForm> {
  String _fuelType = 'petrol';
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Enter a price';
    final price = double.tryParse(value);
    if (price == null) return 'Enter a valid number';
    if (price < kMinFuelPrice || price > kMaxFuelPrice) {
      return 'Price must be between €${kMinFuelPrice.toStringAsFixed(2)} and €${kMaxFuelPrice.toStringAsFixed(2)}';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final price = double.parse(_priceController.text);
      await widget.onSubmit(_fuelType, price);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
            Text(
              'Report Price',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.stationName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _fuelType,
              decoration: const InputDecoration(labelText: 'Fuel Type'),
              items: const [
                DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
              ],
              onChanged: (v) => setState(() => _fuelType = v!),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price per litre',
                prefixText: '€ ',
                hintText: '1.699',
              ),
              validator: _validatePrice,
            ),
            const SizedBox(height: 12),

            Text(
              'Prices are user-reported and may not reflect current pricing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Submit Price'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
