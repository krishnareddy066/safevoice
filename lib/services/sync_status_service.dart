import 'package:flutter/material.dart';

class SyncStatusService extends ChangeNotifier {

  bool _isSyncing = false;
  int _pendingCount = 0;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  void startSync() {
    _isSyncing = true;
    notifyListeners();
  }

  void stopSync() {
    _isSyncing = false;
    notifyListeners();
  }

  void setPending(int count) {
    _pendingCount = count;
    notifyListeners();
  }
}
