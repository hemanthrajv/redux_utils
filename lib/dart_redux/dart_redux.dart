import 'dart:async';
import 'dart:io';

import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'package:redux_utils/utils.dart';

Directory _current = Directory.current;
//Directory _temp = Directory.systemTemp;

typedef VoidCallback = void Function();

class DartRedux {
  final String sourcePath;
  PubSpec pubSpec;
  String pubSpecPath;

  //paths
  final String actionsPath;
  final String reducersPath;
  final String modelsPath;
  final String middlewarePath;
  final String dataPath;
  final String apiPath;
  final String servicesPath;
  final String utilsPath;
  final String viewsPath;
  final String libPath;

  final Map<String, String> _dependencies = <String, String>{
    'redux': '^3.0.0',
    'redux_epics': '^0.10.0',
    'flutter_redux': '^0.5.2',
    'built_value': '^6.1.3',
    'built_collection': '^4.0.0',
    'shared_preferences': '0.4.2',
    'rxdart': '^0.18.1',
    'uri': '0.11.3+1',
    'http': '^0.11.3+16',
    'intl': '^0.15.7',
  };

  final Map<String, String> _devDependencies = <String, String>{
    'build_runner': '^1.0.0',
    'built_value_generator': '^6.1.4',
    'flutter_launcher_icons': '^0.6.1',
  };

  DartRedux()
      : sourcePath = _current.path,
        actionsPath = '${_current.path}/lib/actions',
        reducersPath = '${_current.path}/lib/reducers',
        middlewarePath = '${_current.path}/lib/middleware',
        modelsPath = '${_current.path}/lib/models',
        apiPath = '${_current.path}/lib/data/api',
        servicesPath = '${_current.path}/lib/data/services',
        dataPath = '${_current.path}/lib/data',
        utilsPath = '${_current.path}/lib/utils',
        viewsPath = '${_current.path}/lib/views',
        libPath = '${_current.path}/lib';

  bool get initialized => pubSpec != null;

  Future<void> initialize() async {
    final String _pubSpecPath = '$sourcePath/pubspec.yaml';

    bool _pubSpecExists = Utils.fileExists(path: _pubSpecPath);

    if (!_pubSpecExists) {
      throw SetupError(message: 'file not found: pubspec.yaml');
    } else {
      pubSpecPath = _pubSpecPath;
    }
    pubSpec = await PubSpec.load(_current);
  }

  Future<void> setup() async {
    if (!initialized) {
      throw SetupError(message: 'Please call `initialize()` before setup');
    }

    print('Editing pubspec.yaml...');
    await _editPubSpec();
    print('Creating api...');
    await _createApi();
    print('Creating services...');
    await _createService();
    print('Creating data...');
    await _createData();
    print('Creating actions...');
    await _createActions();
    print('Creating models...');
    await _createModels();
    print('Creating middleware...');
    await _createMiddleware();
    print('Creating reducers...');
    await _createReducers();
    print('Creating utils...');
    await _createUtils();
    print('Creating views...');
    await _createViews();
//    print('Creating routes...');
//    await _createRoutes();
    print('Creating theme...');
    await _createTheme();
    print('Editing main.dart...');
    await _editMain();
  }

  Future<void> _editPubSpec() async {
    final PubSpec pubSpec = this.pubSpec.copy();
    pubSpec.dependencies.addAll(_dependencies
        .map<String, DependencyReference>((String name, String version) {
      return MapEntry<String, DependencyReference>(
          name, HostedReference.fromJson(version));
    }));

    pubSpec.devDependencies.addAll(_devDependencies
        .map<String, DependencyReference>((String name, String version) {
      return MapEntry<String, DependencyReference>(
          name, HostedReference.fromJson(version));
    }));

    await pubSpec.save(_current);
    final File _pubFile = File(pubSpecPath);
    String _content = _pubFile.readAsStringSync();
    _content = _content.replaceAll('\"', "\'");
    final IOSink _sink = _pubFile.openWrite()..write(_content);
    await _sink.close();
  }

  Future<void> _createActions() async {
    await Utils.createAndWrite(
      path: '$actionsPath/actions.dart',
      content: '// export all actions here\n',
    );
  }

