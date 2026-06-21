import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs de upload — na Web aparecem na consola do browser (F12), não no PowerShell.
abstract final class UploadDebug {
  static void log(String message) {
    debugPrint('[KiamiUpload] $message');
  }

  static void fail(String stage, Object error, {StackTrace? stackTrace}) {
    log('FALHA fase=$stage → $error');
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n').take(8);
      for (final line in lines) {
        log('  $line');
      }
    }
  }
}

/// Último relatório de diagnóstico — banner visível no dashboard.
final lastUploadDiagnosticProvider = StateProvider<String?>((ref) => null);

void publishUploadDiagnostic(dynamic ref, String report) {
  UploadDebug.log('diagnóstico publicado (${report.length} chars)');
  ref.read(lastUploadDiagnosticProvider.notifier).state = report;
}
