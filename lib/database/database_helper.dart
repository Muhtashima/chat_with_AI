
import 'chat.dart';
import 'package:sqflite/sqflite.dart';
class DatabaseHelper{
  late Database db;
  DatabaseHelper();



  Future<void> open(String path) async{
    db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE chats (id INTEGER PRIMARY KEY AUTOINCREMENT, prompt TEXT NOT NULL, output TEXT NOT NULL)');
          print('Table chats created');
        }
    );
    print('database opened');

  }

  Future deleteDatabase(String path) async{
    await databaseFactory.deleteDatabase(path);
  }

  Future addChat(Chat chat) async{
    return await db.insert('chats', chat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future removeChats([int? id]) async {
    return await db.delete('chats');
  }
  Future<List<Chat>> retrieveChats([int? id]) async {
    final futureMaps = await db.query('chats');
    final List<Chat> futureChats = futureMaps.map((chat) => Chat.fromMap(chat)).toList();
    return futureChats;
  }

}