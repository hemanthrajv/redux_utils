class Root {
  final String title;

  final Map<String, Subtype> jsonTree;

  Root(this.title, this.jsonTree);

  @override
  String toString() {
    return 'Root{title: $title, jsonTree: $jsonTree}';
  }
}

class Subtype {
  Subtype(String name, this.type, this.value, {this.listType}) {
    this._isNullable = name.contains('?');
    this._hasDependencies = name.contains('\$');
    this._name = _refactorName(name);
  }

  String _name;
  final JsonType type;
  final JsonType listType;
  bool _isNullable;
  bool _hasDependencies;
  final dynamic value;

  String get name => _name;

  bool get isNullable => _isNullable;

  bool get hasDependencies => _hasDependencies;

  String _refactorName(String name) {
    return name.replaceAll('?', '').replaceAll('\$', '');
  }

  @override
  String toString() {
    return 'Subtype{name: $name, type: $type, listType: $listType, value: $value}';
  }
}

enum JsonType { INT, DOUBLE, BOOL, STRING, MAP, LIST }
