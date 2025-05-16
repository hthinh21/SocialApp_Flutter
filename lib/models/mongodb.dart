import 'dart:developer';

import 'package:mongo_dart/mongo_dart.dart';
import 'constant.dart';
class MongoDatabase{
  static var db, userCollection;
  static connect() async {
    db = await Db.create(MONGO_CONNECTION_STRING);
    await db.open();
    inspect(db);
    log("Connected to MongoDB");
    userCollection = db.collection('users');
  }
}