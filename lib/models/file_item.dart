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
  final int childCount;

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
    this.childCount = 0,
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
      childCount: json['child_count'] as int? ?? 0,
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
      'child_count': childCount,
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
    int? childCount,
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
      childCount: childCount ?? this.childCount,
    );
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isText => mimeType.startsWith('text/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isCode => [
    'text/x-python',
    'text/x-java',
    'text/x-c',
    'text/x-cpp',
    'text/x-swift',
    'text/x-rust',
    'text/x-go',
    'text/x-yaml',
    'text/x-dockerfile',
    'application/x-shellscript',
    'application/json',
    'text/javascript',
    'text/css',
    'text/html',
    'text/xml',
  ].contains(mimeType);
  bool get isOffice => [
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  ].contains(mimeType);

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  
  String get sizeString {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get modifiedString => '${modifiedTime.year}-${modifiedTime.month.toString().padLeft(2, '0')}-${modifiedTime.day.toString().padLeft(2, '0')} ${modifiedTime.hour.toString().padLeft(2, '0')}:${modifiedTime.minute.toString().padLeft(2, '0')}';
}
