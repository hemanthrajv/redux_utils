import 'package:redux_utils/dart_redux/dart_redux.dart';
import 'package:redux_utils/dart_redux/model_builder.dart';
import 'package:redux_utils/utils.dart';

void main(List<String> arguments) async {
  try {
    if (arguments.contains('--setup')) {
      final DartRedux _redux = DartRedux();
      await _redux.initialize();
      await _redux.setup();
    }
    if (arguments.contains('--generate-models')) {
      final ModelBuilder _modelBuilder = ModelBuilder();
      await _modelBuilder.initialize();
      await _modelBuilder.generateModelFromJson();
    }
  } catch (e) {
    if (e is SetupError) {
      print(e.message);
    } else {
      throw e;
    }
  }
}
