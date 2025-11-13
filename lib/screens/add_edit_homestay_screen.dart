import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homestay.dart';

class AddOrEditHomestayScreen extends StatefulWidget {
  final Homestay? homestay;
  const AddOrEditHomestayScreen({super.key, this.homestay});

  @override
  State<AddOrEditHomestayScreen> createState() => _AddOrEditHomestayScreenState();
}

class _AddOrEditHomestayScreenState extends State<AddOrEditHomestayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    if (widget.homestay != null) {
      _nameController.text = widget.homestay!.name;
      _addressController.text = widget.homestay!.address;
      _priceController.text = widget.homestay!.price.toString();
      _imageUrlController.text = widget.homestay!.imageUrl;
      _rating = widget.homestay!.rating;
    }
  }

  Future<void> saveHomestay() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'imageUrl': _imageUrlController.text.trim(),
      'rating': _rating,
    };

    final collection = FirebaseFirestore.instance.collection('homestays');

    try {
      if (widget.homestay == null) {
        await collection.add(data);
      } else {
        await collection.doc(widget.homestay!.id).update(data);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu homestay thành công!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.homestay == null ? 'Thêm Homestay' : 'Chỉnh sửa Homestay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên homestay'),
                validator: (v) => v!.isEmpty ? 'Nhập tên homestay' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (v) => v!.isEmpty ? 'Nhập địa chỉ' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá / đêm'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Nhập giá' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Đánh giá: '),
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = i;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Lưu'),
                onPressed: saveHomestay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
