import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/assessment_model.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../base_app_screen.dart';

/// PDF Preview & Actions Screen providing an interactive document canvas,
/// zoom controls, page indicators, authentic PDF actions (Download, Print, Share, Regenerate),
/// and export settings dialog.
class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  double _zoomLevel = 1.0;
  final int _currentPage = 1;
  final int _totalPages = 1;
  bool _includeAnswerKey = true;
  bool _isProcessing = false;

  void _zoomIn() {
    setState(() {
      if (_zoomLevel < 2.0) _zoomLevel += 0.25;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoomLevel > 0.5) _zoomLevel -= 0.25;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _showExportOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Export & Print Options',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      key: const Key('pdf_option_include_answer_key'),
                      title: const Text('Include Answer Key Section'),
                      subtitle: const Text(
                          'Append full solutions and marking scheme at the end'),
                      value: _includeAnswerKey,
                      onChanged: (val) {
                        setModalState(() => _includeAnswerKey = val);
                        setState(() => _includeAnswerKey = val);
                      },
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Page Format'),
                      trailing: Text('Standard A4 (Portrait)'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.high_quality),
                      title: Text('Print Resolution'),
                      trailing: Text('300 DPI Vector'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      key: const Key('pdf_apply_export_settings_btn'),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Export settings updated successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Settings'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleDownloadPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    setState(() => _isProcessing = true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating PDF binary stream...')),
    );

    var pdfResponse = provider.pdfResponse;
    pdfResponse ??= await provider.renderPdf();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (pdfResponse == null || pdfResponse.pdfBytes.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage ??
                'Failed to render PDF binary stream.')),
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'ExamCraft_AI_${provider.generatedAssessment?.subject.apiString ?? "Paper"}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfResponse.pdfBytes);

      if (await file.exists() && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${file.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error saving PDF file: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handlePrintPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    setState(() => _isProcessing = true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Preparing document for system printer...')),
    );

    var pdfResponse = provider.pdfResponse;
    pdfResponse ??= await provider.renderPdf();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (pdfResponse == null || pdfResponse.pdfBytes.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage ??
                'Failed to render PDF binary stream.')),
      );
      return;
    }

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfResponse!.pdfBytes,
        name: provider.generatedAssessment?.testTitle ??
            'ExamCraft_AI_Assessment',
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text('Error launching print dialog: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleSharePdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    setState(() => _isProcessing = true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Preparing PDF document for sharing...')),
    );

    var pdfResponse = provider.pdfResponse;
    pdfResponse ??= await provider.renderPdf();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (pdfResponse == null || pdfResponse.pdfBytes.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage ??
                'Failed to render PDF binary stream.')),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'ExamCraft_AI_${provider.generatedAssessment?.subject.apiString ?? "Paper"}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfResponse.pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'ExamCraft AI Generated Assessment: ${provider.generatedAssessment?.testTitle}',
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error opening share sheet: ${e.toString()}')),
        );
      }
    }
  }

  void _handleRegeneratePdf(BuildContext context) {
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    provider.renderPdf();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Regenerating PDF document layout...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AssessmentProvider>(context);
    final assessment = provider.generatedAssessment;
    if (assessment == null) {
      return BaseAppScreen(
        title: 'PDF Document Preview',
        routeName: AppRoutes.pdfPreview,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Assessment Generated Yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please generate a test paper first to preview the PDF.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return BaseAppScreen(
      title: 'PDF Document Preview',
      routeName: AppRoutes.pdfPreview,
      actions: [
        IconButton(
          key: const Key('pdf_preview_options_btn'),
          icon: const Icon(Icons.tune),
          tooltip: 'Export Options',
          onPressed: () => _showExportOptionsModal(context),
        ),
      ],
      body: Column(
        children: [
          // 1. Interactive Zoom & Page Toolbar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                // Page Indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Page $_currentPage of $_totalPages',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),

                // Zoom Controls
                IconButton(
                  key: const Key('pdf_zoom_out_btn'),
                  icon: const Icon(Icons.zoom_out),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Zoom Out',
                  onPressed: _zoomOut,
                ),
                InkWell(
                  onTap: _resetZoom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${(_zoomLevel * 100).toInt()}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('pdf_zoom_in_btn'),
                  icon: const Icon(Icons.zoom_in),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Zoom In',
                  onPressed: _zoomIn,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. Main PDF Preview Document Canvas
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Transform.scale(
                    scale: _zoomLevel,
                    child: _buildPdfDocumentSheet(context, theme, assessment),
                  ),
                ),
              ),
            ),
          ),

          // 3. Action Toolbar ("Download PDF", "Print", "Share", "Regenerate")
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  key: const Key('pdf_btn_download'),
                  onPressed:
                      _isProcessing ? null : () => _handleDownloadPdf(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                ),
                OutlinedButton.icon(
                  key: const Key('pdf_btn_print'),
                  onPressed:
                      _isProcessing ? null : () => _handlePrintPdf(context),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
                OutlinedButton.icon(
                  key: const Key('pdf_btn_share'),
                  onPressed:
                      _isProcessing ? null : () => _handleSharePdf(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                IconButton(
                  key: const Key('pdf_btn_regenerate'),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate Document',
                  onPressed: _isProcessing
                      ? null
                      : () => _handleRegeneratePdf(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a rendered PDF document canvas sheet (A4 Ratio styled sheet matching `pdf_preview.html`)
  Widget _buildPdfDocumentSheet(
    BuildContext context,
    ThemeData theme,
    AssessmentModel assessment,
  ) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / School Seal Block
          Center(
            child: Column(
              children: [
                Text(
                  'EXAMCRAFT AI ASSESSMENT SYSTEM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assessment.testTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Subject: ${assessment.subject.displayName} | Grade 9 | Time Allowed: ${assessment.timeAllowed}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                Text(
                  'Total Marks: ${assessment.calculatedTotalMarks}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(thickness: 1.5, color: Colors.black87),
              ],
            ),
          ),

          // Instructions
          if (assessment.instructions.isNotEmpty) ...[
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            ...assessment.instructions.map(
              (inst) => Text(
                '• $inst',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // SECTION A: MCQs
          if (assessment.mcqs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.grey.shade200,
              child: Text(
                'SECTION A: MULTIPLE CHOICE QUESTIONS (Marks: ${assessment.mcqs.length * 1})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...assessment.mcqs.map((mcq) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${mcq.questionNumber}. ${mcq.question}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: mcq.options.map((opt) {
                        return Text(
                          opt,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black87),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // SECTION B: SHORT QUESTIONS
          if (assessment.shortQuestions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.grey.shade200,
              child: const Text(
                'SECTION B: SHORT ANSWER QUESTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...assessment.shortQuestions.map((q) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Q${q.questionNumber}. ${q.question}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '[${q.marks}]',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // SECTION C: LONG QUESTIONS
          if (assessment.longQuestions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.grey.shade200,
              child: const Text(
                'SECTION C: LONG / ESSAY QUESTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...assessment.longQuestions.map((q) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Q${q.questionNumber}. ${q.question}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '[${q.marks}]',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // ANSWER KEY SECTION (If Enabled)
          if (_includeAnswerKey) ...[
            const Divider(thickness: 1.5, color: Colors.blue),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '--- ANSWER KEY & SOLUTION GUIDE ---',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...assessment.mcqs.map((m) {
              return Text(
                'MCQ ${m.questionNumber}: Correct Option ${m.correctOption}',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              );
            }),
          ],
        ],
      ),
    );
  }
}
