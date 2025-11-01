import 'package:flutter/foundation.dart';

import '../persistence/prefs.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings I = AppSettings._();
  AppSettings._();

  bool showPreview = true;
  bool showDescriptions = true;

  Future<void> restore() async {
    showPreview = (await Prefs.getString('ui_show_preview')) != '0';
    showDescriptions = (await Prefs.getString('ui_show_desc')) != '0';
    notifyListeners();
  }

  Future<void> setShowPreview(bool v) async {
    showPreview = v;
    await Prefs.setString('ui_show_preview', v ? '1' : '0');
    notifyListeners();
  }

  Future<void> setShowDescriptions(bool v) async {
    showDescriptions = v;
    await Prefs.setString('ui_show_desc', v ? '1' : '0');
    notifyListeners();
  }
}

