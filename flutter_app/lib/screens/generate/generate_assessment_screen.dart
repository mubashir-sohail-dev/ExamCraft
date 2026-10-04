import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../base_app_screen.dart';

/// Generate Assessment Screen (Light & Dark mode support).
/// Form for configuring subject, chapter checklist, question distribution (MCQ, Short, Long),
/// difficulty level, total marks calculation, and triggering AI draft generation.
class GenerateAssessmentScreen extends StatefulWidget {
  final IAssessmentRepository? repository;

  const GenerateAssessmentScreen({
    super.key,
    this.repository,
  });

  @override
  State<GenerateAssessmentScreen> createState() =>
      _GenerateAssessmentScreenState();
}

class _GenerateAssessmentScreenState extends State<GenerateAssessmentScreen> {

  ExamSubject _selectedSubject = ExamSubject.chemistry;
  String? _selectedChapter;
  bool _isLoadingChapters = false;

  String _scopeMode = 'full_chapter'; // 'full_chapter' or 'topic'
  final TextEditingController _topicQueryController = TextEditingController();

  int _mcqCount = 5;
  int _shortCount = 3;
  int _longCount = 1;
  String _selectedDifficulty = 'Medium'; // Easy, Medium, Hard
  bool _includeAnswerKey = true;

  final TextEditingController _instructionController = TextEditingController();

  bool _isGenerating = false;
  String? _errorMessage;

  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();
    _topicQueryController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChaptersForSubject(_selectedSubject);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      _initializedFromRoute = true;
      final routeSettings = ModalRoute.of(context)?.settings;
      ExamSubject? targetSubject;

      if (routeSettings?.arguments is Map) {
        final args = routeSettings!.arguments as Map;
        final subjectArg = args['subject'];
        if (subjectArg is String) {
          try {
            targetSubject = SubjectUtils.fromApiString(subjectArg);
          } catch (_) {}
        }
        final gradeArg = args['grade'];
        if (gradeArg is int) {
          final provider = Provider.of<AssessmentProvider>(context, listen: false);
          provider.selectGrade(gradeArg);
        }
      }

