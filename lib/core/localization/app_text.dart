import 'app_language_controller.dart';

class AppText {
  AppText._();

  static final AppLanguageController _controller = AppLanguageController.instance;

  static bool get isBangla => _controller.isBangla;

  static String tr(String en, String bn) => _controller.text(en, bn);
}