  Future<void> _createModels() async {
    final String _appState = '''
import 'package:built_value/built_value.dart';
import 'package:flutter/material.dart' hide Builder;

part 'app_state.g.dart';

abstract class AppState implements Built<AppState, AppStateBuilder> {
  factory AppState([AppStateBuilder updates(AppStateBuilder builder)]) =
      _\$AppState;

  AppState._();

  static AppState initState() {
    return new AppState((AppStateBuilder b) {
      b..navigator = GlobalKey<NavigatorState>();
    });
  }
  
  GlobalKey<NavigatorState> get navigator;
}
''';

    await Utils.createAndWrite(
        path: '$modelsPath/app_state.dart', content: _appState);

    final String _serializers = '''
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

import 'package:${pubSpec.name}/models/models.dart';

part 'serializers.g.dart';

@SerializersFor(<Type>[])
final Serializers serializers =
    (_\$serializers.toBuilder()..addPlugin(new StandardJsonPlugin())).build();
''';

    await Utils.createAndWrite(
      path: '$modelsPath/serializers.dart',
      content: _serializers,
    );

    final String _model =
        'export \'package:${pubSpec.name}/models/serializers.dart\';\nexport \'package:${pubSpec.name}/models/app_state.dart\';\n';
    //must add: 'export \'package:${pubSpec.name}/models/models.g.dart\'\n;
    await Utils.createAndWrite(
        path: '$modelsPath/models.dart', content: _model);
  }

  Future<void> _createReducers() async {
    final String _content =
        '''import 'package:${pubSpec.name}/models/models.dart';
import 'package:redux/redux.dart';

Reducer<AppState> reducer = combineReducers(<Reducer<AppState>>[]);
''';

    await Utils.createAndWrite(
        path: '$reducersPath/reducers.dart', content: _content);
  }

