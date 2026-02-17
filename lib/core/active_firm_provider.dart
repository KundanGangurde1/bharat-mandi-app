import 'package:flutter/material.dart';
import '../features/firm_setup/firm_model.dart';
import '../features/firm_setup/firm_service.dart';

class ActiveFirmProvider extends ChangeNotifier {
  Firm? _activeFirm;
  bool _isLoading = true;

  Firm? get activeFirm => _activeFirm;
  bool get isLoading => _isLoading;

  /// ✅ Load active firm with fallback logic
  /// 1. Try to get firm with active = 1
  /// 2. If not found, get latest firm and auto-activate it
  /// 3. If no firms exist, return null (show firm creation form)
  Future<void> loadActiveFirm() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1️⃣ Try to get active firm
      final firm = await FirmService.getActiveFirm();

      if (firm != null) {
        _activeFirm = firm;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2️⃣ No active firm found, try to get latest firm
      final allFirms = await FirmService.getAllFirms();

      if (allFirms.isNotEmpty) {
        // Get the latest firm (first in the list since sorted by created_at DESC)
        final latestFirm = allFirms.first;

        // Auto-activate the latest firm
        await FirmService.setActiveFirm(latestFirm.id);

        // Reload to confirm activation
        final activatedFirm = await FirmService.getFirmById(latestFirm.id);
        _activeFirm = activatedFirm;

        print('✅ Auto-activated latest firm: ${latestFirm.name}');
      } else {
        // 3️⃣ No firms exist at all
        _activeFirm = null;
        print('ℹ️ No firms exist, showing firm creation form');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading active firm: $e');
      _activeFirm = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Set active firm and update state
  Future<void> setActiveFirm(Firm firm) async {
    try {
      await FirmService.setActiveFirm(firm.id);
      _activeFirm = firm;
      _isLoading = false;
      notifyListeners();
      print('✅ Active firm changed to: ${firm.name}');
    } catch (e) {
      print('❌ Error setting active firm: $e');
      rethrow;
    }
  }

  /// ✅ Refresh active firm from database
  Future<void> refreshActiveFirm() async {
    try {
      final firm = await FirmService.getActiveFirm();
      _activeFirm = firm;
      notifyListeners();
      print('✅ Active firm refreshed');
    } catch (e) {
      print('❌ Error refreshing active firm: $e');
      rethrow;
    }
  }
}
