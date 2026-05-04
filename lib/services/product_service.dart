import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product.dart';

class ProductService {
  // Lấy tất cả sản phẩm
  Future<List<Product>> getProducts() async {
    try {
      final response = await ApiClient.dio.get(AppConstants.products);
      return (response.data as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách sản phẩm');
    }
  }

  // Tìm sản phẩm theo tên
  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await ApiClient.dio.get(
        AppConstants.products,
        queryParameters: {'search': keyword},
      );
      return (response.data as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Không thể tìm kiếm sản phẩm');
    }
  }

  // Tìm theo barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final response = await ApiClient.dio.get(
        '${AppConstants.products}/barcode/$barcode',
      );
      return Product.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // Thêm sản phẩm mới
  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.post(AppConstants.products, data: data);
      return true;
    } catch (e) {
      throw Exception('Không thể thêm sản phẩm');
    }
  }

  // Cập nhật sản phẩm
  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.put('${AppConstants.products}/$id', data: data);
      return true;
    } catch (e) {
      throw Exception('Không thể cập nhật sản phẩm');
    }
  }

  // Xóa sản phẩm
  Future<bool> deleteProduct(int id) async {
    try {
      await ApiClient.dio.delete('${AppConstants.products}/$id');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa sản phẩm');
    }
  }
}