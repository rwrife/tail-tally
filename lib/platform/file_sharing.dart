/// Platform bridge for user-initiated file export/import (issue #5).
///
/// Follows the gateway-behind-interface pattern proven in
/// `lib/platform/notifications.dart`: everything that touches the system
/// file picker lives behind [FileGateway], so backup/restore services and
/// the privacy UI are fully testable without platform channels.
library;

import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Contract implemented by [PluginFileGateway].
abstract class FileGateway {
  /// Ask the user where to write [fileName] containing [content].
  /// Returns true only when the user chose a location and the write
  /// succeeded; false on cancel or failure.
  Future<bool> saveTextFile({
    required String fileName,
    required String content,
    required String mimeType,
  });

  /// Ask the user to pick one text file (backup import). Returns null when
  /// cancelled, otherwise the decoded contents.
  Future<String?> openTextFile();
}

/// In-memory gateway used in tests and as a no-op fallback on unsupported
/// platforms: saves report [saveResult] (cancel by default), opens return
/// a queued payload.
class NoopFileGateway implements FileGateway {
  NoopFileGateway({this.openPayload, this.saveResult = false});

  /// Returned by [openTextFile] — tests stage the "picked file" here.
  String? openPayload;

  /// What [saveTextFile] reports: false = user cancelled / no destination.
  bool saveResult;

  final List<({String fileName, String content, String mimeType})> saved = [];

  @override
  Future<bool> saveTextFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    saved.add((fileName: fileName, content: content, mimeType: mimeType));
    return saveResult;
  }

  @override
  Future<String?> openTextFile() async => openPayload;
}

/// Real gateway backed by the system file picker (file_picker plugin).
class PluginFileGateway implements FileGateway {
  const PluginFileGateway();

  @override
  Future<bool> saveTextFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final savedUri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    // saveFile with `bytes` performs the write itself on mobile; a null
    // return means the user cancelled or the write was refused.
    return savedUri != null;
  }

  @override
  Future<String?> openTextFile() async {
    final picked = await FilePicker.pickFile(allowedExtensions: const ['json']);
    if (picked == null) return null;
    // Mobile picks surface a cached file path; other platforms only
    // expose bytes. Read whichever the plugin provides.
    final path = picked.path;
    if (path != null) {
      return File(path).readAsStringSync();
    }
    final bytes = await picked.readAsBytes();
    return utf8.decode(bytes);
  }
}
