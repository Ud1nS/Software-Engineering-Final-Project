import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_product_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int selectedCategoryIndex = 0;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.checkroom, 'label': 'Pakaian'},
    {'icon': Icons.electrical_services, 'label': 'Elektronik'},
    {'icon': Icons.chair, 'label': 'Perabot'},
    {'icon': Icons.child_care, 'label': 'Anak'},
    {'icon': Icons.menu_book, 'label': 'Buku'},
    {'icon': Icons.school, 'label': 'Sekolah'},
    {'icon': Icons.medical_services, 'label': 'Kesehatan'},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories[selectedCategoryIndex]['label'];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Produk Katalog', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.grey[200],
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              color: Colors.grey[200],
              height: 70,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: List.generate(
                    categories.length,
                        (index) => _buildCategoryItem(
                      index,
                      categories[index]['icon'],
                      categories[index]['label'],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama atau lokasi...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allProducts = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'title': data['name'] ?? '',
                        'condition': data['condition'] ?? '',
                        'location': data['location'] ?? '',
                        'description': data['description'] ?? '',
                        'category': data['category'] ?? '',
                        'image': data['image_base64'] ?? '',
                      };
                    }).toList();

                    final filteredProducts = allProducts.where((product) {
                      final matchesCategory = product['category'] == selectedCategory;
                      final matchesSearch = searchQuery.isEmpty ||
                          (product['title'].toLowerCase().contains(searchQuery) ||
                              product['location'].toLowerCase().contains(searchQuery));
                      return matchesCategory && matchesSearch;
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return const Center(child: Text('Produk tidak ditemukan'));
                    }

                    return GridView.builder(
                      itemCount: filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        final originalDoc = snapshot.data!.docs.firstWhere((doc) =>
                        (doc.data() as Map<String, dynamic>)['name'] == filteredProducts[index]['title'] &&
                            (doc.data() as Map<String, dynamic>)['location'] == filteredProducts[index]['location']); // ini buat cari dokumennya

                        final product = {
                          ...filteredProducts[index],
                          'id': originalDoc.id, // << tambahin id dokumen Firestore
                        };

                        final imageString = product['image'] as String;

                        Widget imageWidget;
                        if (imageString.startsWith('http')) {
                          imageWidget = Image.network(
                            imageString,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        } else if (imageString.isNotEmpty) {
                          try {
                            final cleanedBase64 = imageString.contains(',')
                                ? imageString.split(',').last
                                : imageString;
                            Uint8List bytes = base64Decode(cleanedBase64);
                            imageWidget = Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 140,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            );
                          } catch (e) {
                            imageWidget = const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                          }
                        } else {
                          imageWidget = const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailProductPage(product: product),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[100],
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: 100,
                                      width: double.infinity,
                                      child: imageWidget,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product['title'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Kondisi: ${product['condition']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        product['location'],
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(int index, IconData icon, String label) {
    final isSelected = index == selectedCategoryIndex;
    final color = isSelected ? Colors.black : Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryIndex = index;
          searchQuery = '';
          searchController.clear();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
