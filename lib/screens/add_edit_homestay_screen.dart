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
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final _kindController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _extraGuestFeeController = TextEditingController();
  final List<TextEditingController> _imageUrlControllers = [];
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    if (widget.homestay != null) {
      _nameController.text = widget.homestay!.name;
      _addressController.text = widget.homestay!.address;
      _priceController.text = widget.homestay!.price.toString();
      _locationController.text = widget.homestay!.location;
      _descriptionController.text = widget.homestay!.description;
      _facilitiesController.text = widget.homestay!.facilities.join(', ');
      _kindController.text = widget.homestay!.kind;
      _maxGuestsController.text = widget.homestay!.maxGuests.toString();
      _extraGuestFeeController.text = widget.homestay!.extraGuestFee.toString();
      _rating = widget.homestay!.rating;

      // Initialize image URL controllers
      _imageUrlControllers.clear();
      for (String url in widget.homestay!.imageUrls) {
        if (url.isNotEmpty) {
          _imageUrlControllers.add(TextEditingController(text: url));
        }
      }
      // Add at least one empty controller if no images
      if (_imageUrlControllers.isEmpty) {
        _imageUrlControllers.add(TextEditingController());
      }
    } else {
      // For new homestay, add one empty image URL controller
      _imageUrlControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _facilitiesController.dispose();
    _kindController.dispose();
    _maxGuestsController.dispose();
    _extraGuestFeeController.dispose();
    for (var controller in _imageUrlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addImageUrlField() {
    setState(() {
      _imageUrlControllers.add(TextEditingController());
    });
  }

  void _removeImageUrlField(int index) {
    if (_imageUrlControllers.length > 1) {
      setState(() {
        _imageUrlControllers[index].dispose();
        _imageUrlControllers.removeAt(index);
      });
    }
  }

  Future<void> saveHomestay() async {
    if (!_formKey.currentState!.validate()) return;

    // Collect image URLs from controllers
    final imageUrls = _imageUrlControllers
        .map((controller) => controller.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    final data = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'facilities': _facilitiesController.text.trim().isEmpty
          ? []
          : _facilitiesController.text.trim().split(',').map((s) => s.trim()).toList(),
      'imageUrls': imageUrls,
      'price': int.tryParse(_priceController.text.trim()) ?? 0,
      'rating': _rating,
      'kind': _kindController.text.trim(),
      'maxGuests': int.tryParse(_maxGuestsController.text.trim()) ?? 2,
      'extraGuestFee': int.tryParse(_extraGuestFeeController.text.trim()) ?? 100000,
      // Keep imageUrl for backward compatibility
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
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
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Vị trí'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _facilitiesController,
                decoration: const InputDecoration(labelText: 'Tiện ích (cách nhau bằng dấu phẩy)'),
              ),
              TextFormField(
                controller: _kindController,
                decoration: const InputDecoration(labelText: 'Loại homestay'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá / đêm'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Nhập giá' : null,
              ),
              TextFormField(
                controller: _maxGuestsController,
                decoration: const InputDecoration(labelText: 'Số khách tối đa'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _extraGuestFeeController,
                decoration: const InputDecoration(labelText: 'Phí khách thêm'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('URL hình ảnh:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._imageUrlControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'URL hình ảnh ${index + 1}',
                          hintText: 'https://example.com/image.jpg',
                        ),
                      ),
                    ),
                    if (_imageUrlControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeImageUrlField(index),
                      ),
                  ],
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm URL hình ảnh'),
                onPressed: _addImageUrlField,
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
