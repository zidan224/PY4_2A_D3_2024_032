import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String username;

  @HiveField(5)
  final String authorId;

  @HiveField(6)
  final String teamId;

  @HiveField(7)
  final String? authorRole;

  @HiveField(8)
  final bool? isPublic;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.username,
    required this.authorId,
    required this.teamId,
    this.authorRole = 'Anggota',
    this.isPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'description': description,
      'date': date,
      'username': username,
      'authorId': authorId,
      'teamId': teamId,
      'authorRole': authorRole,
      'isPublic': isPublic,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      username: map['username'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
      authorRole: map['authorRole'] ?? 'Anggota',
    );
  }
}
