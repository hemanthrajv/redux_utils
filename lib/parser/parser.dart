import 'dart:convert';

import 'package:built_collection/src/list.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:redux_utils/parser/root.dart';

class ModelParser {
  ModelParser({this.packageName});

  final String packageName;

  final DartFormatter _formatter = DartFormatter();

  String generateModel(String jsonData, String name) {
    dynamic data = json.decode(jsonData);

    List<Subtype> fields = _getTypedClassFields(data);

    String model = _generateClass(fields, name);

    return model;
  }

  String _generateClass(List<Subtype> fields, String name) {
    final ReCase reCase = ReCase(name);
    final Class classObj = Class(
      (b) => b
        ..abstract = true
        ..implements.add(
          Reference('Built<${reCase.pascalCase}, ${reCase.pascalCase}Builder>'),
        )
        ..constructors.add(Constructor((b) => b..name = '_'))
        ..constructors.add(
          Constructor(
            (b) => b
              ..factory = true
              ..redirect = refer(' _\$${reCase.pascalCase}')
              ..requiredParameters.add(
                Parameter((b) => b
                  ..defaultTo = Code('= _\$${reCase.pascalCase}')
                  ..name = '[updates(${reCase.pascalCase}Builder b)]'),
              ),
          ),
        )
        ..name = reCase.pascalCase
        ..methods = _getFields(fields)
        ..methods.add(
          Method(
            (b) => b
              ..name = 'toJson'
              ..returns = Reference('String')
              ..body = Code(
                  'return json.encode(serializers.serializeWith(${reCase.pascalCase}.serializer, this));'),
          ),
        )
        ..methods.add(
          Method(
            (b) => b
              ..name = 'fromJson'
              ..static = true
              ..requiredParameters.add(Parameter((b) => b
                ..name = 'jsonString'
                ..type = Reference('String')))
              ..returns = Reference(reCase.pascalCase)
              ..body = Code(
                'return serializers.deserializeWith(${reCase.pascalCase}.serializer, json.decode(jsonString));',
              ),
          ),
        )
        ..methods.add(
          Method(
            (b) => b
              ..type = MethodType.getter
              ..name = 'serializer'
              ..static = true
              ..lambda = true
              ..returns = Reference('Serializer<${reCase.pascalCase}>')
              ..body = Code('_\$${ReCase(name).camelCase}Serializer'),
          ),
        ),
    );

    String classString = classObj.accept(DartEmitter()).toString();

    final String modelImport =
        packageName != null && fields.any((s) => s.hasDependencies)
            ? "import 'package:$packageName/models/models.dart';\n"
            : '';
    final String serializerImport =
        "import 'package:${packageName}/models/serializers.dart';";

    String header = """
      library ${ReCase(name).snakeCase};
      import 'dart:convert';
      
      import 'package:built_collection/built_collection.dart';
      import 'package:built_value/built_value.dart';
      import 'package:built_value/serializer.dart';
      
      $modelImport
      $serializerImport
      
      part '${ReCase(name).snakeCase}.g.dart';
    
    """;

    String output = _formatter.format(header + classString);

    return output;
  }

  ListBuilder<Method> _getFields(List<Subtype> fields) {
    return ListBuilder(
      fields.map(
        (Subtype s) => Method((b) => b
          ..name = ReCase(s.name).camelCase
          ..returns = _getDartType(s)
          ..annotations.addAll(_getAnnotations(s))
          ..type = MethodType.getter),
      ),
    );
  }

  List<Expression> _getAnnotations(Subtype s) {
    final List<Expression> _annotations = <Expression>[];

    _annotations.add(
      CodeExpression(
        Code("BuiltValueField(wireName: '${s.name}')"),
      ),
    );

    if (s.isNullable) {
      _annotations.add(CodeExpression(Code('nullable')));
    }

    return _annotations;
  }

  Reference _getDartType(Subtype subtype) {
    JsonType type = subtype.type;
    switch (type) {
      case JsonType.INT:
        return Reference('int');
      case JsonType.DOUBLE:
        return Reference('double');
      case JsonType.BOOL:
        return Reference('bool');
      case JsonType.STRING:
        return Reference('String');
      case JsonType.MAP:
        return Reference(ReCase(subtype.name).pascalCase);
      case JsonType.LIST:
        return Reference('BuiltList<${_getDartTypeFromJsonType(subtype)}>');
      default:
        return Reference('dynamic');
    }
  }

  String _getDartTypeFromJsonType(Subtype subtype) {
    var type = subtype.listType;
    switch (type) {
      case JsonType.INT:
        return 'int';
      case JsonType.DOUBLE:
        return 'double';
      case JsonType.STRING:
        return 'String';
      case JsonType.MAP:
        return ReCase(subtype.name).pascalCase;
      default:
        return 'dynamic';
    }
  }

  List<Subtype> _getTypedClassFields(decode) {
    List<Subtype> topLevelClass = [];
    var toDecode;

    if (decode is List) {
      toDecode = decode[0];
    } else {
      toDecode = decode;
    }

//  if (toDecode is Map) {
    toDecode.forEach((key, val) {
      topLevelClass.add(_returnType(key, val));
    });
//  }
    return topLevelClass;
  }

  Subtype _returnType(key, val) {
    if (val is String)
      return Subtype(key, JsonType.STRING, val);
    else if (val is int)
      return Subtype(key, JsonType.INT, val);
    else if (val is num)
      return Subtype(key, JsonType.DOUBLE, val);
    else if (val is bool)
      return Subtype(key, JsonType.BOOL, val);
    else if (val is List) {
      return Subtype(key, JsonType.LIST, val, listType: _returnJsonType(val));
    } else if (val is Map) {
      return Subtype(key, JsonType.MAP, val);
    } else
      throw ArgumentError('Cannot resolve JSON-encodable type for $val.');
  }

  JsonType _returnJsonType(List list) {
    var item = list[0];
    print('got item $item');
    if (item is String)
      return JsonType.STRING;
    else if (item is int)
      return JsonType.INT;
    else if (item is num)
      return JsonType.DOUBLE;
    else if (item is bool)
      return JsonType.BOOL;
    else if (item is Map)
      return JsonType.MAP;
    else
      throw ArgumentError('Cannot resolve JSON-encodable type for $item.');
  }
}
