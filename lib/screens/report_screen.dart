import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../services/firestore_service.dart';
import '../utils/anon_id.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final report = Report(
      reportId: const Uuid().v4(),
      anonId: generateAnonId(),
      description: _controller.text.trim(),
      timestamp: DateTime.now(),
      location: "User-selected area",
      status: "pending",
    );

    await FirestoreService().submitReport(report);

    _controller.clear();
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report submitted anonymously")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Anonymous Crime Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Describe the incident",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Enter details here...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Anonymously"),
            ),
          ],
        ),
      ),
    );
  }
}
