import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'add_product.dart';
import 'profile_page.dart';
import 'product_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _userName;

  final List<Widget> _pages = [
    const HomeContent(),
    const ProductPage(),
    SizedBox(), // Placeholder for Add
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Guest';
        });
      } else {
        setState(() {
          _userName = 'Guest';
        });
      }
    } else {
      setState(() {
        _userName = 'Guest';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddProductPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: _selectedIndex == 0
          ? HomeContent(userName: _userName)
          : _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFC6D266),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.add), label: 'Checkout'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String? userName;

  const HomeContent({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFD3E88D),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Waste2Worth",
                    style: GoogleFonts.rubikBubbles(
                      fontSize: 40,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      aspectRatio: 18 / 9,
                      autoPlayInterval: const Duration(seconds: 3),
                      viewportFraction: 0.8,
                    ),
                    items: [
                      'assets/images/image-5.jpg',
                      'assets/images/image-2.jpg',
                      'assets/images/image-3.jpg',
                      'assets/images/image-4.jpg',
                    ].map((imagePath) {
                      return Builder(
                        builder: (BuildContext context) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logo + Nama + Poin
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nama di kiri
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3E88D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Hi, ${userName ?? "..."}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),

                // Logo di tengah
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 73,
                    height: 73,
                    child: Image.asset(
                      'assets/images/logokecil.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Poin di kanan
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3E88D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '800pts',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),




          const SizedBox(height: 20),

          // Bagian Button-button (Donate Item dll)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Column(
                      children: [
                        Icon(Icons.volunteer_activism, size: 30),
                        SizedBox(height: 8),
                        Text("Donate Item"),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.shopping_cart, size: 30),
                        SizedBox(height: 8),
                        Text("Add Item"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Column(
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(height: 8),
                        Text("Button 1"),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(height: 8),
                        Text("Button 2"),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(height: 8),
                        Text("Button 3"),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(height: 8),
                        Text("Button 4"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Welcome dan Learn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/welcome.jpg'),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/learn.jpg'),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
