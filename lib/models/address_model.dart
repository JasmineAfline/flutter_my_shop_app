class AddressModel {
  final String id;
  final String houseNumber;
  final String street;
  final String city;
  final String areaDescription; // e.g., "Near Westlands Stage"

  AddressModel({
    required this.id,
    required this.houseNumber,
    required this.street,
    required this.city,
    required this.areaDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'houseNumber': houseNumber,
      'street': street,
      'city': city,
      'areaDescription': areaDescription,
    };
  }
}