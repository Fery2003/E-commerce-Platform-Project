// models/category_model.dart
class CategoryModel {
  String id;
  String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CategoryModel(
      id: documentId,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
