

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart' as path;
import '../models/models.dart';
class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chats.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final fullPath = path.join(dbPath.path, filePath);
    return await openDatabase(fullPath, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        participants TEXT,
        lastMessage TEXT,
        lastMessageTime INTEGER,
        adId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        chatId TEXT,
        senderId TEXT,
        text TEXT,
        timestamp INTEGER,
        FOREIGN KEY (chatId) REFERENCES chats (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        fullName TEXT,
        email TEXT,
        profilePicture TEXT,
        fcmToken TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ads(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        sellerId TEXT,
        price REAL
      )
    ''');
  }

  Future<void> saveChat(ChatModel chat) async {
    final db = await database;
    await db.insert('chats', chat.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveMessage(String chatId, MessageModel message) async {
    final db = await database;
    await db.insert('messages', {
      ...message.toJson(),
      'chatId': chatId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveAd(AdModel ad) async {
    final db = await database;
    await db.insert('ads', ad.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatModel>> getChats() async {
    final db = await database;
    final chats = await db.query('chats', orderBy: 'lastMessageTime DESC');
    return chats.map((json) => ChatModel.fromJson(json)).toList();
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final db = await database;
    final messages = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );
    return messages.map((json) => MessageModel.fromJson(json)).toList();
  }

  Future<String?> getChatId(String userId1, String userId2, String adId) async {
    final db = await database;
    final result = await db.query(
      'chats',
      where: 'participants LIKE ? AND participants LIKE ? AND adId = ?',
      whereArgs: ['%$userId1%', '%$userId2%', adId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as String?;
    }
    return null;
  }

  Future<ChatModel?> getChat(String chatId) async {
    final db = await database;
    final results = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return ChatModel.fromJson(results.first);
    }
    return null;
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return UserModel.fromJson(results.first);
    }
    return null;
  }

  Future<AdModel?> getAd(String adId) async {
    final db = await database;
    final results = await db.query(
      'ads',
      where: 'id = ?',
      whereArgs: [adId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return AdModel.fromJson(results.first);
    }
    return null;
  }

  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete('chats', where: 'id = ?', whereArgs: [chatId]);
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}