import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PmtilesManager {
  static const String assetPmtilesPath =
      'assets/poc/maps/lima_callao_z14.pmtiles';
  static const String assetStylePath =
      'assets/poc/styles/emergency_geometric_style.json';

  static File? _localPmtilesFile;
  static Directory? _localFontsDir;
  static String? _localStyleJson;

  static const List<String> fontStacks = [
    'Noto Sans Regular',
    'Noto Sans Bold',
  ];

  static const List<String> fontRanges = ['0-255.pbf', '256-511.pbf'];

  /// Ensures the PMTiles asset is unpacked to private app storage for direct random access (mmap)
  /// by MapLibre Native without needing any local loopback HTTP server.
  static Future<File> prepareLocalPmtiles() async {
    if (_localPmtilesFile != null && await _localPmtilesFile!.exists()) {
      return _localPmtilesFile!;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final targetFile = File('${docsDir.path}/lima_callao_z14.pmtiles');

    // Only copy if not present or size mismatch
    if (!await targetFile.exists() || await targetFile.length() == 0) {
      final byteData = await rootBundle.load(assetPmtilesPath);
      final buffer = byteData.buffer;
      await targetFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
    }

    _localPmtilesFile = targetFile;
    return targetFile;
  }

  /// Ensures offline font glyphs PBFs are unpacked to private app storage.
  /// Generates both raw folder names and URL-encoded folder names for MapLibre C++ compatibility.
  static Future<Directory> prepareLocalFonts() async {
    if (_localFontsDir != null && await _localFontsDir!.exists()) {
      return _localFontsDir!;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final fontsBaseDir = Directory('${docsDir.path}/fonts');
    if (!await fontsBaseDir.exists()) {
      await fontsBaseDir.create(recursive: true);
    }

    for (final fontStack in fontStacks) {
      final stackDir = Directory('${fontsBaseDir.path}/$fontStack');
      if (!await stackDir.exists()) {
        await stackDir.create(recursive: true);
      }

      final encodedStack = Uri.encodeComponent(fontStack);
      final encodedStackDir = Directory('${fontsBaseDir.path}/$encodedStack');
      if (encodedStack != fontStack && !await encodedStackDir.exists()) {
        await encodedStackDir.create(recursive: true);
      }

      for (final range in fontRanges) {
        final targetFile = File('${stackDir.path}/$range');
        final encodedTargetFile = File('${encodedStackDir.path}/$range');

        if (!await targetFile.exists() || await targetFile.length() == 0) {
          final assetPath = 'assets/poc/fonts/$fontStack/$range';
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
          await targetFile.writeAsBytes(bytes, flush: true);
          if (encodedStack != fontStack) {
            await encodedTargetFile.writeAsBytes(bytes, flush: true);
          }
        }
      }
    }

    _localFontsDir = fontsBaseDir;
    return fontsBaseDir;
  }

  /// Generates the self-contained offline style JSON string pointing directly to `pmtiles://file://${path}`
  /// and `glyphs: file://${fontsPath}/{fontstack}/{range}.pbf`.
  /// Zero HTTP/HTTPS external requests.
  static Future<String> getOfflineStyleString() async {
    if (_localStyleJson != null) return _localStyleJson!;

    final pmtilesFile = await prepareLocalPmtiles();
    final fontsDir = await prepareLocalFonts();
    final rawStyleStr = await rootBundle.loadString(assetStylePath);
    final styleMap = json.decode(rawStyleStr) as Map<String, dynamic>;

    // Formulate fully qualified native pmtiles file URI
    // e.g. pmtiles://file:///data/user/0/... or pmtiles://file:///var/mobile/...
    final absPath = pmtilesFile.path;
    final fileUri = absPath.startsWith('/')
        ? 'file://$absPath'
        : 'file:///$absPath';
    final pmtilesUri = 'pmtiles://$fileUri';

    // Inject exact file URI into source
    styleMap['sources']['lima_callao']['url'] = pmtilesUri;

    // Inject local glyphs file URI
    final absFontsPath = fontsDir.path;
    final fontsUri = absFontsPath.startsWith('/')
        ? 'file://$absFontsPath'
        : 'file:///$absFontsPath';
    styleMap['glyphs'] = '$fontsUri/{fontstack}/{range}.pbf';

    _localStyleJson = json.encode(styleMap);
    return _localStyleJson!;
  }

  /// Resets cached style in memory (useful for tests or hot reloads)
  static void resetCache() {
    _localStyleJson = null;
  }
}
