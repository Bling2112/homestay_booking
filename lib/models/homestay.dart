class Homestay {
  final String id;
  final String name;
  final String location;
  final String description;
  final List<String> facilities;
  final List<String> imageUrls;
  final int price;
  final int rating;
  final String kind;
  final String address;
  final int maxGuests;
  final int extraGuestFee;

  Homestay({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.facilities,
    required this.imageUrls,
    required this.price,
    required this.rating,
    required this.kind,
    required this.address,
    required this.maxGuests,
    required this.extraGuestFee,

  });

  // Getter for backward compatibility
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory Homestay.fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return Homestay(
        id: id,
        name: '',
        location: '',
        description: '',
        facilities: [],
        imageUrls: [],
        price: 0,
        rating: 0,
        kind: '',
        address: '',
        maxGuests: 2,
        extraGuestFee: 100000,

      );
    }

    return Homestay(
      id: id,
      name: data['name']?.toString() ?? '',
      location: data['rental']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      facilities: List<String>.from(data['facilities'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? [data['imageUrl']?.toString() ?? '']),
      price: (data['price'] is int)
          ? data['price']
          : int.tryParse(data['price']?.toString() ?? '0') ?? 0,
      rating: (data['rating'] is int)
          ? data['rating']
          : int.tryParse(data['rating']?.toString() ?? '0') ?? 0,
      kind: data['kind']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      maxGuests: (data['maxGuests'] is int)
          ? data['maxGuests']
          : int.tryParse(data['maxGuests']?.toString() ?? '2') ?? 2,
      extraGuestFee: (data['extraGuestFee'] is int)
          ? data['extraGuestFee']
          : int.tryParse(data['extraGuestFee']?.toString() ?? '100000') ?? 100000,

    );
  }
}
