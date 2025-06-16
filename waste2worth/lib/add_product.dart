import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'add_product_success.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String? _selectedCategory;
  String _productCondition = '';
  String _productLocation = '';
  String _productDescription = '';
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  String? _imageError;
  bool _termsAccepted = false;

  final List<String> _categories = [
    'Pakaian',
    'Elektronik',
    'Perabot',
    'Anak',
    'Buku',
    'Sekolah',
    'Kesehatan',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTermsAccepted());
  }

  Future<void> _checkTermsAccepted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?['termsAccepted'] == true) {
      setState(() {
        _termsAccepted = true;
      });
    } else {
      _showTermsDialog(user.uid);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImagePath = null;
            _imageError = null;
          });
        } else {
          setState(() {
            _selectedImageBytes = null;
            _selectedImagePath = pickedFile.path;
            _imageError = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membaca file gambar')),
          );
        }
        setState(() {
          _imageError = 'Gagal membaca file gambar.';
        });
      }
    } else {
      setState(() {
        _imageError = null;
      });
    }
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: _imageError == null ? Colors.grey : Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _selectedImageBytes != null
              ? Image.memory(
                  _selectedImageBytes!,
                  fit: BoxFit.cover,
                  width: 150,
                  height: 150,
                )
              : _selectedImagePath != null
                  ? Image.file(
                      File(_selectedImagePath!),
                      fit: BoxFit.cover,
                      width: 150,
                      height: 150,
                    )
                  : Center(
                      child: Icon(
                        Icons.upload_file,
                        size: 60,
                        color: _imageError == null ? Colors.grey : Colors.red,
                      ),
                    ),
        ),
      ),
    );
  }

  void _showTermsDialog(String uid) {
    bool isChecked = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Terms and Conditions'),
              content: SizedBox(
                height: 300,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          'Syarat dan Ketentuan Penggunaan Aplikasi:\n\n'
                          'Dengan menggunakan aplikasi ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh syarat dan ketentuan berikut:\n\n'
                          '1. Setiap barang yang didonasikan harus dalam kondisi layak pakai, bersih, dan tidak rusak, sehingga dapat digunakan kembali oleh penerima.\n'
                          '2. Foto yang diunggah wajib merupakan foto asli dari barang yang akan didonasikan, tidak mengandung unsur menyesatkan, dan memperlihatkan kondisi barang secara jelas.\n'
                          '3. Barang-barang yang bersifat ilegal, berbahaya, atau melanggar hukum tidak diperkenankan untuk didonasikan melalui platform ini.\n'
                          '4. Donatur bertanggung jawab penuh atas keakuratan informasi yang diberikan terkait produk, termasuk deskripsi, kondisi, dan lokasi.\n'
                          '5. Jika terdapat laporan bahwa barang tidak sesuai dengan deskripsi atau foto yang diunggah, maka pihak aplikasi berhak melakukan evaluasi dan memberikan sanksi. Sanksi dapat berupa peringatan, pembatasan akses, hingga pemblokiran akun (ban) secara permanen.\n'
                          '6. Pihak aplikasi tidak bertanggung jawab atas segala bentuk penyalahgunaan informasi maupun barang yang diberikan, namun akan berupaya semaksimal mungkin menjaga keamanan dan kenyamanan pengguna.\n\n'
                          'Dengan melanjutkan penggunaan aplikasi, Anda menyetujui untuk menaati ketentuan-ketentuan di atas. Jika Anda tidak setuju dengan salah satu poin, mohon untuk tidak melanjutkan proses donasi.\n\n'
                          'Terima kasih telah berkontribusi dalam gerakan donasi barang bekas yang bermanfaat.',
                          style: const TextStyle(fontSize: 14),
                        ),

                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              isChecked = value ?? false;
                            });
                          },
                        ),
                        const Expanded(child: Text("Saya menyetujui Syarat dan Ketentuan")),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChecked
                      ? () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .set({'termsAccepted': true}, SetOptions(merge: true));
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          setState(() {
                            _termsAccepted = true;
                          });
                        }
                      : null,
                  child: const Text('Setuju'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFD3E88D),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Add Product',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _termsAccepted
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text('Insert product photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Maximum photo size 10mb and only .jpg', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(children: [_buildImage(), const SizedBox(width: 16)]),
                    if (_imageError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_imageError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 24),
                    const Text('Add Product Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Enter the product name'),
                      validator: (value) => (value == null || value.isEmpty) ? '*Required' : null,
                      onChanged: (value) => _productName = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kategori Barang',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) => value == null ? '*Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'How is the product condition?',
                        helperText: 'Tips: Jelaskan kondisi barang dengan jujur',
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? '*Required' : null,
                      onChanged: (value) => _productCondition = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Where is the product located?'),
                      validator: (value) => (value == null || value.isEmpty) ? '*Required' : null,
                      onChanged: (value) => _productLocation = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Enter the product description',
                        alignLabelWithHint: true,
                      ),
                      maxLength: 500,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      validator: (value) => (value == null || value.isEmpty) ? '*Required' : null,
                      onChanged: (value) => setState(() => _productDescription = value),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedImageBytes != null || _selectedImagePath != null) {
                              setState(() {
                                _imageError = null;
                              });

                              Uint8List imageBytes;
                              if (_selectedImageBytes != null) {
                                imageBytes = _selectedImageBytes!;
                              } else {
                                imageBytes = await File(_selectedImagePath!).readAsBytes();
                              }
                              String base64Image = base64Encode(imageBytes);

                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              Map<String, dynamic> productData = {
                                'name': _productName,
                                'category': _selectedCategory,
                                'condition': _productCondition,
                                'location': _productLocation,
                                'description': _productDescription,
                                'image_base64': base64Image,
                                'timestamp': FieldValue.serverTimestamp(),
                                'userId': user.uid,
                              };

                              try {
                                await FirebaseFirestore.instance.collection('products').add(productData);
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddProductSuccessPage()),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menyimpan data ke Firestore: $e'), backgroundColor: Colors.red),
                                );
                              }
                            } else {
                              setState(() {
                                _imageError = 'Please upload a product image.';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please upload a product image.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD3E88D), 
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                          child: Text('Submit', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
