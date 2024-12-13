import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/file_item.dart';
import 'api_service.dart';

class DownloadService {
  final ApiService _apiService;
  final _downloadControllers = <String, StreamController<double>>{};
  final _downloadPaths = <String, String>{};
  static FlutterLocalNotificationsPlugin? _notifications;

  DownloadService(this._apiService);

  static Future<void> initialize() async {
    _notifications = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications!.initialize(initializationSettings);
  }

  static void registerCallback() {
    // 可以在这里注册下载完成的回调
  }

  Future<String?> downloadFile(FileItem file) async {
    try {
      // 检查存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }

      // 创建下载目录
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 生成本地文件路径
      final localPath = '${downloadDir.path}/${file.name}';
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();

      // 创建进度控制器
      final controller = StreamController<double>.broadcast();
      _downloadControllers[taskId] = controller;
      _downloadPaths[taskId] = localPath;

      // 开始下载
      _apiService.downloadFile(
        file.path,
        localPath,
        onProgress: (progress) {
          controller.add(progress);
          _updateNotification(taskId, file.name, progress);
        },
        onComplete: () {
          controller.add(1.0);
          _completeDownload(taskId, file.name);
          controller.close();
        },
        onError: (error) {
          controller.addError(error);
          _errorDownload(taskId, file.name, error);
          controller.close();
        },
      );

      return taskId;
    } catch (e) {
      debugPrint('Error starting download: $e');
      return null;
    }
  }

  Stream<double> progress(String taskId) {
    return _downloadControllers[taskId]?.stream ?? const Stream.empty();
  }

  String? getLocalPath(String taskId) {
    return _downloadPaths[taskId];
  }

  void _updateNotification(String taskId, String fileName, double progress) {
    _notifications?.show(
      taskId.hashCode,
      'Downloading $fileName',
      'Progress: ${(progress * 100).toStringAsFixed(1)}%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Show download progress',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: (progress * 100).round(),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  void _completeDownload(String taskId, String fileName) {
    _notifications?.show(
      taskId.hashCode,
      'Download Complete',
      '$fileName has been downloaded',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Show download progress',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _errorDownload(String taskId, String fileName, dynamic error) {
    _notifications?.show(
      taskId.hashCode,
      'Download Failed',
      'Failed to download $fileName: $error',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Show download progress',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelDownload(String taskId) async {
    _downloadControllers[taskId]?.close();
    _downloadControllers.remove(taskId);
    _downloadPaths.remove(taskId);
    await _notifications?.cancel(taskId.hashCode);
  }

  void dispose() {
    for (final controller in _downloadControllers.values) {
      controller.close();
    }
    _downloadControllers.clear();
    _downloadPaths.clear();
  }
}
