import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailsScreen({
    super.key,
    required this.reportData,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportData;
    final description = data['description'] ?? 'No description provided';
    final status = data['status'] ?? 'pending';
    final priority = data['priorityLevel'] ?? 'Normal';
    final imageUrl = data['imageUrl'];
    final audioUrl = data['audioUrl'];

    String dateText = 'Unknown date';
    final timestamp = data['timestamp'];
    if (timestamp != null && timestamp is Timestamp) {
      final date = timestamp.toDate();
      dateText = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Report Details",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER BADGES
            Row(
              children: [
                _buildDetailBadge(
                  label: "Status",
                  value: status.toUpperCase(),
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 12),
                _buildDetailBadge(
                  label: "Priority",
                  value: priority.toUpperCase(),
                  color: _getPriorityColor(priority),
                ),
                const SizedBox(width: 12),
                _buildDetailBadge(
                  label: "Date",
                  value: dateText.split(' ')[0],
                  color: Colors.indigo.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // DESCRIPTION SECTION
            _buildSectionHeader("Description"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Text(
                description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),

            // IMAGE SECTION
            if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
              _buildSectionHeader("Attached Image"),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 240,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 240,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // AUDIO SECTION
            if (audioUrl != null && audioUrl.toString().isNotEmpty) ...[
              _buildSectionHeader("Audio Evidence"),
              const SizedBox(height: 16),
              _buildAudioPlayer(
                isPlaying: _isPlaying,
                onPlayPause: () async {
                  if (_isPlaying) {
                    await _player.pause();
                  } else {
                    await _player.play(UrlSource(audioUrl));
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.indigo,
      ),
    );
  }

  Widget _buildDetailBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer({
    required bool isPlaying,
    required VoidCallback onPlayPause,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 28,
            color: Colors.indigo.shade700,
          ),
        ),
        title: Text(
          isPlaying ? "Playing audio evidence" : "Audio recording",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          isPlaying ? "Tap to pause playback" : "Tap to listen to audio evidence",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying ? Icons.stop : Icons.play_arrow,
            color: Colors.indigo.shade700,
            size: 30,
          ),
          onPressed: onPlayPause,
          splashRadius: 24,
        ),
      ),
    );
  }
}