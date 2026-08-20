import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmiCalculatorWidget extends StatefulWidget {
  const EmiCalculatorWidget({super.key});

  @override
  State<EmiCalculatorWidget> createState() => _EmiCalculatorWidgetState();
}

class _EmiCalculatorWidgetState extends State<EmiCalculatorWidget> {
  double _loanAmount = 5000000;
  double _interestRate = 8.5;
  double _tenureYears = 20;

  double get _emi {
    final principal = _loanAmount;
    final ratePerMonth = _interestRate / (12 * 100);
    final totalMonths = _tenureYears * 12;

    if (ratePerMonth == 0) return principal / totalMonths;

    final numerator = principal * ratePerMonth * pow(1 + ratePerMonth, totalMonths);
    final denominator = pow(1 + ratePerMonth, totalMonths) - 1;
    return numerator / denominator;
  }

  double get _totalPayment {
    return _emi * _tenureYears * 12;
  }

  double get _totalInterest {
    return _totalPayment - _loanAmount;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EMI Calculator',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSlider(
                        label: 'Loan Amount',
                        value: _loanAmount,
                        min: 100000,
                        max: 100000000, // 10 Cr
                        divisions: 1000,
                        onChanged: (val) => setState(() => _loanAmount = val),
                        displayValue: _formatCurrency(_loanAmount),
                        color: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Interest Rate (%)',
                        value: _interestRate,
                        min: 5.0,
                        max: 15.0,
                        divisions: 100,
                        onChanged: (val) => setState(() => _interestRate = val),
                        displayValue: '${_interestRate.toStringAsFixed(1)}%',
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Tenure (Years)',
                        value: _tenureYears,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        onChanged: (val) => setState(() => _tenureYears = val),
                        displayValue: '${_tenureYears.toStringAsFixed(0)} Yrs',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            startDegreeOffset: -90,
                            sections: [
                              PieChartSectionData(
                                color: primaryColor,
                                value: _loanAmount,
                                title: '',
                                radius: 12,
                              ),
                              PieChartSectionData(
                                color: secondaryColor,
                                value: _totalInterest,
                                title: '',
                                radius: 12,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Monthly EMI',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                            Text(
                              '₹${(_emi).toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegend(
                          color: primaryColor,
                          label: 'Principal Amount',
                          amount: _formatCurrency(_loanAmount),
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildLegend(
                          color: secondaryColor,
                          label: 'Total Interest',
                          amount: _formatCurrency(_totalInterest),
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildLegend(
                          color: theme.colorScheme.onSurface,
                          label: 'Total Payment',
                          amount: _formatCurrency(_totalPayment),
                          theme: theme,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String displayValue,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend({
    required Color color,
    required String label,
    required String amount,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                amount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
