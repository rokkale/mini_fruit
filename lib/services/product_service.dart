import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product.dart';

class ProductService {
  // Lấy tất cả sản phẩm
  Future<List<Product>> getProducts() async {
    try {
      final response = await ApiClient.dio.get(AppConstants.products);
      return (response.data as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách sản phẩm');
    }
  }

  // Tìm sản phẩm theo tên/SKU/barcode — backend không có search param, lọc client-side
  Future<List<Product>> searchProducts(String keyword) async {
    final products = await getProducts();
    final lower = keyword.toLowerCase().trim();
    if (lower.isEmpty) return products;
    return products.where((p) {
      return p.productName.toLowerCase().contains(lower) ||
          (p.sku?.toLowerCase().contains(lower) ?? false) ||
          (p.barcode?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  // Tìm theo barcode — backend không có endpoint barcode, lọc client-side
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final products = await getProducts();
      return products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => throw Exception('Không tìm thấy'),
      );
    } catch (_) {
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
