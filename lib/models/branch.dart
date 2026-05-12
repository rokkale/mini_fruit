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
    id: json['branchId'] ?? json['id'],
    name: json['branchName'] ?? json['name'],
    address: json['address'],
    phone: json['phone'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null && address!.isNotEmpty) 'address': address,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
  };
}