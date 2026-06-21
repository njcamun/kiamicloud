import 'package:flutter/material.dart';

import '../../app/kiami_app_keys.dart';
import '../../api/kiami_api_exception.dart';
import '../files/providers/files_providers.dart';
import 'upload_debug.dart';
import 'upload_failure_report.dart';
import '../../widgets/upload_error_report_dialog.dart';

/// Mostra o diálogo de relatório — tenta navigator raiz e contexto local.
Future<void> presentUploadDiagnostic(
  BuildContext? context, {
  required String report,
  dynamic ref,
}) async {
  if (ref != null) {
    publishUploadDiagnostic(ref, report);
  }

  BuildContext? dialogContext = kiamiRootNavigatorKey.currentContext;
  if (dialogContext == null || !dialogContext.mounted) {
    dialogContext = context;
  }

  if (dialogContext == null || !dialogContext.mounted) {
    UploadDebug.log('diagnóstico guardado — abra o banner no dashboard');
    return;
  }

  await showUploadErrorReportDialog(dialogContext, report: report);
}

/// Mensagem para erros locais (picker, bytes) — não tratar como falha de API.
String uploadHandlerErrorMessage(Object error) {
  if (error is KiamiApiException) return kiamiApiErrorMessage(error);
  final text = error.toString().trim();
  if (text.isEmpty) return 'Erro ao preparar o upload.';
  return text;
}

String buildEarlyUploadReport({
  required String stage,
  required String message,
  Object? error,
  StackTrace? stackTrace,
  String fileName = '—',
  int fileSizeBytes = 0,
}) {
  if (error != null) {
    return buildUploadFailureReport(
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      error: error,
      stackTrace: stackTrace,
      stage: stage,
    );
  }

  return UploadFailureException(
    stage: stage,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    cause: message,
    stackTrace: stackTrace,
  ).toReport();
}
