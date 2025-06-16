import 'package:flutter/material.dart';
import 'login_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _introData = [
    {
      'image': 'assets/images/intro1.png',
      'title': 'Selamat Datang di Waste2Worth',
      'desc': 'Ubah barang tak terpakai menjadi berkah untuk orang lain!',
    },

    {
      'image': 'assets/images/intro2.png',
      'title': 'Donasikan Barangmu',
      'desc': 'Bantu sesama tanpa harus meninggalkan rumah.',
    },

    {
      'image': 'assets/images/intro3.png',
      'title': 'Berbagi Lebih Mudah',
      'desc': 'Bantu sesama dengan sekali klik. Yuk mulai sekarang!',
    },
  ];

  void _nextPage() {
    if (_currentIndex < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBE7),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _introData.length,
              itemBuilder: (context, index) {
                final item = _introData[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(item['image']!, height: 250),
                      const SizedBox(height: 30),
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        item['desc']!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _introData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 10,
                width: _currentIndex == index ? 20 : 10,
                decoration: BoxDecoration(
                  color:
                      _currentIndex == index
                          ? const Color(0xFFC6D266)
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC6D266),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_currentIndex == 2 ? 'Mulai Sekarang' : 'Lanjut'),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
