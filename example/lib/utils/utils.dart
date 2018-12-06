import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [TextInputFormatter] that only accepts numbers
class NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.contains(RegExp(r'D'))) {
      final TextSelection newSelection = TextSelection(
          baseOffset: newValue.selection.baseOffset - 1,
          extentOffset: newValue.selection.extentOffset - 1);
      final String newText = newValue.text.replaceAll(RegExp(r'D'), '');
      return TextEditingValue(
          text: newText, selection: newSelection, composing: TextRange.empty);
    }
    return newValue;
  }
}

class Logger {
  final String tag;

  Logger({String tag}) : this.tag = tag ?? 'Logger';

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product') ?? false;

  void d(String log) {
    if (isProduction) {
      return;
    }
    debugPrint('D/$tag : $log');
  }

  void i(String log) {
    debugPrint('I/$tag : $log');
  }

  void w(String log) {
    print('W/$tag Warning ===========================================================');
    debugPrint(log);
    print('==========================================================================');
  }

  void e(String log) {
    print('E/$tag ----------------------Error----------------------');
    debugPrint(log);
    print('---------------------------------------------------------');
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