  Future<void> _createApi() async {
    final String _apiClient = '''import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;
import 'package:meta/meta.dart';
import 'package:${pubSpec.name}/models/models.dart';
import 'package:${pubSpec.name}/utils/utils.dart';

//class ApiError extends Error {}

enum Method {
  GET,
  POST,
  PUT,
  DELETE,
  PATCH,
}

class ApiConfig {
  const ApiConfig({
    @required this.scheme,
    @required this.host,
    this.port,
    this.scope,
  }) : assert(scheme != null && host != null,
            'Scheme, host and port cannot be null');

  final String scheme;
  final String host;
  final int port;
  final String scope;

  @override
  String toString() {
    return '\$scheme://\$host:\$port\${scope ?? ''}';
  }
}

class ApiResponse<T> extends http.Response {
  ApiResponse.from(http.Response response, this.responseKey, {this.fullType})
      : super(
          response.body,
          response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
        ) {
    _data = _getData();
    _error = _getError();
    _pagination = _getPagination();
  }

  final String responseKey;

  final FullType fullType;

  // data block
  T get data => _data;

  T _data;

  T _getData() {
    if (!isSuccess || body == null) {
      return null;
    }

    dynamic decodedBody = json.decode(body);
    if (responseKey != null) {
      decodedBody = decodedBody[responseKey];
    }

    return serializers.deserialize(
      decodedBody,
      specifiedType: fullType ?? FullType(T),
    );
  }

  // end

  // pagination block
  bool get hasPagination => _pagination != null;

  Pagination get pagination => _pagination;

  Pagination _pagination;

  Pagination _getPagination() {
    if (!isSuccess || body == null) {
      return null;
    }

    dynamic decodedBody = json.decode(body);
    if (responseKey != null) {
      decodedBody = decodedBody['pagination'];
    }

    if (decodedBody == null) {
      return null;
    }

    return serializers.deserialize(
      decodedBody,
      specifiedType: const FullType(Pagination),
    );
  }

  // end

  // error block
  ApiError _error;

  ApiError get error => _error;

  ApiError _getError() {
    if (isSuccess) {
      return null;
    }
    const String errorKey = 'errors';

    try {
      dynamic decodedBody = json.decode(body);
      decodedBody = decodedBody[errorKey];

      return serializers.deserialize(
        decodedBody,
        specifiedType: const FullType(ApiError),
      );
    } on FormatException {
      return ApiError((ApiErrorBuilder b) {
        b
          ..status = 0
          ..message = ListBuilder<String>(<String>['Something went wrong']);
      });
    }
  }

  // end

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

//ApiClient used to make HTTP/HTTPS calls
class ApiClient extends io_client.IOClient {
  ApiClient({@required this.config})
      : assert(config != null, 'Config cannot be null') {
    log.d(config.toString());
  }

  final Logger log = Logger(tag: 'ApiClient');

  final ApiConfig config;
  Map<String, String> authHeaders;

  Map<String, String> get defaultHeaders =>
      <String, String>{'Content-Type': 'application/json'};

  String buildUrl({String path, Map<String, dynamic> queryParams}) {
    final Uri uri = Uri(
      scheme: config.scheme,
      host: config.host,
      port: config.port,
      queryParameters: queryParams,
      path: '\${config.scope ?? ''}\$path',
    );

    return uri.toString();
  }

  Future<ApiResponse<R>> callJsonApi<R>({
    @required Method method,
    @required String path,
    Map<String, dynamic> queryParams,
    Map<String, String> headers,
    dynamic body,
    Encoding encoding,
    //Request data is wrapped in this key before making any request
    String requestKey,
    //Deserializer uses this key to extract deserializable object from response
    String responseKey,
    FullType fullType,
  }) async {
    final String url = buildUrl(path: path, queryParams: queryParams);

    http.Response response;

    dynamic requestBody = body;

    if (requestKey != null) {
      requestBody = <String, dynamic>{\'\$requestKey\': requestBody};
    }
    final String encodedBody =
        requestBody != null ? json.encode(requestBody) : null;

    final Map<String, String> allHeaders = <String, String>{}
      ..addAll(defaultHeaders)
      ..addAll(authHeaders ?? <String, String>{})
      ..addAll(headers ?? <String, String>{});

    switch (method) {
      case Method.GET:
        response = await get(
          url,
          headers: allHeaders,
        );
        break;
      case Method.POST:
        response = await post(
          url,
          headers: allHeaders,
          body: encodedBody,
          encoding: encoding,
        );
        break;
      case Method.PUT:
        response = await put(
          url,
          headers: allHeaders,
          body: encodedBody,
          encoding: encoding,
        );
        break;
      case Method.PATCH:
        response = await patch(
          url,
          headers: allHeaders,
          body: encodedBody,
          encoding: encoding,
        );
        break;
      case Method.DELETE:
        response = await delete(
          url,
          headers: allHeaders,
        );
        break;
      default:
        throw 'Method \$method does not exist';
    }

    log.d(\'\'\'

    ____________________________________
    URL: \${response.request.url}
    HEADERS: \${response.request.headers}
    RESPONSE : \${response.body}
    ____________________________________
    \'\'\');

    return ApiResponse<R>.from(response, responseKey, fullType: fullType);
  }
}

''';

    await Utils.createAndWrite(
      path: '$apiPath/api_client.dart',
      content: _apiClient,
    );

    final String _apiRoutes =
        '''import 'package:${pubSpec.name}/data/api/api_client.dart';

class ApiRoutes {
  static const ApiConfig debugConfig = ApiConfig(
    scheme: 'https',
    host: 'example.com',
    port: 443,
    scope: scope,
  );

  static const ApiConfig prodConfig = ApiConfig(
    scheme: 'https',
    host: 'example.com',
    port: 443,
    scope: scope,
  );

  //Scope
  static const String scope = '/v1';
}
''';

    await Utils.createAndWrite(
      path: '$apiPath/api_routes.dart',
      content: _apiRoutes,
    );
  }

