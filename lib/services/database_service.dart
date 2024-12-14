import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/file_item.dart';

class DatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> init() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS files (
        path TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        size INTEGER NOT NULL,
        modified TEXT NOT NULL,
        is_directory INTEGER NOT NULL,
        local_path TEXT,
        sync_status TEXT,
        last_synced TEXT,
        is_synced INTEGER DEFAULT 0,
        child_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'zhitrend_nas.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 文件缓存表
        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT UNIQUE,
            name TEXT,
            size INTEGER,
            modified TEXT,
            is_directory INTEGER,
            local_path TEXT,
            sync_status TEXT,
            last_synced TEXT,
            is_synced INTEGER,
            child_count INTEGER DEFAULT 0
          )
        ''');

        // 备份记录表
        await db.execute('''
          CREATE TABLE backup_files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_hash TEXT UNIQUE,
            backup_path TEXT,
            backup_time TEXT
          )
        ''');

        // 配置表
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  // 文件相关操作
  Future<void> insertFile(FileItem file) async {
    final db = await database;
    await db.insert(
      'files',
      file.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveFile(FileItem file) async {
    final db = await database;
    await db.insert(
      'files',
      {
        'path': file.path,
        'name': file.name,
        'size': file.size,
        'modified': file.modifiedTime.toIso8601String(),
        'is_directory': file.isDirectory ? 1 : 0,
        'local_path': file.localPath,
        'is_synced': file.isSynced ? 1 : 0,
        'child_count': file.childCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFile(String path) async {
    final db = await database;
    await db.delete(
      'files',
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  Future<List<FileItem>> getFiles(String path) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'path LIKE ?',
      whereArgs: ['$path%'],
    );

    return List.generate(maps.length, (i) {
      return FileItem(
        path: maps[i]['path'],
        name: maps[i]['name'],
        size: maps[i]['size'],
        modifiedTime: DateTime.parse(maps[i]['modified']),
        isDirectory: maps[i]['is_directory'] == 1,
        mimeType: 'application/octet-stream',
        isLocal: maps[i]['local_path'] != null,
        isSynced: maps[i]['is_synced'] == 1,
        localPath: maps[i]['local_path'],
        childCount: maps[i]['child_count'] ?? 0,
      );
    });
  }

  Future<FileItem?> getFile(String path) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return FileItem(
      path: maps[0]['path'],
      name: maps[0]['name'],
      size: maps[0]['size'],
      modifiedTime: DateTime.parse(maps[0]['modified']),
      isDirectory: maps[0]['is_directory'] == 1,
      mimeType: 'application/octet-stream',
      isLocal: maps[0]['local_path'] != null,
      isSynced: maps[0]['is_synced'] == 1,
      localPath: maps[0]['local_path'],
      childCount: maps[0]['child_count'] ?? 0,
    );
  }

  Future<void> updateFile(FileItem file) async {
    final db = await database;
    await db.update(
      'files',
      {
        'name': file.name,
        'size': file.size,
        'modified': file.modifiedTime.toIso8601String(),
        'is_directory': file.isDirectory ? 1 : 0,
        'is_synced': file.isSynced ? 1 : 0,
        'local_path': file.localPath,
        'child_count': file.childCount,
      },
      where: 'path = ?',
      whereArgs: [file.path],
    );
  }

  Future<List<FileItem>> getUnsyncedFiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return FileItem(
        path: maps[i]['path'],
        name: maps[i]['name'],
        size: maps[i]['size'],
        modifiedTime: DateTime.parse(maps[i]['modified']),
        isDirectory: maps[i]['is_directory'] == 1,
        mimeType: 'application/octet-stream',
        isLocal: maps[i]['local_path'] != null,
        isSynced: false,
        localPath: maps[i]['local_path'],
        childCount: maps[i]['child_count'] ?? 0,
      );
    });
  }

  Future<void> markAsSynced(String path) async {
    final db = await database;
    await db.update(
      'files',
      {'is_synced': 1},
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  Future<void> clearFiles() async {
    final db = await database;
    await db.delete('files');
  }

  Future<bool> isFileExists(String path) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'files',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // 备份相关操作
  Future<bool> isFileBackedUp(String fileHash) async {
    final db = await database;
    final results = await db.query(
      'backup_files',
      where: 'file_hash = ?',
      whereArgs: [fileHash],
    );
    return results.isNotEmpty;
  }

  Future<void> markFileAsBackedUp(String fileHash, String backupPath) async {
    final db = await database;
    await db.insert(
      'backup_files',
      {
        'file_hash': fileHash,
        'backup_path': backupPath,
        'backup_time': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 设置相关操作
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String;
    }
    return null;
  }

  // 备份设置相关操作
  Future<void> setBackupEnabled(bool enabled) async {
    await setSetting('backup_enabled', enabled.toString());
  }

  Future<bool?> getBackupEnabled() async {
    final value = await getSetting('backup_enabled');
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  Future<void> setLastBackupTime(DateTime time) async {
    await setSetting('last_backup_time', time.toIso8601String());
  }

  Future<DateTime?> getLastBackupTime() async {
    final value = await getSetting('last_backup_time');
    return value != null ? DateTime.parse(value) : null;
  }

  Future<void> setBackupFolder(String folder) async {
    await setSetting('backup_folder', folder);
  }

  Future<String?> getBackupFolder() async {
    return await getSetting('backup_folder');
  }
}
