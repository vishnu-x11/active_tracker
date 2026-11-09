import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ImageSharer {
  Future<void> sharePng(Uint8List bytes, {required String name, String? text});
}

class SharePlusImageSharer implements ImageSharer {
  const SharePlusImageSharer();

  @override
  Future<void> sharePng(Uint8List bytes, {required String name, String? text}) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '$name.png'));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ),
    );
  }
}

final imageSharerProvider = Provider<ImageSharer>((ref) => const SharePlusImageSharer());
