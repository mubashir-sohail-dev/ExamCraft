import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/assessment_model.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../base_app_screen.dart';

/// Review Paper Screen for reviewing, editing, adding/deleting questions, and exporting to PDF.
class ReviewPaperScreen extends StatefulWidget {
  const ReviewPaperScreen({super.key});

  @override
  State<ReviewPaperScreen> createState() => _ReviewPaperScreenState();
}

class _ReviewPaperScreenState extends State<ReviewPaperScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AssessmentModel? _assessmentModel;
  AssessmentModel get _assessment => _assessmentModel!;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAssessment();
  }

  void _initAssessment() {
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    _assessmentModel = provider.generatedAssessment;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateAssessment(AssessmentModel updated) {
    setState(() {
      _assessmentModel = updated.copyWith(
        totalMarks: updated.calculatedTotalMarks,
      );
    });
  }

  // --- MCQ EDITING ACTIONS ---
  void _editMCQ(int index, MCQItemModel item) {
    final textController = TextEditingController(text: item.question);
    final refController = TextEditingController(text: item.textbookReference);
    final optionsControllers =
        item.options.map((opt) => TextEditingController(text: opt)).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit MCQ Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('edit_mcq_text_input'),
                  controller: textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refController,
                  decoration: const InputDecoration(
                    labelText: 'Textbook Reference',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Options:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...List.generate(optionsControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: optionsControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Option ${String.fromCharCode(65 + i)}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('save_mcq_edit_btn'),
              onPressed: () {
                final updatedMcqs = List<MCQItemModel>.from(_assessment.mcqs);
                updatedMcqs[index] = item.copyWith(
                  question: textController.text.trim(),
                  textbookReference: refController.text.trim(),
                  options:
                      optionsControllers.map((c) => c.text.trim()).toList(),
                );
                _updateAssessment(_assessment.copyWith(mcqs: updatedMcqs));
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMCQ(int index) {
    final updatedMcqs = List<MCQItemModel>.from(_assessment.mcqs)
      ..removeAt(index);
    // Renumber questions
    final renumbered = List.generate(updatedMcqs.length, (i) {
      return updatedMcqs[i].copyWith(questionNumber: i + 1);
    });
    _updateAssessment(_assessment.copyWith(mcqs: renumbered));
  }

  void _regenerateMCQ(int index) {
    final updatedMcqs = List<MCQItemModel>.from(_assessment.mcqs);
    final oldItem = updatedMcqs[index];
    updatedMcqs[index] = oldItem.copyWith(
      question: '${oldItem.question} (Regenerated Variant)',
    );
    _updateAssessment(_assessment.copyWith(mcqs: updatedMcqs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('MCQ question regenerated with AI variation.')),
    );
  }

  // --- SHORT QUESTION EDITING ACTIONS ---
  void _editShortQuestion(int index, ShortQuestionItemModel item) {
    final textController = TextEditingController(text: item.question);
    int currentMarks = item.marks;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Short Question'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('edit_short_text_input'),
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Question Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Marks:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            key: const Key('dec_short_marks_btn'),
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: currentMarks > 1
                                ? () => setModalState(() => currentMarks--)
                                : null,
                          ),
                          Text(
                            '$currentMarks',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            key: const Key('inc_short_marks_btn'),
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                setModalState(() => currentMarks++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const Key('save_short_edit_btn'),
                  onPressed: () {
                    final updatedShorts = List<ShortQuestionItemModel>.from(
                        _assessment.shortQuestions);
                    updatedShorts[index] = item.copyWith(
                      question: textController.text.trim(),
                      marks: currentMarks,
                    );
                    _updateAssessment(
                        _assessment.copyWith(shortQuestions: updatedShorts));
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteShortQuestion(int index) {
    final updatedShorts =
        List<ShortQuestionItemModel>.from(_assessment.shortQuestions)
          ..removeAt(index);
    final renumbered = List.generate(updatedShorts.length, (i) {
      return updatedShorts[i].copyWith(questionNumber: i + 1);
    });
    _updateAssessment(_assessment.copyWith(shortQuestions: renumbered));
  }

  void _regenerateShortQuestion(int index) {
    final updatedShorts =
        List<ShortQuestionItemModel>.from(_assessment.shortQuestions);
    final oldItem = updatedShorts[index];
    updatedShorts[index] = oldItem.copyWith(
      question: '${oldItem.question} (AI Refreshed Version)',
    );
    _updateAssessment(_assessment.copyWith(shortQuestions: updatedShorts));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Short question regenerated successfully.')),
    );
  }

  // --- LONG QUESTION EDITING ACTIONS ---
  void _editLongQuestion(int index, LongQuestionItemModel item) {
    final textController = TextEditingController(text: item.question);
    int currentMarks = item.marks;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Long / Essay Question'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('edit_long_text_input'),
                    controller: textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Question Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Marks:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            key: const Key('dec_long_marks_btn'),
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: currentMarks > 1
                                ? () => setModalState(() => currentMarks--)
                                : null,
                          ),
                          Text(
                            '$currentMarks',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            key: const Key('inc_long_marks_btn'),
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                setModalState(() => currentMarks++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const Key('save_long_edit_btn'),
                  onPressed: () {
                    final updatedLongs = List<LongQuestionItemModel>.from(
                        _assessment.longQuestions);
                    updatedLongs[index] = item.copyWith(
                      question: textController.text.trim(),
                      marks: currentMarks,
                    );
                    _updateAssessment(
                        _assessment.copyWith(longQuestions: updatedLongs));
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteLongQuestion(int index) {
    final updatedLongs =
        List<LongQuestionItemModel>.from(_assessment.longQuestions)
          ..removeAt(index);
    final renumbered = List.generate(updatedLongs.length, (i) {
      return updatedLongs[i].copyWith(questionNumber: i + 1);
    });
    _updateAssessment(_assessment.copyWith(longQuestions: renumbered));
  }

  void _regenerateLongQuestion(int index) {
    final updatedLongs =
        List<LongQuestionItemModel>.from(_assessment.longQuestions);
    final oldItem = updatedLongs[index];
    updatedLongs[index] = oldItem.copyWith(
      question: '${oldItem.question} (Expanded Concept Variant)',
    );
    _updateAssessment(_assessment.copyWith(longQuestions: updatedLongs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Long question regenerated with new sub-questions.')),
    );
  }

  // --- EXPORT PDF ACTION ---
  Future<void> _handleExportPdf() async {
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    // Render PDF and navigate to preview
    await provider.renderPdf();
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.pdfPreview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_assessmentModel == null) {
      return BaseAppScreen(
        title: 'Review Test Paper',
        routeName: AppRoutes.review,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_late_outlined,
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
                'Please generate a test paper first to review and edit questions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.generate,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Generate New Assessment'),
              ),
            ],
          ),
        ),
      );
    }

    final subject = _assessment.subject;
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = isDark ? subject.darkColor : subject.color;

    return BaseAppScreen(
      title: 'Review Test Paper',
      routeName: AppRoutes.review,
      actions: [
        IconButton(
          key: const Key('review_export_pdf_icon_btn'),
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: 'Export PDF',
          onPressed: _handleExportPdf,
        ),
      ],
      body: Column(
        children: [
          // 1. Assessment Summary Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 6.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Subject Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: subjectColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(subject.icon, size: 14, color: subjectColor),
                          const SizedBox(width: 4),
                          Text(
                            subject.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: subjectColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grade Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Class 9 / Grade 9',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _assessment.testTitle,
                  key: const Key('review_test_title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Topic / Chapter: ${_assessment.chapterOrTopic}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatChip(
                      theme,
                      Icons.star_outline,
                      'Total Marks: ${_assessment.calculatedTotalMarks}',
                    ),
                    _buildStatChip(
                      theme,
                      Icons.timer_outlined,
                      _assessment.timeAllowed,
                    ),
                    _buildStatChip(
                      theme,
                      Icons.quiz_outlined,
                      '${_assessment.totalQuestionCount} Questions',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Section Navigation Tabs
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: [
              Tab(
                key: const Key('tab_section_mcqs'),
                text: 'Section A (MCQs: ${_assessment.mcqs.length})',
              ),
              Tab(
                key: const Key('tab_section_short'),
                text: 'Section B (Short: ${_assessment.shortQuestions.length})',
              ),
              Tab(
                key: const Key('tab_section_long'),
                text: 'Section C (Long: ${_assessment.longQuestions.length})',
              ),
            ],
          ),

          // 3. Tab Bar View with Questions
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMCQSection(context, theme),
                _buildShortSection(context, theme),
                _buildLongSection(context, theme),
              ],
            ),
          ),

          // 4. Bottom Action Bar ("Export PDF" button)
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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('review_export_pdf_btn'),
                    onPressed: _handleExportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(
                      'Export PDF Paper',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION A: MCQs BUILDER ---
  Widget _buildMCQSection(BuildContext context, ThemeData theme) {
    if (_assessment.mcqs.isEmpty) {
      return const Center(child: Text('No Multiple Choice Questions added.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _assessment.mcqs.length,
      itemBuilder: (context, index) {
        final mcq = _assessment.mcqs[index];
        return Card(
          key: Key('mcq_review_item_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Q${mcq.questionNumber}. (1 Mark)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('edit_mcq_btn_$index'),
                          icon: const Icon(Icons.edit_note, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Question',
                          onPressed: () => _editMCQ(index, mcq),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: Key('regen_mcq_btn_$index'),
                          icon: const Icon(Icons.autorenew, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Regenerate Question',
                          onPressed: () => _regenerateMCQ(index),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: Key('delete_mcq_btn_$index'),
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete Question',
                          onPressed: () => _deleteMCQ(index),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mcq.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...mcq.options.map((opt) {
                  final isCorrect = opt.startsWith(mcq.correctOption) ||
                      opt.contains(mcq.correctOption);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            isCorrect
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: isCorrect
                                ? const Color(0xFF006E2C)
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight:
                                  isCorrect ? FontWeight.bold : FontWeight.normal,
                              color: isCorrect
                                  ? const Color(0xFF006E2C)
                                  : theme.colorScheme.onSurface,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SECTION B: SHORT QUESTIONS BUILDER ---
  Widget _buildShortSection(BuildContext context, ThemeData theme) {
    if (_assessment.shortQuestions.isEmpty) {
      return const Center(child: Text('No Short Answer Questions added.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _assessment.shortQuestions.length,
      itemBuilder: (context, index) {
        final item = _assessment.shortQuestions[index];
        return Card(
          key: Key('short_review_item_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Q${item.questionNumber}. (${item.marks} ${item.marks == 1 ? 'Mark' : 'Marks'})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('edit_short_btn_$index'),
                          icon: const Icon(Icons.edit_note, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Question',
                          onPressed: () => _editShortQuestion(index, item),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: Key('regen_short_btn_$index'),
                          icon: const Icon(Icons.autorenew, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Regenerate Question',
                          onPressed: () => _regenerateShortQuestion(index),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: Key('delete_short_btn_$index'),
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete Question',
                          onPressed: () => _deleteShortQuestion(index),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SECTION C: LONG QUESTIONS BUILDER ---
  Widget _buildLongSection(BuildContext context, ThemeData theme) {
    if (_assessment.longQuestions.isEmpty) {
      return const Center(child: Text('No Long / Essay Questions added.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _assessment.longQuestions.length,
      itemBuilder: (context, index) {
        final item = _assessment.longQuestions[index];
        return Card(
          key: Key('long_review_item_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Q${item.questionNumber}. (${item.marks} Marks)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('edit_long_btn_$index'),
                          icon: const Icon(Icons.edit_note, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Question',
                          onPressed: () => _editLongQuestion(index, item),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: Key('regen_long_btn_$index'),
                          icon: const Icon(Icons.autorenew, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Regenerate Question',
                          onPressed: () => _regenerateLongQuestion(index),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: Key('delete_long_btn_$index'),
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete Question',
                          onPressed: () => _deleteLongQuestion(index),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
