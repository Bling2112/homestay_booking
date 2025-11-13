class Homestay {
  final String id;
  final String name;
  final String location;
  final String description;
  final List<String> facilities;
  final String imageUrl;
  final int price;
  final int rating;
  final String kind;
  final String address;

  Homestay({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.facilities,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.kind,
    required this.address,
  });

  factory Homestay.fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return Homestay(
        id: id,
        name: '',
        location: '',
        description: '',
        facilities: [],
        imageUrl: '',
        price: 0,
        rating: 0,
        kind: '',
        address: '',
      );
    }

    return Homestay(
      id: id,
      name: data['name']?.toString() ?? '',
      location: data['rental']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      facilities: List<String>.from(data['facilities'] ?? []),
      imageUrl: data['imageUrl']?.toString() ?? '',
      price: (data['price'] is int)
          ? data['price']
          : int.tryParse(data['price']?.toString() ?? '0') ?? 0,
      rating: (data['rating'] is int)
          ? data['rating']
          : int.tryParse(data['rating']?.toString() ?? '0') ?? 0,
      kind: data['kind']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
    );
  }
}
