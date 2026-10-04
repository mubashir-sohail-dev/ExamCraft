import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/recent_papers_model.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../../presentation/providers/recent_papers_provider.dart';
import '../base_app_screen.dart';

/// Recent Papers Screen displaying history of generated test papers with subject filtering,
/// search, favoriting, and paper action controls (View PDF, Edit, Delete).
class RecentPapersScreen extends StatefulWidget {
  const RecentPapersScreen({super.key});

  @override
  State<RecentPapersScreen> createState() => _RecentPapersScreenState();
}

class _RecentPapersScreenState extends State<RecentPapersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<RecentPapersProvider>(context, listen: false);
      if (provider.papers.isEmpty && !provider.isLoading) {
        provider.loadRecentPapers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<RecentPapersProvider>(context);
    final selectedSubject = provider.selectedSubjectFilter;

    // Filter papers by search query in addition to provider's subject filter
    final displayedPapers = provider.papers.where((paper) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return paper.title.toLowerCase().contains(q) ||
          paper.chapterOrTopic.toLowerCase().contains(q) ||
          paper.subject.displayName.toLowerCase().contains(q);
    }).toList();

    return BaseAppScreen(
      title: 'Recent Papers Archive',
      routeName: AppRoutes.recentPapers,
      actions: [
        if (provider.papers.isNotEmpty)
          IconButton(
            key: const Key('recent_clear_all_btn'),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All Papers',
            onPressed: () => _confirmClearAll(context, provider),
          ),
      ],
      body: Column(
        children: [
          // 1. Search Bar & Subject Filter Chips
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  key: const Key('recent_papers_search_input'),
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search test papers by title, topic, or subject...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chip Group for all 5 Mandatory Subjects
                Text(
                  'Filter by Subject',
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
                      // All Subjects Chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          key: const Key('recent_subject_chip_all'),
                          label: const Text('All Subjects'),
                          selected: selectedSubject == null,
                          onSelected: (_) => provider.filterBySubject(null),
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: selectedSubject == null
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: selectedSubject == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      ...SubjectUtils.allSubjects.map((subj) {
                        final isSelected = selectedSubject == subj;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            key: Key(
                                'recent_subject_chip_${subj.apiString.toLowerCase()}'),
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
                              provider
                                  .filterBySubject(isSelected ? null : subj);
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
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. Main Content Body (Grid / List of Recent Test Papers)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.loadRecentPapers();
              },
              child: _buildPapersBody(context, provider, displayedPapers),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPapersBody(
    BuildContext context,
    RecentPapersProvider provider,
    List<RecentPaperModel> displayedPapers,
  ) {
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Recent Papers...'),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.loadRecentPapers();
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
                      'Failed to Load Recent Papers',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadRecentPapers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (displayedPapers.isEmpty) {
      final isFiltered =
          _searchQuery.isNotEmpty || provider.selectedSubjectFilter != null;
      return RefreshIndicator(
        onRefresh: () async {
          await provider.loadRecentPapers();
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
                      Icons.folder_open,
                      size: 64,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFiltered
                          ? 'No Recent Papers'
                          : 'No assessments generated yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFiltered
                          ? 'No papers match your search query or subject filter.'
                          : 'Generate your first assessment from your uploaded textbooks.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      key: const Key('recent_create_new_btn'),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.generate),
                      icon: const Icon(Icons.add),
                      label: const Text('Generate New Assessment'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadRecentPapers();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: displayedPapers.length,
              itemBuilder: (context, index) {
                return _buildPaperCard(
                    context, provider, displayedPapers[index]);
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadRecentPapers();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: displayedPapers.length,
            itemBuilder: (context, index) {
              return _buildPaperCard(context, provider, displayedPapers[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaperCard(
    BuildContext context,
    RecentPapersProvider provider,
    RecentPaperModel paper,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = isDark ? paper.subject.darkColor : paper.subject.color;
    final formattedDate = paper.dateCreated.toIso8601String().split('T')[0];

    return Card(
      key: Key('recent_paper_card_${paper.paperId}'),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Header: Subject Badge, Date & Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                              Icon(paper.subject.icon,
                                  size: 14, color: subjectColor),
                              const SizedBox(width: 4),
                              Text(
                                paper.subject.displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: subjectColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('favorite_paper_btn_${paper.paperId}'),
                    icon: Icon(
                      paper.isFavorite ? Icons.star : Icons.star_border,
                      color: paper.isFavorite
                          ? Colors.amber
                          : theme.colorScheme.outline,
                    ),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip:
                        paper.isFavorite ? 'Remove Favorite' : 'Mark Favorite',
                    onPressed: () => provider.toggleFavorite(paper.paperId),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Paper Title & Topic
              Text(
                paper.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Topic: ${paper.chapterOrTopic}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer Info & Actions ("View PDF", "Edit", "Delete")
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${paper.totalMarks} Marks • ${paper.timeAllowed}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        key: Key('view_pdf_paper_btn_${paper.paperId}'),
                        onPressed: () {
                          final assessmentProv =
                              Provider.of<AssessmentProvider>(context,
                                  listen: false);
                          assessmentProv.renderPdf();
                          Navigator.pushNamed(context, AppRoutes.pdfPreview);
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 14),
                        label: const Text('View PDF'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        key: Key('edit_paper_btn_${paper.paperId}'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Paper',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.review);
                        },
                      ),
                      IconButton(
                        key: Key('delete_paper_btn_${paper.paperId}'),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        tooltip: 'Delete Paper',
                        onPressed: () =>
                            _confirmDeletePaper(context, provider, paper),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePaper(
    BuildContext context,
    RecentPapersProvider provider,
    RecentPaperModel paper,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Paper'),
          content: Text('Are you sure you want to delete "${paper.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_delete_paper_btn'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                provider.deletePaper(paper.paperId);
                Navigator.pop(context);
              },
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, RecentPapersProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Recent Papers'),
          content: const Text(
            'This action will permanently delete all saved recent papers. Proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_clear_all_btn'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                provider.clearAll();
                Navigator.pop(context);
              },
              child: const Text('Clear All',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
