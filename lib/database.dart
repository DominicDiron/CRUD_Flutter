import 'package:crud/model/user.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;

class DatabaseHelper {
  static sql.Database? _database;

  static Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB('crud');
    return _database!;
  }

  static Future<void> createDatabase(sql.Database db) async {
    await db.execute("""CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      imagePath TEXT
    )""");
  }

  static Future<sql.Database> initDB(String filePath) async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await sql.openDatabase(path, version: 1, onCreate: (sql.Database database,int version) async{
        await createDatabase(database);
      });
  }

  static Future<int> create(String name, String imagePath) async {
    final db = await database;
    return await db.insert('users', {'name': name, 'imagePath': imagePath},conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<List<User>> readAll() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('users');
  return List.generate(maps.length, (i) {
    return User(
      id: maps[i]['id'],
      name: maps[i]['name'],
      imagePath: maps[i]['imagePath'],
    );
  });
}


  static Future<int> update(User user) async {
    final db = await database;
    return await db.update('users', {'name': user.name, 'imagePath': user.imagePath}, where: 'id = ?', whereArgs: [user.id]);
  }

  static Future<int> delete(User user) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
  }

  static Future close() async {
    final db = await database;
    db.close();
  }
}
