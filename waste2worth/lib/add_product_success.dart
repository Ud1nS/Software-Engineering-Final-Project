import 'package:flutter/material.dart';
import 'home_page.dart'; // Import halaman HomePage

class AddProductSuccessPage extends StatelessWidget {
  const AddProductSuccessPage({super.key});

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
            const Text('Produk Berhasil Ditambahkan!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Produk Anda telah ditambahkan ke daftar.',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigasi ke HomePage dan hapus semua rute sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false, // Hapus semua rute sebelumnya
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD3E88D),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child:
                  const Text('Kembali ke Beranda', style: TextStyle(color: Colors.black)), //Label diubah
            )
          ],
        ),
      ),
    );
  }
}
