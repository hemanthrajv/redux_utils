import 'package:example/data/app_repository.dart';
import 'package:example/models/models.dart';
import 'package:redux/redux.dart';

class AuthMiddleware {
  final AppRepository repository;

  AuthMiddleware({this.repository});

  List<Middleware<AppState>> createAuthMiddleware() {
    return <Middleware<AppState>>[];
  }
}
