import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _bhkCtrl = TextEditingController();
  final _builtUpAreaCtrl = TextEditingController();

  String _listingType = 'RESIDENTIAL';
  String _propertyType = 'SALE'; // Transaction type
  bool _isUnderConstruction = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _localityCtrl.dispose();
    _bhkCtrl.dispose();
    _builtUpAreaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final repo = ref.read(listingRepositoryProvider);
      await repo.createListing({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'listingType': _listingType,
        'type': _propertyType,
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'city': _cityCtrl.text.trim(),
        'locality': _localityCtrl.text.trim(),
        if (_listingType == 'RESIDENTIAL')
          'bhk': int.tryParse(_bhkCtrl.text.trim()),
        if (_builtUpAreaCtrl.text.trim().isNotEmpty)
          'builtUpArea': int.tryParse(_builtUpAreaCtrl.text.trim()),
        'isUnderConstruction': _isUnderConstruction,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!')),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to create listing')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Listing')),
      body: _submitting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _propertyType,
                      decoration: const InputDecoration(labelText: 'Transaction Type'),
                      items: const [
                        DropdownMenuItem(value: 'SALE', child: Text('Sell')),
                        DropdownMenuItem(value: 'RENT', child: Text('Rent Out')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _propertyType = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _listingType,
                      decoration: const InputDecoration(labelText: 'Listing Category'),
                      items: const [
                        DropdownMenuItem(value: 'RESIDENTIAL', child: Text('Residential')),
                        DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial')),
                        DropdownMenuItem(value: 'PG', child: Text('PG / Co-living')),
                        DropdownMenuItem(value: 'PLOT', child: Text('Plot')),
                        DropdownMenuItem(value: 'LAND', child: Text('Land')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _listingType = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Must be a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_listingType == 'RESIDENTIAL') ...[
                      TextFormField(
                        controller: _bhkCtrl,
                        decoration: const InputDecoration(labelText: 'BHK Count'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'BHK is required for Residential';
                          if (int.tryParse(v) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _builtUpAreaCtrl,
                      decoration: const InputDecoration(labelText: 'Built-up Area (sqft) (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _localityCtrl,
                      decoration: const InputDecoration(labelText: 'Locality'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Under Construction'),
                      value: _isUnderConstruction,
                      onChanged: (v) => setState(() => _isUnderConstruction = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Submit Listing', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