  Future<void> _createService() async {
    final String _apiService = '''import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:${pubSpec.name}/data/api/api_client.dart';
import 'package:${pubSpec.name}/models/serializers.dart';

// Any api service should extend this class
abstract class ApiService {
  const ApiService({@required this.client}) : assert(client != null);

  final ApiClient client;

  Map<String, String> get defaultHeaders => client.defaultHeaders;

  Map<String, String> get authHeaders => client.authHeaders;

  Map<String, String> getAllHeaders({Map<String, String> headers}) {
    return <String, String>{}
      ..addAll(client.defaultHeaders)
      ..addAll(client.authHeaders ?? <String, String>{})
      ..addAll(headers ?? <String, String>{});
  }

  String buildUrl({String path, Map<String, dynamic> queryParams}) =>
      client.buildUrl(path: path, queryParams: queryParams);

  Map<String, dynamic> buildBodyFrom<T>(
    T data, {
    List<String> keysToRemove,
    Map<String, dynamic> dataToAdd,
    String withRootKey,
  }) {
    final Map<String, dynamic> body = serialize<T>(data);
    keysToRemove?.forEach(body.remove);
    body.addAll(dataToAdd ?? <String, dynamic>{});
    if (withRootKey != null) {
      final Map<String, dynamic> withRoot = <String, dynamic>{};
      withRoot[withRootKey] = body;
      return withRoot;
    }
    return body;
  }

  String encode(dynamic data) {
    return json.encode(data);
  }

  dynamic decode(String data) {
    return json.decode(data);
  }

  Object serializeQuery<T>(T query, {FullType fullType}) {
    if (query == null) {
      return null;
    }

    return serialize<T>(query, fullType: fullType);
  }

  Object serialize<T>(T data, {FullType fullType}) {
    return serializers.serialize(
      data,
      specifiedType: fullType ?? FullType(T),
    );
  }

  T deserialize<T>(Object data, {FullType fullType}) {
    return serializers.deserialize(
      data,
      specifiedType: fullType ?? FullType(T),
    );
  }
}
''';

    await Utils.createAndWrite(
      path: '$servicesPath/api_service.dart',
      content: _apiService,
    );
  }

  Future<void> _createData() async {
    final String _preferences =
        '''import 'package:shared_preferences/shared_preferences.dart';

class PreferencesClient {
  PreferencesClient({this.prefs});

  final SharedPreferences prefs;
}
''';

    await Utils.createAndWrite(
      path: '$dataPath/preference_client.dart',
      content: _preferences,
    );

    final String _appRepo =
        '''import 'package:flutter/material.dart';
import 'package:${pubSpec.name}/data/api/api_client.dart';
import 'package:${pubSpec.name}/data/app_repository_provider.dart';
import 'package:${pubSpec.name}/data/preference_client.dart';
import 'package:${pubSpec.name}/data/services/api_service.dart';
import 'package:${pubSpec.name}/data/services/auth_service.dart';
import 'package:${pubSpec.name}/data/services/filter_service.dart';
import 'package:${pubSpec.name}/data/services/invitation_service.dart';
import 'package:${pubSpec.name}/data/services/user_service.dart';

class AppRepository {
  AppRepository({@required this.preferencesClient, @required this.config})
      : assert(preferencesClient != null && config != null) {
    apiClient = ApiClient(config: config);
    services = <ApiService>[];
  }

  final PreferencesClient preferencesClient;
  final ApiConfig config;
  ApiClient apiClient;

  // All available services list
  List<ApiService> services;

  static AppRepository of(BuildContext context) {
    final AppRepositoryProvider provider =
        context.inheritFromWidgetOfExactType(AppRepositoryProvider);
    if (provider == null) {
      throw 'AppRepositoryProvider not found';
    }

    return provider.repository;
  }

  ApiService getService<T>() {
    return services.firstWhere((ApiService s) => s is T, orElse: () => null);
  }
}
''';

    await Utils.createAndWrite(
      path: '$dataPath/app_repository.dart',
      content: _appRepo,
    );

    final String _repoProvider = '''import 'package:flutter/material.dart';
import 'package:${pubSpec.name}/data/app_repository.dart';

class AppRepositoryProvider extends InheritedWidget {
  const AppRepositoryProvider(
      {Key key, @required this.repository, @required Widget child})
      : assert(repository != null && child != null),
        super(key: key, child: child);

  final AppRepository repository;

  @override
  bool updateShouldNotify(AppRepositoryProvider oldWidget) {
    return oldWidget.repository != repository;
  }
}
''';

    await Utils.createAndWrite(
        path: '$dataPath/app_repository_provider.dart', content: _repoProvider);
  }

