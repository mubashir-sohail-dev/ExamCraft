import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/question_bank_model.dart';
import '../../presentation/providers/question_bank_provider.dart';
import '../base_app_screen.dart';

/// Question Bank Screen allowing teachers to search, filter by subject, difficulty,
/// and question type, view question details with options/answer keys, and paginate.
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedQuestionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<QuestionBankProvider>(context, listen: false);
      _searchController.text = provider.filter.searchQuery ?? '';
      if (provider.questions.isEmpty && !provider.isLoading) {
        provider.fetchQuestions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedQuestionIds.contains(id)) {
        _expandedQuestionIds.remove(id);
      } else {
        _expandedQuestionIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<QuestionBankProvider>(context);
    final filter = provider.filter;

    return BaseAppScreen(
      title: 'Question Bank',
      routeName: AppRoutes.questionBank,
      actions: [
        IconButton(
          key: const Key('qb_filter_icon_btn'),
          icon: Icon(
            Icons.filter_list,
            color: (filter.difficulty != null || filter.type != null)
                ? theme.colorScheme.primary
                : null,
          ),
          tooltip: 'Advanced Filters',
          onPressed: () => _showAdvancedFiltersModal(context, provider),
        ),
      ],
      body: Column(
        children: [
          // 1. Search Bar & Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Field
                TextField(
                  key: const Key('qb_search_input'),
                  controller: _searchController,
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search questions, chapters, or topics...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery(null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Filter Chips for All 5 Mandatory Subjects
                Text(
                  'Subjects',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All Subjects" chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          key: const Key('qb_subject_chip_all'),
                          label: const Text('All Subjects'),
                          selected: filter.subject == null,
                          onSelected: (_) => provider.setSubject(null),
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: filter.subject == null
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: filter.subject == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      ...SubjectUtils.allSubjects.map((subj) {
                        final isSelected = filter.subject == subj;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            key: Key(
                                'qb_subject_chip_${subj.apiString.toLowerCase()}'),
                            avatar: Icon(
                              subj.icon,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : subj.color,
                            ),
                            label: Text(subj.displayName),
                            selected: isSelected,
                            onSelected: (_) {
                              provider.setSubject(isSelected ? null : subj);
                            },
                            selectedColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Active Filters Row & Quick Type/Difficulty Bar
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (filter.type != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: Chip(
                                  key: const Key('qb_active_filter_type'),
                                  label:
                                      Text('Type: ${filter.type!.displayName}'),
                                  onDeleted: () => provider.setType(null),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (filter.difficulty != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: Chip(
                                  key: const Key('qb_active_filter_difficulty'),
                                  label: Text(
                                      'Diff: ${filter.difficulty!.displayName}'),
                                  onDeleted: () => provider.setDifficulty(null),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('qb_open_advanced_filters_btn'),
                      onPressed: () =>
                          _showAdvancedFiltersModal(context, provider),
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Filters'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (filter.subject != null ||
                        filter.difficulty != null ||
                        filter.type != null ||
                        (filter.searchQuery != null &&
                            filter.searchQuery!.isNotEmpty))
                      TextButton(
                        key: const Key('qb_clear_filters_btn'),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                        },
                        child: const Text('Reset'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 3. Question List Body with States (Loading, Error, Empty, Success)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.fetchQuestions();
              },
              child: _buildQuestionsBody(context, provider),
            ),
          ),

          // 4. Pagination Toolbar Footer
          if (!provider.isLoading && provider.questions.isNotEmpty)
            _buildPaginationFooter(context, provider),
        ],
      ),
    );
  }

  Widget _buildQuestionsBody(
      BuildContext context, QuestionBankProvider provider) {
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Question Bank...'),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.fetchQuestions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'Error Loading Questions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      key: const Key('qb_retry_btn'),
                      onPressed: () => provider.fetchQuestions(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (provider.questions.isEmpty) {
      final isFiltered = _searchController.text.isNotEmpty ||
          provider.filter.subject != null ||
          provider.filter.difficulty != null ||
          provider.filter.type != null;

      if (!isFiltered) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchQuestions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No questions indexed yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a textbook to start indexing questions automatically.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/upload'),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Textbook'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await provider.fetchQuestions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: theme.colorScheme.outline.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Questions Found',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No questions match your current search query or subject filters.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      key: const Key('qb_empty_reset_btn'),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearFilters();
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear All Filters'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchQuestions();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: provider.questions.length,
        itemBuilder: (context, index) {
          final q = provider.questions[index];
          final isExpanded = _expandedQuestionIds.contains(q.id);
          return _buildQuestionCard(context, q, isExpanded);
        },
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    QuestionItemModel question,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor =
        isDark ? question.subject.darkColor : question.subject.color;

    return Card(
      key: Key('question_card_${question.id}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tags Wrap (Defensive against RenderFlex overflow)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Subject Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: subjectColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(question.subject.icon,
                              size: 12, color: subjectColor),
                          const SizedBox(width: 4),
                          Text(
                            question.subject.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: subjectColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.type.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Difficulty Chip
                    _buildDifficultyChip(theme, question.difficulty),

                    // Marks Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${question.marks} ${question.marks == 1 ? 'Mark' : 'Marks'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question Text
                Text(
                  question.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chapter: ${question.chapterName}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              key: Key('toggle_expand_btn_${question.id}'),
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: theme.colorScheme.primary,
              ),
              onPressed: () => _toggleExpanded(question.id),
            ),
            onTap: () => _toggleExpanded(question.id),
          ),

          // Expanded Section (Options, Answer Key, Explanation)
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MCQ Options
                  if (question.type == QuestionType.mcq &&
                      question.options.isNotEmpty) ...[
                    Text(
                      'Options:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...question.options.map((opt) {
                      final isCorrect = opt.startsWith(question.answer) ||
                          question.answer.contains(opt);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: isCorrect
                                  ? const Color(0xFF006E2C)
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                opt,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isCorrect
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCorrect
                                      ? const Color(0xFF006E2C)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Answer Key & Explanation
                  Text(
                    'Answer Key / Solution:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      question.answer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  if (question.textbookReference.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Ref: ${question.textbookReference}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(ThemeData theme, QuestionDifficulty difficulty) {
    Color bg;
    Color fg;
    switch (difficulty) {
      case QuestionDifficulty.easy:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF006E2C);
        break;
      case QuestionDifficulty.medium:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFF805600);
        break;
      case QuestionDifficulty.hard:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFBA1A1A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(
      BuildContext context, QuestionBankProvider provider) {
    final theme = Theme.of(context);
    final currentPage = provider.filter.page;
    final totalPages = provider.totalPages > 0 ? provider.totalPages : 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Total: ${provider.totalCount} questions',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('qb_prev_page_btn'),
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: currentPage > 1
                    ? () => provider.setPage(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                'Page $currentPage of $totalPages',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const Key('qb_next_page_btn'),
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: currentPage < totalPages
                    ? () => provider.setPage(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdvancedFiltersModal(
      BuildContext context, QuestionBankProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return QuestionBankFiltersModal(provider: provider);
      },
    );
  }
}

/// Advanced Filters Modal Dialog / Bottom Sheet
class QuestionBankFiltersModal extends StatefulWidget {
  final QuestionBankProvider provider;

  const QuestionBankFiltersModal({super.key, required this.provider});

  @override
  State<QuestionBankFiltersModal> createState() =>
      _QuestionBankFiltersModalState();
}

class _QuestionBankFiltersModalState extends State<QuestionBankFiltersModal> {
  ExamSubject? _tempSubject;
  QuestionDifficulty? _tempDifficulty;
  QuestionType? _tempType;

  @override
  void initState() {
    super.initState();
    _tempSubject = widget.provider.filter.subject;
    _tempDifficulty = widget.provider.filter.difficulty;
    _tempType = widget.provider.filter.type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advanced Filters',
                style: theme.textTheme.titleLarge?.copyWith(
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

          // Subject Selection
          Text(
            'Subject',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _tempSubject == null,
                onSelected: (_) => setState(() => _tempSubject = null),
              ),
              ...SubjectUtils.allSubjects.map((s) {
                return ChoiceChip(
                  label: Text(s.displayName),
                  selected: _tempSubject == s,
                  onSelected: (_) => setState(() => _tempSubject = s),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Question Type
          Text(
            'Question Type',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Types'),
                selected: _tempType == null,
                onSelected: (_) => setState(() => _tempType = null),
              ),
              ...QuestionType.values.map((t) {
                return ChoiceChip(
                  key: Key('qb_filter_type_${t.code}'),
                  label: Text(t.displayName),
                  selected: _tempType == t,
                  onSelected: (_) => setState(() => _tempType = t),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty Level
          Text(
            'Difficulty Level',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Difficulties'),
                selected: _tempDifficulty == null,
                onSelected: (_) => setState(() => _tempDifficulty = null),
              ),
              ...QuestionDifficulty.values.map((d) {
                return ChoiceChip(
                  key: Key('qb_filter_diff_${d.name}'),
                  label: Text(d.displayName),
                  selected: _tempDifficulty == d,
                  onSelected: (_) => setState(() => _tempDifficulty = d),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('qb_modal_reset_btn'),
                  onPressed: () {
                    setState(() {
                      _tempSubject = null;
                      _tempDifficulty = null;
                      _tempType = null;
                    });
                  },
                  child: const Text('Reset All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('qb_modal_apply_btn'),
                  onPressed: () {
                    widget.provider.setSubject(_tempSubject);
                    widget.provider.setDifficulty(_tempDifficulty);
                    widget.provider.setType(_tempType);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

/// Standalone QuestionBankFiltersScreen mapping to `/question_bank/filters`
class QuestionBankFiltersScreen extends StatelessWidget {
  const QuestionBankFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestionBankProvider>(context);

    return BaseAppScreen(
      title: 'Question Bank Filters',
      routeName: AppRoutes.questionBankFilters,
      body: QuestionBankFiltersModal(provider: provider),
    );
  }
}
