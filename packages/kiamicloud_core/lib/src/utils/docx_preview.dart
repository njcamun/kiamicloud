import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'file_category.dart';

/// Limite para pré-visualização de Word (.docx).
const int kDocxPreviewMaxBytes = 20 * 1024 * 1024;

bool canPreviewDocxFileName(String fileName) =>
    fileExtensionOf(fileName) == 'docx';

bool canPreviewDocxFile(String fileName, int sizeBytes) =>
    canPreviewDocxFileName(fileName) && sizeBytes <= kDocxPreviewMaxBytes;

/// Extrai o texto de um .docx (zip → word/document.xml → parágrafos).
/// Devolve `null` se o ficheiro não for um docx legível.
String? extractDocxText(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.findFile('word/document.xml');
    if (entry == null) return null;

    final xmlStr = utf8.decode(
      entry.content as List<int>,
      allowMalformed: true,
    );
    final doc = XmlDocument.parse(xmlStr);

    final buffer = StringBuffer();
    for (final paragraph in doc.findAllElements('w:p')) {
      for (final node in paragraph.descendants) {
        if (node is XmlElement) {
          if (node.name.qualified == 'w:t') {
            buffer.write(node.innerText);
          } else if (node.name.qualified == 'w:tab') {
            buffer.write('\t');
          } else if (node.name.qualified == 'w:br') {
            buffer.writeln();
          }
        }
      }
      buffer.writeln();
    }

    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  } catch (_) {
    return null;
  }
}
