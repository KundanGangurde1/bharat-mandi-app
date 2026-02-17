import 'package:flutter/material.dart';
import '../features/firm_setup/firm_model.dart';
import '../features/firm_setup/firm_service.dart';

class ActiveFirmProvider extends ChangeNotifier {
  Firm? _activeFirm;
  bool _isLoading = true;

  Firm? get activeFirm => _activeFirm;
  bool get isLoading => _isLoading;

  Future<void> loadActiveFirm() async {
    _isLoading = true;
    notifyListeners();

    final firm = await FirmService.getActiveFirm();
    _activeFirm = firm;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setActiveFirm(Firm firm) async {
    await FirmService.setActiveFirm(firm.id!);

    _activeFirm = firm;
    _isLoading = false;

    notifyListeners();
  }
}
