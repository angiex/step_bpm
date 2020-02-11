import "dart:io";
import "dart:typed_data";

import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:flutter/services.dart";
import "package:sqflite/sqflite.dart";

/////////////////////////////////// MODEL //////////////////////////////////////

class SongData {
  final String title;
  final String artist;
  final int bpm;

  SongData(this.title, this.artist, this.bpm);
}

///////////////////////////////// DATABASE /////////////////////////////////////


class SongDatabase {
  Database db;
  bool initialized;

  SongDatabase() {
     this.initialized = false;
  }

  Future _loadDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "asset_database.db");

    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      // Load database from asset and copy
      ByteData data = await rootBundle.load(join("assets", "db.db"));
      List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes, data.lengthInBytes);

      // Save copied asset to documents
      await new File(path).writeAsBytes(bytes);
    }
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String databasePath = join(appDocDir.path, "asset_database.db");
    db = await openDatabase(databasePath);
    initialized = true;
  }

  Future<List<SongData>> search(int bpm) async {
    if (!initialized) await _loadDB();
    String query = '''SELECT * FROM Songs WHERE BPM = $bpm''';
    List<Map> list = await db.rawQuery(query);
    List <SongData> songs = new List();

    for (int i = 0; i<list.length; i++) {
      songs.add(new SongData(list[i]["Title"], list[i]["Artist"], list[i]["BPM"]));
    }
    return songs;
  }
}