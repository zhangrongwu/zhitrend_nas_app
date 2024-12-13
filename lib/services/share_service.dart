import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import '../models/file_item.dart';

class ShareService {
  final String baseUrl;
  late final Dio _dio;

  ShareService({required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<String> createShareLink({
    required String path,
    int? expirationDays,
    bool? requirePassword,
    String? password,
    bool? allowDownload,
  }) async {
    try {
      final response = await _dio.post('/api/share', data: {
        'path': path,
        if (expirationDays != null) 'expiration_days': expirationDays,
        if (requirePassword != null) 'require_password': requirePassword,
        if (password != null) 'password': password,
        if (allowDownload != null) 'allow_download': allowDownload,
      });

      if (response.statusCode == 200) {
        return response.data['share_link'];
      }
      throw Exception('Failed to create share link');
    } catch (e) {
      throw Exception('Failed to create share link: $e');
    }
  }

  Future<List<ShareInfo>> getSharedFiles() async {
    try {
      final response = await _dio.get('/api/share/list');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['shares'];
        return data.map((item) => ShareInfo.fromJson(item)).toList();
      }
      throw Exception('Failed to get shared files');
    } catch (e) {
      throw Exception('Failed to get shared files: $e');
    }
  }

  Future<void> removeShare(String shareId) async {
    try {
      await _dio.delete('/api/share/$shareId');
    } catch (e) {
      throw Exception('Failed to remove share: $e');
    }
  }

  Future<void> updateShare({
    required String shareId,
    int? expirationDays,
    bool? requirePassword,
    String? password,
    bool? allowDownload,
  }) async {
    try {
      await _dio.put('/api/share/$shareId', data: {
        if (expirationDays != null) 'expiration_days': expirationDays,
        if (requirePassword != null) 'require_password': requirePassword,
        if (password != null) 'password': password,
        if (allowDownload != null) 'allow_download': allowDownload,
      });
    } catch (e) {
      throw Exception('Failed to update share: $e');
    }
  }

  Future<void> shareViaSystem(FileItem file) async {
    try {
      final shareLink = await createShareLink(path: file.path);
      await Share.share(
        'Check out this file from my NAS: $shareLink',
        subject: 'Shared file: ${file.name}',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }
}

class ShareInfo {
  final String id;
  final String path;
  final String shareLink;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool requirePassword;
  final bool allowDownload;
  final int accessCount;

  ShareInfo({
    required this.id,
    required this.path,
    required this.shareLink,
    required this.createdAt,
    this.expiresAt,
    required this.requirePassword,
    required this.allowDownload,
    required this.accessCount,
  });

  factory ShareInfo.fromJson(Map<String, dynamic> json) {
    return ShareInfo(
      id: json['id'],
      path: json['path'],
      shareLink: json['share_link'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      requirePassword: json['require_password'],
      allowDownload: json['allow_download'],
      accessCount: json['access_count'],
    );
  }
}
