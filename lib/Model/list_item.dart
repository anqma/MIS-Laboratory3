import 'package:cloud_firestore/cloud_firestore.dart';

class ListItem {
  final String id;
  final String predmet;
  final DateTime datum;
  final String userId;
  final GeoPoint mesto;

  ListItem({
    this.id = '',
    required this.predmet,
    required this.datum,
    required this.userId,
    this.mesto = const GeoPoint(41.9965, 21.4314),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'predmet': predmet,
        'datum': datum,
        'userId': userId,
        'mesto': mesto,
      };

  static ListItem fromJson(Map<String, dynamic> json) => ListItem(
        id: json['id'],
        predmet: json['predmet'],
        datum: (json['datum'] as Timestamp).toDate(),
        userId: json['userId'],
        mesto: json['mesto'],
      );
}
