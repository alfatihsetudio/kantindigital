class TableModel {
  final int id;
  final String code;
  final String? name;
  final bool isOccupied;

  const TableModel({
    required this.id,
    required this.code,
    this.name,
    this.isOccupied = false,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: (json['id'] as num).toInt(),
      code: (json['code'] ?? '').toString(),
      name: json['name']?.toString(),
      isOccupied: json['is_occupied'] == true || json['is_occupied'] == 1,
    );
  }
}
