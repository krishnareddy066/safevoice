import 'package:cloud_firestore/cloud_firestore.dart';

class ReportFetchService {

  static Stream<QuerySnapshot> getMyReports(String anonId) {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('anon_id', isEqualTo: anonId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
