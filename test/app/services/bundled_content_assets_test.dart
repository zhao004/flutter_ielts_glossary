import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/services/content/content_database_verifier.dart';
import 'package:flutter_ielts_glossary/app/services/content/flutter_content_asset_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('正式资产包包含冻结来源的完整词库与匹配校验和', () async {
    final reader = FlutterContentAssetReader();
    final manifest = const ContentDatabaseVerifier().parseManifestBytes(
      await reader.readManifestBytes(),
    );
    var databaseBytes = 0;
    final digest = await sha256
        .bind(
          reader.readDatabaseBytes().map((chunk) {
            databaseBytes += chunk.length;
            return chunk;
          }),
        )
        .first;

    expect(
      manifest.sourceRepository,
      'https://github.com/chunsi-w/ielts-vocab-cloudflare',
    );
    expect(manifest.sourceRevision, '2278d049dacca60181aea4cba3deae1546a63381');
    expect(manifest.wordCount, 34211);
    expect(manifest.sentenceCount, 76332);
    expect(databaseBytes, manifest.databaseBytes);
    expect(digest.toString(), manifest.databaseSha256);
  });
}
