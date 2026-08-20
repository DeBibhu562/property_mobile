import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  double _loanAmount = 5000000; // 50 Lakhs default
  double _interestRate = 8.5; // 8.5% default
  double _tenure = 20; // 20 Years default

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String _formatIndianCurrency(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} Lakhs';
    }
    return _currencyFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    // Formula: [P x R x (1+R)^N]/[((1+R)^N)-1]
    final double p = _loanAmount;
    final double r = _interestRate / 12 / 100;
    final double n = _tenure * 12;

    final double emi = r > 0
        ? (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
        : p / n;

    final double totalPayable = emi * n;
    final double totalInterest = totalPayable - p;

    final theme = Theme.of(context);

    final cardBody = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Monthly EMI',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormat.format(emi),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Sliders Section
          _buildSliderGroup(
            label: 'Loan Amount',
            currentValueText: _formatIndianCurrency(_loanAmount),
            value: _loanAmount,
            min: 500000,
            max: 50000000,
            divisions: 99,
            minLabel: '₹5 L',
            maxLabel: '₹5 Cr',
            onChanged: (val) => setState(() => _loanAmount = val),
          ),
          const SizedBox(height: 20),
          _buildSliderGroup(
            label: 'Interest Rate',
            currentValueText: '${_interestRate.toStringAsFixed(1)}% p.a.',
            value: _interestRate,
            min: 5.0,
            max: 15.0,
            divisions: 100,
            minLabel: '5%',
            maxLabel: '15%',
            onChanged: (val) => setState(() => _interestRate = val),
          ),
          const SizedBox(height: 20),
          _buildSliderGroup(
            label: 'Loan Tenure',
            currentValueText: '${_tenure.toInt()} Years',
            value: _tenure,
            min: 1,
            max: 30,
            divisions: 29,
            minLabel: '1 Yr',
            maxLabel: '30 Yrs',
            onChanged: (val) => setState(() => _tenure = val),
          ),
          const SizedBox(height: 28),
          // Details breakdown
          const Divider(),
          const SizedBox(height: 16),
          _buildDetailRow('Principal Loan Amount', _currencyFormat.format(_loanAmount)),
          const SizedBox(height: 12),
          _buildDetailRow('Total Interest Payable', _currencyFormat.format(totalInterest)),
          const SizedBox(height: 12),
          _buildDetailRow('Total Amount Payable', _currencyFormat.format(totalPayable)),
        ],
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('EMI Calculator'),
          automaticallyImplyLeading: false,
        ),
        body: cardBody,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('EMI Calculator')),
      body: cardBody,
    );
  }

  Widget _buildSliderGroup({
    required String label,
    required String currentValueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              currentValueText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: theme.textTheme.bodySmall),
            Text(maxLabel, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