  Future<void> _createMiddleware() async {
    final String _authMiddleware =
        '''import 'package:${pubSpec.name}/data/app_repository.dart';
import 'package:${pubSpec.name}/models/models.dart';
import 'package:redux/redux.dart';

class AuthMiddleware {
  final AppRepository repository;

  AuthMiddleware({this.repository});

  List<Middleware<AppState>> createAuthMiddleware() {
    return <Middleware<AppState>>[];
  }
}
''';

    await Utils.createAndWrite(
      path: '$middlewarePath/auth_middleware.dart',
      content: _authMiddleware,
    );

    final String _content =
        '''import 'package:${pubSpec.name}/data/app_repository.dart';
import 'package:${pubSpec.name}/models/models.dart';
import 'package:${pubSpec.name}/middleware/auth_middleware.dart';
import 'package:redux/redux.dart';
import 'package:redux_epics/redux_epics.dart';

EpicMiddleware<AppState> epicMiddleware(AppRepository repository) =>
    EpicMiddleware<AppState>(
      combineEpics<AppState>(
        <Epic<AppState>>[],
      ),
    );

List<Middleware<AppState>> middleware(AppRepository repository) =>
    <List<Middleware<AppState>>>[
      AuthMiddleware(repository: repository).createAuthMiddleware(),
    ].expand((List<Middleware<AppState>> list) => list).toList();\n''';

    await Utils.createAndWrite(
        path: '$middlewarePath/middleware.dart', content: _content);
  }

  Future<void> _createUtils() async {
    final String _content = '''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [TextInputFormatter] that only accepts numbers
class NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.contains(RegExp(r'\D'))) {
      final TextSelection newSelection = TextSelection(
          baseOffset: newValue.selection.baseOffset - 1,
          extentOffset: newValue.selection.extentOffset - 1);
      final String newText = newValue.text.replaceAll(RegExp(r'\D'), '');
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
    debugPrint('D/\$tag : \$log');
  }

  void i(String log) {
    debugPrint('I/\$tag : \$log');
  }

  void w(String log) {
    print('W/\$tag Warning ===========================================================');
    debugPrint(log);
    print('==========================================================================');
  }

  void e(String log) {
    print('E/\$tag ----------------------Error----------------------');
    debugPrint(log);
    print('---------------------------------------------------------');
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
''';

    await Utils.createAndWrite(
      path: '$utilsPath/utils.dart',
      content: _content,
    );

    final String _package = ReCase(pubSpec.name).pascalCase;

    final String _assets = '''class ${_package}Assets {
  ${_package}Assets._();
}
''';

    await Utils.createAndWrite(
      path: '$utilsPath/assets.dart',
      content: _assets,
    );

    final String _icons = '''import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ${_package}Icons {
  ${_package}Icons._();
}
''';

    await Utils.createAndWrite(
      path: '$utilsPath/icons.dart',
      content: _icons,
    );
  }

  Future<void> _createViews() async {
    await Utils.createAndWrite(path: '$viewsPath/login/login_page.dart');
    await Utils.createAndWrite(path: '$viewsPath/home/home_page.dart');

    final String _initPage = '''import 'package:flutter/material.dart';

class InitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InitPage'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Text('InitPage'),
      ),
    );
  }
}
''';

    await Utils.createAndWrite(
      path: '$viewsPath/init_page.dart',
      content: _initPage,
    );
  }

//  Future<void> _createRoutes() async {
//    final String _routes = '''library router;
//
//import 'package:flutter/material.dart';
//import 'package:${pubSpec.name}/utils/utils.dart';
//
//// ignore: avoid_classes_with_only_static_members
//class AppRoutes {
//  static const String _initialRoute = '/';
//
//  static AppRoute initialRoute = AppRoute(name: _initialRoute);
//}
//
//typedef AppRouteHandler = Widget Function(Map<String, String> params);
//
//class AppRoute {
//  static RegExp variablePattern = RegExp(r'{(\\w+)}');
//  final String name;
//  final RegExp pattern;
//  final bool fullScreenDialog;
//  final bool maintainState;
//  final Logger log;
//
//  AppRoute({
//    @required this.name,
//    this.fullScreenDialog = false,
//    this.maintainState = true,
//  })  : pattern = RegExp(
//            '\${name == '/' ? r'^/\$' : name.replaceAll(variablePattern, r'(.*[^/])')}'),
//        log = Logger(tag: 'AppRoute');
//
//  Map<String, String> getParams(String url) {
//    final RegExp pathPattern =
//        RegExp(name.replaceAll(variablePattern, variablePattern.pattern));
//    final Match key = pathPattern.firstMatch(name);
//    final Match value = pattern.firstMatch(url);
//    final Map<String, String> params = <String, String>{};
//    for (int i = 1; i <= key.groupCount; i++) {
//      params[key.group(i)] = value.group(i);
//    }
//    log.d('Path: \$name ---> Params: \$params');
//    return params.isEmpty ? null : params;
//  }
//
//  String withArguments(List<String> arguments) {
//    if (arguments == null) {
//      return name;
//    }
//    String newPath = name;
//    final List<Match> matches = variablePattern.allMatches(name).toList();
//    if (matches.length > arguments.length) {
//      throw Exception('Route variables and argument count mismatch');
//    }
//    for (int i = 0; i < matches.length; i++) {
//      newPath = newPath.replaceFirst(variablePattern, arguments[i]);
//    }
//    return newPath;
//  }
//}
//
//class AppRouter {
//  final Map<AppRoute, AppRouteHandler> routeMap;
//  final List<AppRoute> routes;
//  final Logger log = Logger(tag: 'AppRouter');
//
//  AppRouter({@required this.routeMap}) : routes = routeMap.keys.toList();
//
//  Route<dynamic> onGenerateRoute(RouteSettings settings) {
//    final AppRoute route = routes.firstWhere(
//      (AppRoute route) {
//        return route.pattern.hasMatch(settings.name) ||
//            route.name == settings.name;
//      },
//      orElse: () => null,
//    );
//
//    if (route == null) {
//      throw Exception('Route Not Found');
//    }
//
//    final RouteSettings routeSettings =
//        route.name == '/' ? settings.copyWith(isInitialRoute: true) : settings;
//
//    final Map<String, String> params =
//        route.name == settings.name ? null : route.getParams(settings.name);
//
//    return MaterialPageRoute<dynamic>(
//      fullscreenDialog: route.fullScreenDialog,
//      settings: routeSettings,
//      maintainState: route.maintainState,
//      builder: (BuildContext context) {
//        return routeMap[route](params);
//      },
//    );
//  }
//}
//''';
//
//    await Utils.createAndWrite(
//      path: '$libPath/routes.dart',
//      content: _routes,
//    );
//  }

