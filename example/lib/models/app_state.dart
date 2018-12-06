import 'package:built_value/built_value.dart';
import 'package:flutter/material.dart' hide Builder;

part 'app_state.g.dart';

abstract class AppState implements Built<AppState, AppStateBuilder> {
  factory AppState([AppStateBuilder updates(AppStateBuilder builder)]) =
      _$AppState;

  AppState._();

  static AppState initState() {
    return new AppState((AppStateBuilder b) {
      b..navigator = GlobalKey<NavigatorState>();
    });
  }
  
  GlobalKey<NavigatorState> get navigator;
}
