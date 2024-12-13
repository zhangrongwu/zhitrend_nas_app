import 'package:dio/dio.dart';
import '../models/file_item.dart';

class SearchService {
  final String baseUrl;
  late final Dio _dio;

  SearchService({required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<List<FileItem>> searchFiles({
    required String query,
    String? path,
    List<String>? fileTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? minSize,
    int? maxSize,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'query': query,
        if (path != null) 'path': path,
        if (fileTypes != null) 'file_types': fileTypes.join(','),
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (minSize != null) 'min_size': minSize,
        if (maxSize != null) 'max_size': maxSize,
      };

      final response = await _dio.get('/api/search', queryParameters: params);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['files'];
        return data.map((item) => FileItem.fromJson(item)).toList();
      }
      throw Exception('Search failed');
    } catch (e) {
      throw Exception('Failed to search files: $e');
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    try {
      final response = await _dio.get('/api/search/suggestions', 
        queryParameters: {'query': query});
      
      if (response.statusCode == 200) {
        return List<String>.from(response.data['suggestions']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
