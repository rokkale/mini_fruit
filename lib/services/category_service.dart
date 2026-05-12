import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/category.dart';

class CategoryService {
  Future<List<Category>> getCategories() async {
    try {
      final response = await ApiClient.dio.get(AppConstants.categories);
      return (response.data as List)
          .map((e) => Category.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh mục sản phẩm');
    }
  }
}
