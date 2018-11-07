import 'dart:async';
import 'dart:io';

class SetupError implements Exception {
  final String message;

  const SetupError({this.message});
}

class Utils {
  static Future<bool> copy(Directory source, Directory destination) async {
    String processName = Platform.isWindows ? "robocopy" : "cp";
    List<String> args;
    if (Platform.isWindows)
      args = [source.absolute.path, destination.absolute.path, '/E', '/B'];
    else
      args = ['-r', source.absolute.path, destination.absolute.path];
    Process cp = await Process.start(processName, args);
    // For some reason, robocopy won't copy directories unless you listen to stdout
    cp.stdout.listen(null);
    stderr.addStream(cp.stderr);
    int code = await cp.exitCode;
    return (Platform.isWindows && code <= 1) ||
        (!Platform.isWindows && code == 0);
  }

  static bool fileExists({String path}) {
    return FileSystemEntity.typeSync(path) == FileSystemEntityType.file;
  }

  static Future<File> createIfNotExists({String path}) async {
    File _file;
    final bool _exists = Utils.fileExists(path: path);
    if (_exists) {
      _file = File(path);
    } else {
      _file = File(path);
      await _file.createSync(recursive: true);
    }

    return _file;
  }

  static Future<void> createAndWrite({String path, String content}) async {
    final File _file = await Utils.createIfNotExists(path: path);
    final IOSink _sink = _file.openWrite();
    _sink.write(content ?? '');
    await _sink.close();
  }
}
