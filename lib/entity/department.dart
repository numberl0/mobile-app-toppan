class Department {
  final String value;
  final String label;

  Department({
    required this.value,
    required this.label,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}