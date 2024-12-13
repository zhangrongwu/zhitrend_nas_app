import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/file_item.dart';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'files';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'zhitrend_nas.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            path TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            is_directory INTEGER NOT NULL,
            size INTEGER NOT NULL,
            modified_time TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            is_local INTEGER NOT NULL,
            is_synced INTEGER NOT NULL,
            local_path TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertFile(FileItem file) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        'path': file.path,
        'name': file.name,
        'is_directory': file.isDirectory ? 1 : 0,
        'size': file.size,
        'modified_time': file.modifiedTime.toIso8601String(),
        'mime_type': file.mimeType,
        'is_local': file.isLocal ? 1 : 0,
        'is_synced': file.isSynced ? 1 : 0,
        'local_path': file.localPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFile(FileItem file) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'name': file.name,
        'is_directory': file.isDirectory ? 1 : 0,
        'size': file.size,
        'modified_time': file.modifiedTime.toIso8601String(),
        'mime_type': file.mimeType,
        'is_local': file.isLocal ? 1 : 0,
        'is_synced': file.isSynced ? 1 : 0,
        'local_path': file.localPath,
      },
      where: 'path = ?',
      whereArgs: [file.path],
    );
  }

  Future<void> deleteFile(String path) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  Future<FileItem?> getFile(String path) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'path = ?',
      whereArgs: [path],
    );

    if (maps.isEmpty) return null;

    return FileItem(
      name: maps[0]['name'] as String,
      path: maps[0]['path'] as String,
      isDirectory: maps[0]['is_directory'] == 1,
      size: maps[0]['size'] as int,
      modifiedTime: DateTime.parse(maps[0]['modified_time'] as String),
      mimeType: maps[0]['mime_type'] as String,
      isLocal: maps[0]['is_local'] == 1,
      isSynced: maps[0]['is_synced'] == 1,
      localPath: maps[0]['local_path'] as String?,
    );
  }

  Future<List<FileItem>> getFiles(String directory) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: "path LIKE ? AND path != ?",
      whereArgs: ['$directory%', directory],
    );

    return List.generate(maps.length, (i) {
      return FileItem(
        name: maps[i]['name'] as String,
        path: maps[i]['path'] as String,
        isDirectory: maps[i]['is_directory'] == 1,
        size: maps[i]['size'] as int,
        modifiedTime: DateTime.parse(maps[i]['modified_time'] as String),
        mimeType: maps[i]['mime_type'] as String,
        isLocal: maps[i]['is_local'] == 1,
        isSynced: maps[i]['is_synced'] == 1,
        localPath: maps[i]['local_path'] as String?,
      );
    });
  }

  Future<List<FileItem>> getUnsyncedFiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return FileItem(
        name: maps[i]['name'] as String,
        path: maps[i]['path'] as String,
        isDirectory: maps[i]['is_directory'] == 1,
        size: maps[i]['size'] as int,
        modifiedTime: DateTime.parse(maps[i]['modified_time'] as String),
        mimeType: maps[i]['mime_type'] as String,
        isLocal: maps[i]['is_local'] == 1,
        isSynced: maps[i]['is_synced'] == 1,
        localPath: maps[i]['local_path'] as String?,
      );
    });
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(tableName);
  }
}
