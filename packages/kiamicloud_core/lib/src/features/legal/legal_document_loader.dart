import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import '../../assets/kiami_assets.dart';

/// Carrega o PDF legal a partir do bundle do pacote [kiamicloud_core].
abstract final class LegalDocumentLoader {
  static const List<String> _relativeCandidates = [
    KiamiAssets.legalDocumentPdf,
    'assets/branding/KIAMICLOUD - Documentacao legal.pdf',
    'assets/branding/KiamiCloud - Documentacao Legal Oficial.pdf',
  ];

  static Future<PdfDocument> open() async {
    Object? lastError;
    for (final relative in _relativeCandidates) {
      final keys = <String>[
        KiamiAssets.packageAssetPath(relative),
        relative,
      ];
      for (final key in keys) {
        try {
          final data = await rootBundle.load(key);
          final bytes = data.buffer.asUint8List();
          if (bytes.isEmpty) continue;
          return PdfDocument.openData(bytes);
        } catch (e) {
          lastError = e;
        }
      }
    }
    throw StateError(
      'Documento legal não encontrado no bundle.${lastError != null ? ' ($lastError)' : ''}',
    );
  }

  /// Verifica se o PDF está disponível (útil em testes).
  static Future<bool> isBundled() async {
    try {
      await open();
      return true;
    } catch (_) {
      return false;
    }
  }
}
