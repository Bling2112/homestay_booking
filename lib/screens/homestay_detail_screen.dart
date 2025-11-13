import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homestay.dart';
import 'package:url_launcher/url_launcher.dart';

class HomestayDetailScreen extends StatelessWidget {
  final Homestay homestay;
  Future<void> _openMap(String address) async {
  final encodedAddress = Uri.encodeComponent(address);
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Không thể mở bản đồ.';
  }
}

  const HomestayDetailScreen({super.key, required this.homestay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(homestay.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(homestay.imageUrl, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(homestay.location,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  Row(
  children: [
    InkWell(
      onTap: () {
        if (homestay.address.isNotEmpty) {
          _openMap(homestay.address);
        }
      },
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
          const SizedBox(width: 4),
          Text(
            homestay.address.isNotEmpty ? homestay.address : 'Chưa có địa chỉ',
            style: const TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
                color: Colors.blueAccent),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  ],
),


                  const SizedBox(height: 12),
                  Text(homestay.description),
                  const SizedBox(height: 12),
                  Text('Giá: ${homestay.price} đ/đêm',
                      style: const TextStyle(color: Colors.teal)),
                  const SizedBox(height: 12),
                  Text('Loại: ${homestay.kind}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: homestay.facilities
                        .map((f) => Chip(label: Text(f)))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

