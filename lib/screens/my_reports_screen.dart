import 'report_details_screen.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/report_fetch_service.dart';
import '../utils/anon_id.dart';
import 'package:provider/provider.dart';
import '../services/sync_status_service.dart';
import '../services/sync_service.dart';
import '../widgets/network_banner.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String? _anonId;

  @override
  void initState() {
    super.initState();
    _loadAnonId();
  }

  Future<void> _loadAnonId() async {
    final id = await getOrCreateAnonId();
    setState(() {
      _anonId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Reports",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
      ),
      body: _anonId == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : StreamBuilder<QuerySnapshot>(
        stream: ReportFetchService.getMyReports(_anonId!),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator.adaptive(),
                  SizedBox(height: 16),
                  Text(
                    "Loading your reports...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading reports: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Empty
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_gmailerrorred, size: 64, color: Colors.indigo),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "No reports submitted yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the '+' button to submit your first anonymous report",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // List
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final description = data['description'] ?? 'No description';
              final status = data['status'] ?? 'pending';
              final priority = data['priorityLevel'] ?? 'Normal';
              final timestamp = data['timestamp'];

              String dateText = "Unknown date";

              if (timestamp != null) {
                try {
                  // New format (String)
                  if (timestamp is String) {
                    final date = DateTime.parse(timestamp);

                    dateText =
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                  }

                  // Old format (Firestore Timestamp)
                  else if (timestamp is Timestamp) {
                    final date = timestamp.toDate();

                    dateText =
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                  }
                } catch (_) {
                  dateText = "Unknown date";
                }
              }


              Color _getStatusColor(String status) {
                switch (status.toLowerCase()) {
                  case 'resolved':
                    return Colors.green.shade600;
                  case 'in progress':
                    return Colors.orange.shade600;
                  case 'pending':
                    return Colors.blue.shade600;
                  default:
                    return Colors.grey;
                }
              }

              Color _getPriorityColor(String priority) {
                switch (priority.toLowerCase()) {
                  case 'high':
                    return Colors.red.shade600;
                  case 'medium':
                    return Colors.orange.shade600;
                  case 'normal':
                  default:
                    return Colors.blue.shade400;
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailsScreen(
                            reportData: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      // ✅ CORRECTED BORDER IMPLEMENTATION
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: _getStatusColor(status),
                            width: 5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.report,
                            color: Colors.indigo,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _buildStatusChip(status, _getStatusColor(status)),
                                _buildPriorityChip(priority, _getPriorityColor(priority)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    dateText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        "PRIORITY: ${priority.toUpperCase()}",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}