      if (targetSubject != null && targetSubject != _selectedSubject) {
        _loadChaptersForSubject(targetSubject);
      }
    }
  }

  @override
  void dispose() {
    _topicQueryController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  /// Dynamically fetch chapters for the selected subject via repository
  Future<void> _loadChaptersForSubject(ExamSubject subject) async {
    setState(() {
      _selectedSubject = subject;
      _isLoadingChapters = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      await provider.selectSubject(subject);
      if (!mounted) return;
      setState(() {
        _selectedChapter = provider.selectedChapter;
        _isLoadingChapters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingChapters = false;
        _errorMessage = 'Failed to load chapters: ${e.toString()}';
      });
    }
  }

  int get _calculatedTotalMarks =>
      (_mcqCount * 1) + (_shortCount * 2) + (_longCount * 5);

  bool get isFormValid {
    try {
      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      if (provider.chapters.isEmpty) return false;
      if (_scopeMode == 'full_chapter') {
        final effectiveChapter = _selectedChapter ?? provider.selectedChapter;
        if (effectiveChapter == null || effectiveChapter.isEmpty) {
          return false;
        }
      } else if (_scopeMode == 'topic') {
        if (_topicQueryController.text.trim().isEmpty) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleGenerateSubmit() async {
    if (!isFormValid) {
      if (_scopeMode == 'topic' && _topicQueryController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a topic query for specific topic mode.';
        });
      } else {
        setState(() {
          _errorMessage = 'Please select a chapter before generating assessment.';
        });
      }
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      provider.setTestType(_scopeMode);
      provider.setTopicQuery(_topicQueryController.text.trim());
      final instruction = _instructionController.text.trim();
      provider.setGenerationInstruction(instruction.isEmpty ? null : instruction);
      provider.updateQuestionCounts(
        mcq: _mcqCount,
        short: _shortCount,
        long: _longCount,
      );
      provider.toggleAnswerKey(_includeAnswerKey);

      Navigator.pushNamed(context, AppRoutes.generating);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Generation failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BaseAppScreen(
      title: 'Generate Assessment',
      routeName: AppRoutes.generate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return Consumer<AssessmentProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Generate Assessment',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select subject, chapter, question count, and difficulty to generate an AI assessment.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 7,
                              child: _buildFormLeftColumn(
                                  theme, isDark, provider)),
                          const SizedBox(width: 24),
                          Expanded(
                              flex: 5,
                              child: _buildSummaryRightColumn(theme, isDark)),
                        ],
                      )
                    else ...[
                      _buildFormLeftColumn(theme, isDark, provider),
                      const SizedBox(height: 24),
                      _buildSummaryRightColumn(theme, isDark),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormLeftColumn(
      ThemeData theme, bool isDark, AssessmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Mandatory 5 Subjects Selection Grid / Selector
        Text(
          '1. Select Subject (All 5 Mandatory Subjects)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: ExamSubject.values.length,
          itemBuilder: (context, index) {
            final subject = ExamSubject.values[index];
            final isSelected = _selectedSubject == subject;
            final color = isDark ? subject.darkColor : subject.color;

            return InkWell(
              key: Key('subject_tile_${subject.name}'),
              onTap: () => _loadChaptersForSubject(subject),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? color : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(subject.icon, color: color, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subject.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected ? color : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // 2. Dynamic Chapter Selection Checklist / Dropdown
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_books, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '2. Select Chapter / Topic Scope',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Class / Grade Choice Chips Bar
                Text(
                  'Academic Class:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [9, 10, 11, 12].map((grade) {
                      final isSelected = provider.selectedGrade == grade;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          key: Key('chip_class_$grade'),
                          label: Text('Class $grade'),
                          selected: isSelected,
                          onSelected: (val) async {
                            if (val) {
                              setState(() {
                                _isLoadingChapters = true;
                                _errorMessage = null;
                              });
                              await provider.selectGrade(grade);
                              if (!mounted) return;
                              setState(() {
                                _selectedChapter = provider.selectedChapter;
                                _isLoadingChapters = false;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Scope Selector Mode (Full Chapter vs Specific Topic)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        key: const Key('chip_mode_full'),
                        label: const Text('Full Chapter'),
                        selected: _scopeMode == 'full_chapter',
                        onSelected: (val) {
                          if (val) setState(() => _scopeMode = 'full_chapter');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        key: const Key('chip_mode_topic'),
                        label: const Text('Specific Topic'),
                        selected: _scopeMode == 'topic',
                        onSelected: (val) {
                          if (val) setState(() => _scopeMode = 'topic');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_isLoadingChapters || provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.chapters.isEmpty)
                  Container(
                    key: const Key('card_empty_chapters_warning'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber.shade900,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No Indexed Chapters Available',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No chapters are indexed for the selected Class ${provider.selectedGrade} and ${_selectedSubject.displayName} in Qdrant vector database. Please upload the textbook to enable assessment generation.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          key: const Key('btn_upload_textbook_empty'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.upload,
                              arguments: {
                                'subject': _selectedSubject.apiString,
                                'grade': provider.selectedGrade,
                              },
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Textbook'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'Chapter:',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: const Key('dropdown_chapter'),
                    // ignore: deprecated_member_use
                    value: provider.chapters.contains(_selectedChapter)
                        ? _selectedChapter
                        : (provider.chapters.isNotEmpty
                            ? provider.chapters.first
                            : null),
                    isExpanded: true,
                    menuMaxHeight: 360,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.bookmark_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return provider.chapters.map((ch) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            ch,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: provider.chapters.map((ch) {
                      return DropdownMenuItem<String>(
                        value: ch,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            ch,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newChapter) {
                      if (newChapter != null) {
                        setState(() {
                          _selectedChapter = newChapter;
                        });
                        provider.selectChapter(newChapter);
                      }
                    },
                  ),
                ],

                if (_selectedSubject.apiString == 'Mathematics' &&
                    _selectedChapter != null &&
                    provider.availableExercises.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Exercise:',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: const Key('dropdown_exercise'),
                    initialValue: provider.selectedExercise,
                    isExpanded: true,
                    menuMaxHeight: 360,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.assignment_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    items: provider.availableExercises.map((ex) {
                      return DropdownMenuItem<String>(
                        value: ex,
                        child: Text(ex, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (newExercise) {
                      provider.setSelectedExercise(newExercise);
                    },
                  ),
                ],

                if (_scopeMode == 'topic') ...[
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('input_topic_query'),
                    controller: _topicQueryController,
                    decoration: InputDecoration(
                      labelText: 'Specific Topic Query',
                      hintText: 'e.g. Solving systems by substitution',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  key: const Key('input_teacher_instructions'),
                  controller: _instructionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Teacher Instructions (Optional)',
                    hintText:
                        'e.g. Focus on word problems, ensure questions are challenging...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Question Distribution Controls (MCQ, Short, Long)
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_list_numbered,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '3. Question Distribution',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // MCQ Slider
                _buildSliderControl(
                  theme,
                  keyStr: 'slider_mcq_count',
                  label: 'Multiple Choice Questions (1 Mark)',
                  value: _mcqCount.toDouble(),
                  min: 0,
                  max: 20,
                  onChanged: (v) => setState(() => _mcqCount = v.toInt()),
                ),
                const SizedBox(height: 16),

                // Short Slider
                _buildSliderControl(
                  theme,
                  keyStr: 'slider_short_count',
                  label: 'Short Answer Questions (2 Marks)',
                  value: _shortCount.toDouble(),
                  min: 0,
                  max: 15,
                  onChanged: (v) => setState(() => _shortCount = v.toInt()),
                ),
                const SizedBox(height: 16),

                // Long Slider
                _buildSliderControl(
                  theme,
                  keyStr: 'slider_long_count',
                  label: 'Long / Essay Questions (5 Marks)',
                  value: _longCount.toDouble(),
                  min: 0,
                  max: 10,
                  onChanged: (v) => setState(() => _longCount = v.toInt()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRightColumn(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Marks Auto-Calculator Widget
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                'Calculated Assessment Total Marks',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_calculatedTotalMarks Marks',
                key: const Key('txt_total_marks'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '($_mcqCount MCQs × 1) + ($_shortCount Short × 2) + ($_longCount Long × 5)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Difficulty Level Selector
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Difficulty Level Selector:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Easy', 'Medium', 'Hard'].map((diff) {
                    final isSel = _selectedDifficulty == diff;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          key: Key('chip_difficulty_$diff'),
                          label: Text(diff),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedDifficulty = diff);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Include Answer Key Switch
                SwitchListTile(
                  key: const Key('switch_include_answer_key'),
                  title: const Text('Include Answer Key'),
                  subtitle:
                      const Text('Automatically generate textbook solutions'),
                  value: _includeAnswerKey,
                  onChanged: (val) => setState(() => _includeAnswerKey = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('btn_generate_assessment'),
                onPressed:
                    (_isGenerating || !isFormValid) ? null : _handleGenerateSubmit,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_isGenerating
                    ? 'Generating Draft...'
                    : 'Generate Assessment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderControl(
    ThemeData theme, {
    required String keyStr,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toInt()}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          key: Key(keyStr),
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
