import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storeNameController = TextEditingController();
  final _shippingFeeController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('store').get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _storeNameController.text = data['storeName'] ?? '';
        _shippingFeeController.text = (data['shippingFee'] ?? 200).toString();
        _taxRateController.text = (data['taxRate'] ?? 0.16).toString();
        _logoUrlController.text = data['logoUrl'] ?? '';
        _bannerUrlController.text = data['bannerUrl'] ?? '';
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance.collection('settings').doc('store').set({
        'storeName': _storeNameController.text,
        'shippingFee': double.parse(_shippingFeeController.text),
        'taxRate': double.parse(_taxRateController.text),
        'logoUrl': _logoUrlController.text,
        'bannerUrl': _bannerUrlController.text,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _shippingFeeController.dispose();
    _taxRateController.dispose();
    _logoUrlController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Information Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _storeNameController,
                  decoration: InputDecoration(
                    labelText: 'Store Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _logoUrlController,
                  decoration: InputDecoration(
                    labelText: 'Store Logo URL',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                if (_logoUrlController.text.isNotEmpty)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_logoUrlController.text, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image))),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Pricing Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pricing & Fees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _shippingFeeController,
                        decoration: InputDecoration(
                          labelText: 'Shipping Fee (KSH)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _taxRateController,
                        decoration: InputDecoration(
                          labelText: 'Tax Rate (%)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Homepage Banner Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Homepage Banner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _bannerUrlController,
                  decoration: InputDecoration(
                    labelText: 'Banner Image URL',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                if (_bannerUrlController.text.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_bannerUrlController.text, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image))),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Save Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
