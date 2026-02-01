import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'my_reports_screen.dart';
import '../utils/keyword_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/offline_storage_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/anon_id.dart';
import '../services/image_upload_service.dart';
import '../services/audio_upload_service.dart';
import '../services/location_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isSubmitting = false;
  bool _isRecording = false;

  File? _selectedImage;
  File? _audioFile;

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      if (await ConnectivityService.isOnline()) {
        await SyncService.syncOfflineReports(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ---------------- AUDIO ----------------
  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Microphone permission denied"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    const config = RecordConfig();

    await _audioRecorder.start(config, path: path);

    setState(() {
      _isRecording = true;
      _audioFile = null;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      if (path != null) {
        _audioFile = File(path);
      }
    });
  }

  // ---------------- IMAGE ----------------
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final saved = await File(image.path).copy('${appDir.path}/${image.name}');

    setState(() {
      _selectedImage = saved;
    });
  }

  // ---------------- REMOVE ATTACHMENTS ----------------
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _removeAudio() {
    setState(() {
      _audioFile = null;
    });
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submitReport() async {
    if (_controller.text.trim().isEmpty &&
        _selectedImage == null &&
        _audioFile == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final anonId = await getOrCreateAnonId();
      final reportId = const Uuid().v4();
      final text = _controller.text.trim();

      // Priority
      final priority = KeywordConfig.getPriority(text);

      // Location
      final location = await LocationService.getCurrentLocation();

      // Base report (NO media yet)
      final reportData = {
        'report_id': reportId,
        'anon_id': anonId,
        'description': text,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        'priorityLevel': priority,
        'imageUrl': null,
        'audioUrl': null,
        'location': location,
        'uploading': true,
      };

      bool savedOnline = false;

      // Try Firestore FIRST
      try {
        await FirestoreService().submitRawReport(reportData);
        savedOnline = true;
      } catch (e) {
        // If Firestore fails → Save Offline
        await OfflineStorageService.saveOfflineReport(reportData);
        savedOnline = false;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedOnline
                ? "Report submitted ✓ Uploading media..."
                : "Saved offline • Will sync later",
          ),
          backgroundColor: savedOnline ? Colors.green : Colors.orange,
        ),
      );

      // Reset UI
      _controller.clear();

      final File? image =
      _selectedImage != null ? File(_selectedImage!.path) : null;

      final File? audio =
      _audioFile != null ? File(_audioFile!.path) : null;

      setState(() {
        _selectedImage = null;
        _audioFile = null;
      });

      // Upload media ONLY if online save succeeded
      if (savedOnline) {
        _uploadMediaInBackground(
          reportId: reportId,
          image: image,
          audio: audio,
        );
      }
    } catch (e) {
      debugPrint("Submit error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _uploadMediaInBackground({
    required String reportId,
    File? image,
    File? audio,
  }) async {
    try {
      String? imageUrl;
      String? audioUrl;

      // Upload image
      if (image != null) {
        imageUrl = await ImageUploadService.uploadReportImage(
          imageFile: image,
          reportId: reportId,
        );
      }

      // Upload audio
      if (audio != null) {
        audioUrl = await AudioUploadService.uploadAudio(
          audioFile: audio,
          reportId: reportId,
        );
      }

      // Update Firestore safely
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .set(
        {
          'imageUrl': imageUrl,
          'audioUrl': audioUrl,
          'uploading': false,
        },
        SetOptions(merge: true),
      );

      debugPrint("Media upload completed for $reportId");
    } catch (e) {
      debugPrint("Background upload error: $e");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Anonymous Crime Report",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyReportsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.list_alt_outlined,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'My Reports',
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Describe the incident",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  color: Colors.grey.shade50,
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 4,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                  decoration: InputDecoration(
                    hintText: "Enter details of the incident (optional)",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaButton(
                    onPressed: _pickImage,
                    icon: Icons.camera_alt_outlined,
                    label: "Photo",
                    color: Colors.blue.shade500,
                  ),
                  _buildMediaButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: _isRecording ? Icons.stop_circle : Icons.mic_none_outlined,
                    label: _isRecording ? "Stop" : "Record",
                    color: _isRecording ? Colors.red.shade400 : Colors.green.shade600,
                  ),
                ],
              ),
              // PREVIEW WITH REMOVE BUTTONS
              if (_selectedImage != null || _audioFile != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade100, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Attachments",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: Colors.indigo,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _audioFile = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            label: const Text(
                              "Clear all",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // IMAGE PREVIEW WITH REMOVE BUTTON
                      if (_selectedImage != null) ...[
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade500,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "Photo",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // AUDIO CHIP WITH REMOVE BUTTON
                      if (_audioFile != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.green.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.audiotrack,
                                  size: 24, color: Colors.greengit ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Audio recording",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    Text(
                                      "${_formatFileSize(_audioFile!.lengthSync())} • Ready to submit",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _removeAudio,
                                icon: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        if (_selectedImage != null) const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // SUBMIT
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _isSubmitting || _isRecording
                        ? LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                    )
                        : LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.indigo.shade800],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade900.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _isRecording ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    )
                        : const Text(
                      "Submit Anonymously",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isRecording
                      ? "• Recording in progress •"
                      : "Your identity remains completely anonymous",
                  style: TextStyle(
                    fontSize: 13,
                    color: _isRecording ? Colors.red.shade500 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 36, color: color),
            padding: const EdgeInsets.all(16),
            splashRadius: 32,
            splashColor: color.withOpacity(0.2),
            highlightColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}