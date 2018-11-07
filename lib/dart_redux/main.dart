import 'dart:async';
import 'dart:io';

import 'package:pubspec/pubspec.dart';
import 'package:redux_utils/dart_redux/dart_redux.dart';
import 'package:redux_utils/utils.dart';

Directory _current = Directory.current;
Directory _temp = Directory.systemTemp;

void main() async {
  try {
    final DartRedux _redux = DartRedux();
    await _redux.initialize();
    await _redux.setup();
  } catch (e) {
    if (e is SetupError) {
      print(e.message);
    } else {
      throw e;
    }
  }
}