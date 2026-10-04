import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../../core/routes/app_routes.dart';
import '../base_app_screen.dart';

/// Generating Assessment Screen (Light & Dark mode support).
/// Displays real async RAG Qdrant retrieval and Gemini AI generation steps without fake timers.
class GeneratingScreen extends StatefulWidget {
  const GeneratingScreen({super.key});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  int _currentStepIndex = 0;
  double _progress = 0.25;
  bool _hasError = false;
  bool _isCompleted = false;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Searching Knowledge Base',
      'subtitle':
          'Retrieving relevant textbook material & syllabus context via Qdrant.',
      'icon': 'search',
    },
    {
      'title': 'Context Extraction & Alignment',
      'subtitle':
          'Aligning extracted textbook material with Bloom\'s taxonomy.',
      'icon': 'menu_book',
    },
    {
      'title': 'Synthesizing AI Questions',
      'subtitle': 'Synthesizing MCQs, Short & Long questions with answer keys.',
      'icon': 'psychology',
    },
    {
      'title': 'Test Paper Assembly & Answer Key',
      'subtitle':
          'Formatting layout, calculating marks & constructing answer key.',
      'icon': 'assignment_turned_in',
    },
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('[GeneratingScreen] initState called');
    _startGeneration();
  }

  void _startGeneration() {
    debugPrint('[GeneratingScreen] _startGeneration() called');
    setState(() {
      _currentStepIndex = 0;
      _progress = 0.25;
      _hasError = false;
      _isCompleted = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = Provider.of<AssessmentProvider>(context, listen: false);

      // Advance step visually as async operation proceeds
      setState(() {
        _currentStepIndex = 1;
        _progress = 0.50;
      });

      debugPrint('[GeneratingScreen] calling provider.generateDraftTest()...');
      final result = await provider.generateDraftTest();
      debugPrint(
          '[GeneratingScreen] generateDraftTest returned: ${result?.testTitle ?? "null"}, mounted=$mounted');
      if (!mounted) return;

      if (result != null) {
        debugPrint('[GeneratingScreen] SUCCESS - setting completed state');
        setState(() {
          _currentStepIndex = _steps.length - 1;
          _progress = 1.0;
          _isCompleted = true;
          _hasError = false;
        });
      } else {
        debugPrint('[GeneratingScreen] FAILURE - setting error state');
        setState(() {
          _hasError = true;
          _isCompleted = false;
        });
      }
    });
  }

  void _triggerRetry() {
    _startGeneration();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentStep = _steps[_currentStepIndex];

    return BaseAppScreen(
      title: 'Generating Assessment...',
      routeName: AppRoutes.generating,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Orbital Progress Animation Container
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _hasError ? Icons.error_outline : Icons.auto_awesome,
                      color: _hasError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      size: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Status Heading
              Text(
                _hasError
                    ? 'Generation Encountered an Error'
                    : _isCompleted
                        ? 'Assessment Generation Complete!'
                        : currentStep['title']!,
                key: const Key('txt_generating_status'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _hasError
                    ? 'Failed to connect to assessment generation service.'
                    : currentStep['subtitle']!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error Banner with Retry
              if (_hasError) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          Provider.of<AssessmentProvider>(context,
                                      listen: false)
                                  .errorMessage ??
                              'Connection timeout or server error. Please try again.',
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('btn_retry_generation'),
                  onPressed: _triggerRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Generation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                ),
              ] else ...[
                // Steps Indicator List
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerLowest
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: List.generate(_steps.length, (idx) {
                      final isPast = idx < _currentStepIndex || _isCompleted;
                      final isCurr = idx == _currentStepIndex && !_isCompleted;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isPast
                                  ? Icons.check_circle
                                  : isCurr
                                      ? Icons.sync
                                      : Icons.radio_button_unchecked,
                              color: isPast
                                  ? const Color(0xFF006E2C)
                                  : isCurr
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _steps[idx]['title']!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isPast || isCurr
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 28),

                // View Draft Result Button - ONLY shown after backend generation finishes successfully
                if (_isCompleted)
                  ElevatedButton.icon(
                    key: const Key('btn_view_draft_result'),
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.review),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('View Draft Result'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'AI Assessment generation in progress...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
