import 'package:isar/isar.dart';

part 'song_model.g.dart';

@collection
class SongModel {
  Id isarId = Isar.autoIncrement; // internal id

  @Index(unique: true)
  late String id; // Firebase doc id
  late String title;
  late String singer;
  String? soundtrack;
  late String category;
  late bool isChord;
  late String lyrics;
  late String uploaderId;
  late String type;
  late bool approved;
  late int likes;
  late int comments;
  @Index()
  late int createdAt;
  @Index()
  late int updatedAt;
  late bool isLikedByMe;
}