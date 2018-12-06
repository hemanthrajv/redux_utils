import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:example/data/app_repository.dart';
import 'package:example/data/preference_client.dart';
import 'package:example/middleware/middleware.dart';
import 'package:example/models/models.dart';
import 'package:example/reducers/reducers.dart';
import 'package:example/theme.dart';
import 'package:example/views/init_page.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final AppRepository repository = AppRepository(
    preferencesClient: PreferencesClient(prefs: prefs),
  );

  runApp(
    Example(
      repository: repository,
    ),
  );
}

class Example extends StatefulWidget {
  final Store<AppState> store;

  Example({Key key, AppRepository repository})
      : store = Store<AppState>(
          reducer,
          middleware: middleware(repository),
          initialState: AppState.initState(),
        ),
        super(key: key);

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  Store<AppState> store;

  @override
  void initState() {
    super.initState();
    store = widget.store;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        navigatorKey: store.state.navigator,
        title: 'Example',
        theme: themeData,
      ),
    );
  }
}
