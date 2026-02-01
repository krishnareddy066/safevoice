import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit using Report Model
  Future<void> submitReport(Report report) async {
    await _firestore
        .collection('reports')
        .doc(report.reportId) // ✅ use reportId from model
        .set(
      report.toMap(), // ✅ convert to Map
      SetOptions(merge: true),
    );
  }

  // Submit using Raw Map (for offline / quick save)
  Future<void> submitRawReport(
      Map<String, dynamic> data) async {

    final String reportId = data['report_id'];

    await _firestore
        .collection('reports')
        .doc(reportId)
        .set(data);
  }

}
