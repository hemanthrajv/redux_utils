import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

class ModelBuilder {
  method() {
    final Class app = Class((b) {
      b
        ..name = 'App'
        ..extend = refer('StatefulWidget')
        ..constructors = ListBuilder<Constructor>(<Constructor>[
          Constructor((b) {
            b
              ..constant = true
              ..optionalParameters = ListBuilder<Parameter>([
                Parameter((b) {
                  b
                    ..name = 'key'
                    ..named = true
                    ..type = TypeReference((b) {
                      b..symbol = 'Key';
                    });
                })
              ]);
          }),
        ])
        ..methods = ListBuilder(<Method>[
          Method((b) {
            b
              ..name = 'createState'
              ..annotations = ListBuilder<Expression>(
                [
                  CodeExpression(
                    Code('override'),
                  ),
                ],
              )
              ..lambda = true
              ..returns = Reference('_AppState')
              ..body = Code('_AppState()');
          })
        ]);
    });
    final emitter = DartEmitter();
    final String formatted = DartFormatter().format('${app.accept(emitter)}');
  }
}
