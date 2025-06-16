import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetailProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailProductPage({super.key, required this.product});

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  String selectedDelivery = 'Reguler';
  String selectedArea = 'Jabodetabek';

  final List<String> deliveryOptions = ['Instant', 'Reguler', 'Kargo'];
  final List<String> areaOptions = ['Jabodetabek', 'Jawa', 'Luar Jawa'];

  bool isLoading = true;
  int todayCheckoutCount = 0;

  double get shippingCost {
    double baseCost = switch (selectedDelivery) {
      'Instant' => 30000,
      'Kargo' => 15000,
      _ => 10000
    };

    double multiplier = switch (selectedArea) {
      'Jawa' => 1.5,
      'Luar Jawa' => 2.0,
      _ => 1.0
    };

    return baseCost * multiplier;
  }

  bool get isDeliveryValid {
    return !(selectedDelivery == 'Instant' && selectedArea != 'Jabodetabek');
  }

  bool get isCheckoutEnabled {
    return isDeliveryValid && todayCheckoutCount < 2;
  }

  @override
  void initState() {
    super.initState();
    _loadTodayCheckouts();
  }

  Future<void> _loadTodayCheckouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 7));

    final snapshot = await FirebaseFirestore.instance
        .collection('checkouts')
        .doc(user.uid)
        .collection('records')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    setState(() {
      todayCheckoutCount = snapshot.docs.length;
      isLoading = false;
    });
  }

  Future<void> _checkoutProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final productId = widget.product['id'];

    try {
      // Tambahkan record checkout
      await FirebaseFirestore.instance
          .collection('checkouts')
          .doc(user.uid)
          .collection('records')
          .add({
        'productId': productId,
        'timestamp': Timestamp.now(),
        'delivery': selectedDelivery,
        'area': selectedArea,
        'shippingCost': shippingCost,
      });

      // Hapus produk dari koleksi 'products'
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentSuccessPage()),
        );
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal checkout. Silakan coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final String base64Image = product['image']!;
    final cleanBase64 = base64Image.contains(',') ? base64Image.split(',')[1] : base64Image;
    final Uint8List imageBytes = base64Decode(cleanBase64);

    final title = product['title']!;
    final condition = product['condition']!;
    final location = product['location']!;
    final description = product['description'] ?? 'Deskripsi belum tersedia.';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black), // teks judul hitam
        ),
        iconTheme: const IconThemeData(color: Colors.black), // ikon back hitam
        backgroundColor: const Color(0xFFD3E88D),
        foregroundColor: Colors.black, // berlaku untuk teks & ikon juga
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isCheckoutEnabled ? Color(0xFFD3E88D) : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (isLoading) return;

            if (!isCheckoutEnabled) {
              if (!isDeliveryValid) return;

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Batas Checkout Tercapai'),
                  content: const Text('Anda hanya dapat checkout maksimal 2 produk per hari. Silakan coba lagi besok.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              _checkoutProduct();
            }
          },
          child: Text(
            isLoading
                ? 'Memuat...'
                : todayCheckoutCount >= 2
                ? 'Batas Checkout Tercapai'
                : 'Checkout',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageBytes, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Kondisi: $condition'),
            Text('Lokasi: $location'),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(description)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: selectedDelivery,
              decoration: InputDecoration(
                labelText: 'Pilih Pengiriman',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: deliveryOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
              onChanged: (value) => setState(() => selectedDelivery = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedArea,
              decoration: InputDecoration(
                labelText: 'Pilih Area Pengantaran',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: areaOptions.map((area) => DropdownMenuItem(value: area, child: Text(area))).toList(),
              onChanged: (value) => setState(() => selectedArea = value!),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ongkos Kirim: Rp ${shippingCost.toInt()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (!isDeliveryValid)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pengiriman Instant hanya tersedia untuk Jabodetabek.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Color(0xFFD3E88D)),
            const SizedBox(height: 20),
            const Text('Pembayaran Diterima!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Checkout berhasil.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD3E88D),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Kembali ke Produk', style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }
}
