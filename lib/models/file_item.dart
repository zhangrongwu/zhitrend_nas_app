class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedTime;
  final String mimeType;
  final bool isLocal;
  final bool isSynced;
  final String? localPath;

  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedTime,
    required this.mimeType,
    this.isLocal = false,
    this.isSynced = false,
    this.localPath,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: json['is_directory'] as bool,
      size: json['size'] as int,
      modifiedTime: DateTime.parse(json['modified_time'] as String),
      mimeType: json['mime_type'] as String,
      isLocal: json['is_local'] as bool? ?? false,
      isSynced: json['is_synced'] as bool? ?? false,
      localPath: json['local_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'is_directory': isDirectory,
      'size': size,
      'modified_time': modifiedTime.toIso8601String(),
      'mime_type': mimeType,
      'is_local': isLocal,
      'is_synced': isSynced,
      'local_path': localPath,
    };
  }

  FileItem copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    DateTime? modifiedTime,
    String? mimeType,
    bool? isLocal,
    bool? isSynced,
    String? localPath,
  }) {
    return FileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      mimeType: mimeType ?? this.mimeType,
      isLocal: isLocal ?? this.isLocal,
      isSynced: isSynced ?? this.isSynced,
      localPath: localPath ?? this.localPath,
    );
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isText => mimeType.startsWith('text/');

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