  Future<void> _createTheme() async {
    final String _theme = '''library theme;

import 'package:flutter/material.dart';

final ThemeData themeData = ThemeData.fallback();
''';

    await Utils.createAndWrite(
      path: '$libPath/theme.dart',
      content: _theme,
    );
  }

  Future<void> _editMain() async {
    final String _package = ReCase(pubSpec.name).pascalCase;

    final String _main = '''import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:${pubSpec.name}/data/app_repository.dart';
import 'package:${pubSpec.name}/data/preference_client.dart';
import 'package:${pubSpec.name}/middleware/middleware.dart';
import 'package:${pubSpec.name}/models/models.dart';
import 'package:${pubSpec.name}/reducers/reducers.dart';
import 'package:${pubSpec.name}/theme.dart';
import 'package:${pubSpec.name}/views/init_page.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final AppRepository repository = AppRepository(
    preferencesClient: PreferencesClient(prefs: prefs),
  );

  runApp(
    $_package(
      repository: repository,
    ),
  );
}

class $_package extends StatefulWidget {
  final Store<AppState> store;

  $_package({Key key, AppRepository repository})
      : store = Store<AppState>(
          reducer,
          middleware: middleware(repository),
          initialState: AppState.initState(),
        ),
        super(key: key);

  @override
  _${_package}State createState() => _${_package}State();
}

class _${_package}State extends State<$_package> {
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
        title: '$_package',
        theme: themeData,
        home: InitPage(),
      ),
    );
  }
}
''';

//import 'package:${pubSpec.name}/routes.dart';

//    '''
//            onGenerateRoute: AppRouter(
//          routeMap: AppNavigator(
//            store: store,
//            navigator: store.state.navigator,
//          ).routeMap,
//        ).onGenerateRoute,
//    '''
//'''
//
//class AppNavigator {
//  final Store<AppState> store;
//  final GlobalKey<NavigatorState> navigator;
//
//  AppNavigator({this.store, this.navigator});
//
//  Map<AppRoute, AppRouteHandler> get routeMap => _getRouteMap();
//
//  Map<AppRoute, AppRouteHandler> _getRouteMap() {
//    return <AppRoute, AppRouteHandler>{
//      AppRoutes.initialRoute: (Map<String, String> params) {
//        return InitPage();
//      },
//    };
//  }
//}
//''';

    await Utils.createAndWrite(
      path: '$libPath/main.dart',
      content: _main,
    );
  }
}
