import 'package:cloud_firestore/cloud_firestore.dart';

class ListItem {
  final String id;
  final String predmet;
  final DateTime datum;
  final String userId;

  ListItem(
      {this.id = '',
      required this.predmet,
      required this.datum,
      required this.userId});

  Map<String, dynamic> toJson() => {
        'id': id,
        'predmet': predmet,
        'datum': datum,
        'userId': userId,
      };

  static ListItem fromJson(Map<String, dynamic> json) => ListItem(
        id: json['id'],
        predmet: json['predmet'],
        datum: (json['datum'] as Timestamp).toDate(),
        userId: json['userId'],
      );
}
