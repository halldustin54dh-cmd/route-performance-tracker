import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EvidenceStorageService {
  const EvidenceStorageService();

  Future<String> persistImage({
    required String sourcePath,
    required String suggestedBaseName,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory(p.join(docs.path, 'route_evidence'));
    if (!await evidenceDir.exists()) await evidenceDir.create(recursive: true);

    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath).toLowerCase();
    var candidate = p.join(evidenceDir.path, '$suggestedBaseName$extension');
    var counter = 2;
    while (await File(candidate).exists()) {
      candidate = p.join(evidenceDir.path, '${suggestedBaseName}_$counter$extension');
      counter++;
    }
    return File(sourcePath).copy(candidate).then((file) => file.path);
  }
}
