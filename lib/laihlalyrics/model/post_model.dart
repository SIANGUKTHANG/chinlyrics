import 'package:isar/isar.dart';

part 'post_model.g.dart';

@collection
class PostModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? firestoreId;

  String? uploaderId;

  @Index(type: IndexType.value, caseSensitive: false) // Min in kawl khawhnak
  String? userName;

  String? userImage;

  @Index(type: IndexType.value, caseSensitive: false) // Ca chungfang in kawl khawhnak
  String? content;

  // ================= A BIAPI BIK: MULTI-IMAGE CAAH =================
  // imageUrl (String) kha imageUrls (List) ah kan thlen
  List<String>? imageUrls;

  int? likes;
  int? comments;
  List<String>? likedBy;

  @Index() // Cung lei/tang lei (Sorting) a ran nakhnga
  int? createdAt;
}