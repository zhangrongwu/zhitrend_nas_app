import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:office_viewer/office_viewer.dart';
import 'package:image_editor/image_editor.dart';
import '../models/file_item.dart';
import 'database_service.dart';

class PreviewService {
  final DatabaseService _databaseService;
  
  PreviewService({required DatabaseService databaseService})
      : _databaseService = databaseService;

  Future<Widget> getPreviewWidget(FileItem file, String localPath) async {
    final extension = path.extension(file.name).toLowerCase();
    
    // 检查文件是否在本地可用
    final isLocal = await _databaseService.isFileAvailableLocally(file.path);
    final filePath = isLocal ? localPath : file.path;

    switch (extension) {
      // 图片预览
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return ImagePreviewWidget(
          filePath: filePath,
          isLocal: isLocal,
        );
      
      // 视频预览
      case '.mp4':
      case '.mov':
      case '.avi':
        return VideoPreviewWidget(
          filePath: filePath,
          isLocal: isLocal,
        );
      
      // 音频预览
      case '.mp3':
      case '.wav':
      case '.m4a':
        return AudioPreviewWidget(
          filePath: filePath,
          isLocal: isLocal,
        );
      
      // PDF预览
      case '.pdf':
        return PDFPreviewWidget(
          filePath: filePath,
          isLocal: isLocal,
        );
      
      // Office文档预览
      case '.doc':
      case '.docx':
      case '.xls':
      case '.xlsx':
      case '.ppt':
      case '.pptx':
        return OfficePreviewWidget(
          filePath: filePath,
          isLocal: isLocal,
        );
      
      // 文本预览
      case '.txt':
      case '.md':
      case '.json':
      case '.xml':
      case '.yml':
      case '.yaml':
        return TextPreviewWidget(
          filePath: filePath,
          isLocal: isLocal,
        );
      
      default:
        return const Center(
          child: Text('不支持预览此类型的文件'),
        );
    }
  }

  // 获取文件的缩略图
  Future<Widget> getThumbnail(FileItem file, String localPath) async {
    final extension = path.extension(file.name).toLowerCase();
    final isLocal = await _databaseService.isFileAvailableLocally(file.path);
    final filePath = isLocal ? localPath : file.path;

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image);
          },
        );
      
      case '.mp4':
      case '.mov':
      case '.avi':
        return const Icon(Icons.video_library);
      
      case '.mp3':
      case '.wav':
      case '.m4a':
        return const Icon(Icons.audio_file);
      
      case '.pdf':
        return const Icon(Icons.picture_as_pdf);
      
      case '.doc':
      case '.docx':
        return const Icon(Icons.description);
      
      case '.xls':
      case '.xlsx':
        return const Icon(Icons.table_chart);
      
      case '.ppt':
      case '.pptx':
        return const Icon(Icons.presentation);
      
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }
}

// 各种预览widget的实现...（这里先省略具体实现，需要时我可以展开）
