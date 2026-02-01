import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'offline_storage_service.dart';
import 'firestore_service.dart';
import 'sync_status_service.dart';

class SyncService {
  static Future<void> syncOfflineReports(context) async {
    final status = Provider.of<SyncStatusService>(
      context,
      listen: false,
    );

    status.startSync();

    final reports = await OfflineStorageService.getOfflineReports();

    status.setPending(reports.length);

    for (final report in reports) {
      try {
        await FirestoreService().submitRawReport(report);

        await OfflineStorageService.deleteOfflineReport(
          report['report_id'],
        );
      } catch (e) {
        debugPrint("Sync failed: $e");
        break; // stop if network fails
      }
    }

    final remaining =
    await OfflineStorageService.getOfflineReports();

    status.setPending(remaining.length);

    status.stopSync();
  }
}

