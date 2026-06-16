// Sincroniza branding/assets sem PowerShell.
// Na raiz do projeto: dart run tool/sync_branding.dart

import 'dart:io';

const _categoryFiles = [
  'img.png',
  'img_dark.png',
  'video.png',
  'video_dark.png',
  'audio.png',
  'audio_dark.png',
  'doc.png',
  'doc_dark.png',
  'outro.png',
  'outro_dark.png',
  'unknow.png',
  'unknow_dark.png',
];

const _brandingSkip = {
  'logo.png',
  'Logo_barra.png',
  'icon.png',
  'audio.png',
  'doc.png',
  'img.png',
  'outro.png',
  'unknow.png',
  'video.png',
};

/// icon.png na origem e copiado com estes nomes no destino (app + upload).
const _brandingAliases = {
  'icon.png': ['icone.png', 'icon_claro.png'],
};

/// Origem em branding/assets/ -> destino estável no bundle Flutter.
const _legalSourceCandidates = [
  'KIAMICLOUD - Documentacao legal.pdf',
  'KiamiCloud - Documentacao Legal Oficial.pdf',
  'KiamiCloud_Documentacao_Legal_Completa.pdf',
];
const _legalBundleName = 'legal_documentation.pdf';

void main() {
  final root = _findProjectRoot();
  final sep = Platform.pathSeparator;
  final source = Directory('${root.path}${sep}branding${sep}assets');
  final destBranding = Directory(
    '${root.path}${sep}packages${sep}kiamicloud_core${sep}assets${sep}branding',
  );
  final destCategories = Directory(
    '${root.path}${sep}packages${sep}kiamicloud_core${sep}assets${sep}categories',
  );

  stdout.writeln('KiamiCloud — sync branding (Dart)');
  stdout.writeln('  Raiz: ${root.path}');
  stdout.writeln('  Origem: ${source.path}');
  stdout.writeln('');

  if (!source.existsSync()) {
    stderr.writeln('ERRO: Crie a pasta branding/assets/');
    exit(1);
  }

  destBranding.createSync(recursive: true);
  destCategories.createSync(recursive: true);

  var copied = 0;
  stdout.writeln('Branding -> assets/branding');
  for (final entity in source.listSync().whereType<File>()) {
    final name = entity.uri.pathSegments.last;
    if (_categoryFiles.contains(name)) continue;
    if (_brandingSkip.contains(name)) {
      stdout.writeln('  SKIP $name (nao usado em branding/)');
      continue;
    }
    entity.copySync('${destBranding.path}$sep$name');
    copied++;
    stdout.writeln('  OK  $name');
  }

  stdout.writeln('');
  stdout.writeln('Categories -> assets/categories');
  for (final name in _categoryFiles) {
    final src = File('${source.path}$sep$name');
    if (!src.existsSync()) continue;
    src.copySync('${destCategories.path}$sep$name');
    copied++;
    stdout.writeln('  OK  $name');
  }

  for (final legacy in _brandingSkip) {
    final stale = File('${destBranding.path}$sep$legacy');
    if (stale.existsSync()) {
      stale.deleteSync();
      stdout.writeln('  DEL $legacy (removido de assets/branding)');
    }
  }

  stdout.writeln('');
  stdout.writeln('Aliases (icon.png -> icone.png, icon_claro.png)');
  for (final entry in _brandingAliases.entries) {
    final src = File('${source.path}${sep}${entry.key}');
    if (!src.existsSync()) {
      stdout.writeln('  SKIP ${entry.key} (nao encontrado)');
      continue;
    }
    for (final destName in entry.value) {
      src.copySync('${destBranding.path}$sep$destName');
      copied++;
      stdout.writeln('  OK  ${entry.key} -> $destName');
    }
  }

  const staleLegal = 'KiamiCloud_Documentacao_Legal_Completa.pdf';
  final staleLegalFile = File('${destBranding.path}$sep$staleLegal');
  if (staleLegalFile.existsSync()) {
    staleLegalFile.deleteSync();
    stdout.writeln('  DEL $staleLegal (substituido pelo PDF legal actual)');
  }

  stdout.writeln('');
  stdout.writeln('Documento legal -> $_legalBundleName');
  var legalCopied = false;
  for (final name in _legalSourceCandidates) {
    final src = File('${source.path}$sep$name');
    if (!src.existsSync()) continue;
    src.copySync('${destBranding.path}$sep$_legalBundleName');
    copied++;
    legalCopied = true;
    stdout.writeln('  OK  $name -> $_legalBundleName');
    break;
  }
  if (!legalCopied) {
    stderr.writeln(
      '  AVISO: Nenhum PDF legal encontrado em branding/assets/.',
    );
  }

  stdout.writeln('');
  stdout.writeln('Concluido: $copied ficheiro(s).');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}${Platform.pathSeparator}melos.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}
