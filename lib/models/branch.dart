class Branch {
  final int id;
  final String name;
  final String? address;
  final String? phone;

  Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    phone: json['phone'],
  );
}