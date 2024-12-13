import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/file_item.dart';

class ApiService {
  final String baseUrl;
  final Dio _dio;

  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  String getPreviewUrl(String path) {
    return '$baseUrl/api/preview?path=$path';
  }

  Future<List<FileItem>> listFiles(String path) async {
    try {
      final response = await _dio.get('/api/files', queryParameters: {
        'path': path,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['files'];
        return data.map((item) => FileItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to list files');
      }
    } catch (e) {
      debugPrint('Error listing files: $e');
      rethrow;
    }
  }

  Future<FileItem?> getFileInfo(String path) async {
    try {
      final response = await _dio.get('/api/file', queryParameters: {
        'path': path,
      });

      if (response.statusCode == 200) {
        return FileItem.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting file info: $e');
      return null;
    }
  }

  Future<void> downloadFile(
    String path,
    String savePath, {
    Function(double)? onProgress,
    Function()? onComplete,
    Function(dynamic)? onError,
  }) async {
    try {
      await _dio.download(
        '/api/download',
        savePath,
        queryParameters: {'path': path},
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
          }
        },
      );
      onComplete?.call();
    } catch (e) {
      debugPrint('Error downloading file: $e');
      onError?.call(e);
      rethrow;
    }
  }

  Future<void> uploadFile(String directory, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'directory': directory,
      });

      await _dio.post(
        '/api/upload',
        data: formData,
      );
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> createDirectory(String path, String name) async {
    try {
      await _dio.post('/api/directory', data: {
        'path': path,
        'name': name,
      });
    } catch (e) {
      debugPrint('Error creating directory: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String path) async {
    try {
      await _dio.delete('/api/file', queryParameters: {
        'path': path,
      });
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  Future<void> moveItem(String sourcePath, String targetPath) async {
    try {
      await _dio.post('/api/move', data: {
        'source': sourcePath,
        'target': targetPath,
      });
    } catch (e) {
      debugPrint('Error moving item: $e');
      rethrow;
    }
  }

  Future<void> copyItem(String sourcePath, String targetPath) async {
    try {
      await _dio.post('/api/copy', data: {
        'source': sourcePath,
        'target': targetPath,
      });
    } catch (e) {
      debugPrint('Error copying item: $e');
      rethrow;
    }
  }

  Future<String> generateShareLink(String path, {
    DateTime? expiration,
    String? password,
    bool allowDownload = true,
  }) async {
    try {
      final response = await _dio.post('/api/share', data: {
        'path': path,
        'expiration': expiration?.toIso8601String(),
        'password': password,
        'allow_download': allowDownload,
      });

      if (response.statusCode == 200) {
        return response.data['link'];
      } else {
        throw Exception('Failed to generate share link');
      }
    } catch (e) {
      debugPrint('Error generating share link: $e');
      rethrow;
    }
  }
}
