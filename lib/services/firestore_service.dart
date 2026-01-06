import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReport(Report report) async {
    await _firestore.collection('reports').add(report.toMap());
  }
}
