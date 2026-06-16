import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'legal_document_loader.dart';

/// Visualizador de PDF embutido (documentação legal).
class LegalPdfViewerPage extends StatefulWidget {
  const LegalPdfViewerPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<LegalPdfViewerPage> createState() => _LegalPdfViewerPageState();
}

class _LegalPdfViewerPageState extends State<LegalPdfViewerPage> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final document = await LegalDocumentLoader.open();
      if (!mounted) {
        await document.close();
        return;
      }
      setState(() {
        _controller = PdfControllerPinch(document: Future.value(document));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed || _controller == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Não foi possível abrir o documento.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _failed = false;
                              _controller?.dispose();
                              _controller = null;
                            });
                            _loadDocument();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfViewPinch(
                  controller: _controller!,
                  onDocumentError: (_) {
                    if (!mounted) return;
                    setState(() => _failed = true);
                  },
                ),
    );
  }
}
