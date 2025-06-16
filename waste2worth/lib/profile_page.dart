import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<ProfilePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String name = "Nama nama nama";
  String email = "example@gmail.com";
  String phoneNumber = "08121231231";

  String? selectedAddress = "Bandung, Indonesia";
  String? selectedPayment = "OVO";
  String? selectedSecurity = "PIN";

  bool hasFabChanges = false;

  final addressController = TextEditingController();
  final securityController = TextEditingController();
  final phoneController = TextEditingController();

  List<String> uploads = [];

  final List<String> paymentMethods = ["OVO", "Gopay", "Dana", "Bank Transfer"];

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadUserProducts();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? name;
          email = data['email'] ?? email;
          phoneNumber = data['phone'] ?? phoneNumber;
          selectedAddress = data['address'] ?? selectedAddress;
          selectedPayment = data['paymentMethod'] ?? selectedPayment;
          selectedSecurity = data['security'] ?? selectedSecurity;
          addressController.text = selectedAddress!;
          securityController.text = selectedSecurity!;
          phoneController.text = phoneNumber;
        });
      }
    }
  }

  Future<void> loadUserProducts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: uid)
          .get();

      setState(() {
        uploads = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    }
  }

  void _checkFabChanges() {
    setState(() {
      hasFabChanges =
          selectedAddress != addressController.text ||
              selectedPayment != "OVO" ||
              selectedSecurity != securityController.text;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _openEditProfile() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    bool hasChanges = false;

    void checkChanges() {
      setState(() {
        hasChanges =
            nameController.text != name || emailController.text != email || phoneController.text != phoneNumber;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: StatefulBuilder(
          builder: (context, modalSetState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const Text("Edit Profile",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage(
                          'assets/images/default_profile.jpg')
                      as ImageProvider,
                      child: _imageFile == null
                          ? const Icon(Icons.camera_alt,
                          size: 30, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    onChanged: (_) => modalSetState(checkChanges),
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    onChanged: (_) => modalSetState(checkChanges),
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    onChanged: (_) => modalSetState(checkChanges),
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: hasChanges
                        ? () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'name': nameController.text,
                          'email': emailController.text,
                          'phone': phoneController.text,
                        });
                      }
                      setState(() {
                        name = nameController.text;
                        email = emailController.text;
                        phoneNumber = phoneController.text;
                      });

                      Navigator.pop(context);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: value,
          onChanged: (val) {
            onChanged(val);
            _checkFabChanges();
          },
          items: items
              .map((item) =>
              DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          decoration: InputDecoration(
            labelText: label,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPreviousOrdersSection() {
    if (uploads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            "Kamu belum mengupload barang apapun.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final lastTwoUploads = uploads.length >= 2
        ? uploads.sublist(uploads.length - 2)
        : uploads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Barang yang Kamu Upload",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lastTwoUploads.length,
            itemBuilder: (context, index) {
              final item = lastTwoUploads[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 6,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFFD3E88D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              size: 48, color: Colors.deepPurple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final updatedList = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PreviousOrdersPage(uploads: uploads)),
              );
              if (updatedList != null) {
                setState(() {
                  uploads = List<String>.from(updatedList);
                });
              }
            },
            child: const Text(
              "See More",
              style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFD3E88D),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : const AssetImage(
                            'assets/images/default_profile.jpg')
                        as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(email, style: const TextStyle(fontSize: 16)),
                          Text(phoneNumber,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _openEditProfile,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPreviousOrdersSection(),
                  TextField(
                    controller: addressController,
                    onChanged: (_) => _checkFabChanges(),
                    decoration: const InputDecoration(
                      labelText: "Shipping Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown("Payment Methods", selectedPayment,
                      paymentMethods, (val) {
                        setState(() => selectedPayment = val);
                      }),
                  TextField(
                    controller: securityController,
                    onChanged: (_) => _checkFabChanges(),
                    decoration: const InputDecoration(
                      labelText: "Security",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasFabChanges
            ? () async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'address': addressController.text,
              'security': securityController.text,
              'paymentMethod': selectedPayment,
            });
          }
          setState(() {
            selectedAddress = addressController.text;
            selectedSecurity = securityController.text;
            hasFabChanges = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Changes saved!")),
          );
        }
            : null,
        backgroundColor: hasFabChanges ? Color(0xFFD3E88D) : Colors.grey,
        icon: const Icon(Icons.save),
        label: const Text("Save"),
      ),
    );
  }
}

class PreviousOrdersPage extends StatefulWidget {
  final List<String> uploads;
  const PreviousOrdersPage({super.key, required this.uploads});

  @override
  State<PreviousOrdersPage> createState() => _PreviousOrdersPageState();
}

class _PreviousOrdersPageState extends State<PreviousOrdersPage> {
  late List<String> uploads;

  @override
  void initState() {
    super.initState();
    uploads = List.from(widget.uploads);
  }

  Future<void> _removeItem(int index) async {
    final nameToDelete = uploads[index];
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: uid)
          .where('name', isEqualTo: nameToDelete)
          .get();

      for (var doc in query.docs) {
        await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
      }
    }

    setState(() {
      uploads.removeAt(index);
    });
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah kamu yakin ingin menghapus item ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeItem(index);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang yang Kamu Upload'),
        backgroundColor: Color(0xFFD3E88D),
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, uploads);
          },
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: uploads.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.shopping_bag_outlined,
                color: Colors.deepPurple),
            title: Text(uploads[index],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(index),
            ),
          );
        },
      ),
    );
  }
}