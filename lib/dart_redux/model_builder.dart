import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'package:redux_utils/parser/parser.dart';
import 'package:redux_utils/utils.dart';

Directory _current = Directory.current;

class ModelBuilder {
  final String sourcePath;
  final String modelsPath;
  final String metaPath;
  ModelParser parser;
  String pubSpecPath;
  PubSpec pubSpec;

  ModelBuilder()
      : sourcePath = _current.path,
        modelsPath = '${_current.path}/lib/models',
        metaPath = '${_current.path}/meta';

  Future<void> initialize() async {
    final String _pubSpecPath = '$sourcePath/pubspec.yaml';

    bool _pubSpecExists = Utils.fileExists(path: _pubSpecPath);

    if (!_pubSpecExists) {
      throw SetupError(message: 'file not found: pubspec.yaml');
    } else {
      pubSpecPath = _pubSpecPath;
    }
    final PubSpec _pub = await PubSpec.load(_current);
    parser = ModelParser(packageName: _pub.name);
    pubSpec = _pub;
  }

  Future<void> generateModelFromJson() async {
    final Map<String, dynamic> data = (json.decode(File('$metaPath/models.json')
        .readAsStringSync()
        .replaceAll(RegExp('//.*\n'), '')) as Map<String, dynamic>);

    String models = '';

    for (String model in data.keys) {
      String modelCode = parser.generateModel(json.encode(data[model]), model);
      if (modelCode != null) {
        await Utils.createAndWrite(
          path: '$modelsPath/${ReCase(model).snakeCase}.dart',
          content: modelCode,
        );
        models = models +
            'export \'package:${pubSpec.name}/models/${ReCase(model).snakeCase}.dart\';\n';
      }
    }

    await Utils.createAndWrite(
      path: '$modelsPath/models.g.dart',
      content: models,
    );
  }
}
