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

  Future<void> uploadFile(String path, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        'path': path,
      });

      final response = await _dio.post('/api/upload', data: formData);

      if (response.statusCode != 200) {
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final response = await _dio.delete('/api/files', queryParameters: {
        'path': path,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to delete file');
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
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

  // 创建分享链接
  Future<Map<String, dynamic>> createShareLink(String path, {int? expiresInHours}) async {
    try {
      final response = await _dio.post('/api/files/share', queryParameters: {
        'path': path,
        if (expiresInHours != null) 'expires_in_hours': expiresInHours,
      });

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create share link');
      }
    } catch (e) {
      debugPrint('Error creating share link: $e');
      rethrow;
    }
  }

  // 压缩文件
  Future<String> compressFiles(List<String> paths, String archiveName) async {
    try {
      final response = await _dio.post('/api/files/compress', data: {
        'paths': paths,
        'archive_name': archiveName,
      });

      if (response.statusCode == 200) {
        return response.data['archive_path'];
      } else {
        throw Exception('Failed to compress files');
      }
    } catch (e) {
      debugPrint('Error compressing files: $e');
      rethrow;
    }
  }

  // 解压文件
  Future<String> extractArchive(String path, {String? extractPath}) async {
    try {
      final response = await _dio.post('/api/files/extract', data: {
        'path': path,
        if (extractPath != null) 'extract_path': extractPath,
      });

      if (response.statusCode == 200) {
        return response.data['extract_path'];
      } else {
        throw Exception('Failed to extract archive');
      }
    } catch (e) {
      debugPrint('Error extracting archive: $e');
      rethrow;
    }
  }

  // 批量操作文件
  Future<List<Map<String, dynamic>>> batchOperation(String operation, List<String> files) async {
    try {
      final response = await _dio.post('/api/files/batch', data: {
        'operation': operation,
        'files': files,
      });

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['results']);
      } else {
        throw Exception('Failed to perform batch operation');
      }
    } catch (e) {
      debugPrint('Error performing batch operation: $e');
      rethrow;
    }
  }
}
