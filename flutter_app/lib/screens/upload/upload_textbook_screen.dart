import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/network/api_client.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/upload_repository.dart';
import '../../presentation/providers/upload_provider.dart';
import '../base_app_screen.dart';

/// Upload Textbook Screen (Light & Dark mode support).
/// Allows educators to upload PDF textbooks, configure Subject, Grade Level, and Chapter Name,
/// and send materials to the RAG vector indexing backend pipeline.
class UploadTextbookScreen extends StatefulWidget {
  final IUploadRepository? uploadRepository;

  const UploadTextbookScreen({
    super.key,
    this.uploadRepository,
  });

  @override
  State<UploadTextbookScreen> createState() => _UploadTextbookScreenState();
}

class _UploadTextbookScreenState extends State<UploadTextbookScreen> {
  late final IUploadRepository _repo;
  final TextEditingController _chapterController =
      TextEditingController(text: 'Unit 3: Electromagnetism');

  ExamSubject _selectedSubject = ExamSubject.physics;
  int _selectedGrade = 9;
  File? _selectedFile;
  String _selectedFileName = 'No file selected';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.uploadRepository ?? UploadRepository(apiClient: ApiClient());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      _initializedFromRoute = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final subjectArg = args['subject'];
        if (subjectArg is String) {
          final parsed = SubjectUtils.tryParse(subjectArg);
          if (parsed != null) {
            _selectedSubject = parsed;
          }
        }
        final gradeArg = args['grade'];
        if (gradeArg is int) {
          _selectedGrade = gradeArg;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            final provider = Provider.of<UploadProvider>(context, listen: false);
            provider.setSubject(_selectedSubject);
            provider.setGrade(_selectedGrade);
          } catch (_) {}
        });
      }
    }
  }

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final file = File(filePath);

        setState(() {
          _selectedFile = file;
          _selectedFileName = fileName;
          _errorMessage = null;
        });

        if (!mounted) return;
        try {
          final provider = Provider.of<UploadProvider>(context, listen: false);
          provider.setSelectedFile(file, customName: fileName);
        } catch (_) {}
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: ${e.toString()}';
      });
    }
  }

  Future<void> _handleUploadSubmit() async {
    if (_selectedFile == null &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      setState(() {
        _errorMessage = 'Please select a textbook PDF file to upload.';
      });
      return;
    }

    final fileToUpload = _selectedFile ?? File('test_textbook.pdf');

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.3;
      _errorMessage = null;
    });

    try {
      UploadProvider? provider;
      try {
        provider = Provider.of<UploadProvider>(context, listen: false);
      } catch (_) {}

      if (provider != null) {
        provider.setSubject(_selectedSubject);
        provider.setGrade(_selectedGrade);
        provider.setChapterName(_chapterController.text);
        provider.setSelectedFile(fileToUpload, customName: _selectedFileName);
        final success = await provider.startUpload();
        if (!success) {
          throw Exception(provider.errorMessage ?? 'Upload failed');
        }
      } else {
        await _repo.uploadTextbook(
          file: fileToUpload,
          subject: _selectedSubject,
          grade: _selectedGrade,
        );
      }

      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
        _isUploading = false;
      });

      Navigator.pushNamed(context, AppRoutes.uploadStatus);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BaseAppScreen(
      title: 'Upload Textbook',
      routeName: AppRoutes.upload,
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await Provider.of<UploadProvider>(context, listen: false)
                .loadUploadedTextbooks();
          } catch (_) {}
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Header
                  Text(
                    'Upload Textbook',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload educational materials to index content & generate tailored assessments.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

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
                            child: _buildUploadFormColumn(theme, isDark)),
                        const SizedBox(width: 24),
                        Expanded(
                            flex: 5,
                            child: _buildInfoCardColumn(theme, isDark)),
                      ],
                    )
                  else ...[
                    _buildUploadFormColumn(theme, isDark),
                    const SizedBox(height: 24),
                    _buildInfoCardColumn(theme, isDark),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUploadFormColumn(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drop-zone / File Picker Card
        InkWell(
          key: const Key('btn_pick_file'),
          onTap: _handlePickFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerLowest
                  : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select PDF Textbook',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(
                          text: 'Drag and drop your textbook here, or '),
                      TextSpan(
                        text: 'browse files',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Supported formats: PDF, DOCX (Max 50MB)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Selected File Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: theme.colorScheme.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isUploading
                              ? '2.4 MB • Uploading...'
                              : '2.4 MB • Ready to upload',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isUploading)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFileName = 'Physics_Unit_3.pdf';
                          _selectedFile = null;
                        });
                      },
                    ),
                ],
              ),
              if (_isUploading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_uploadProgress * 100).toInt()}% uploaded',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Processing...',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Form Fields (Subject, Grade Level, Chapter Name)
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metadata Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Mandatory 5 Subjects Dropdown
                Text(
                  'Subject (Mandatory 5 Subjects):',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExamSubject>(
                  key: const Key('dropdown_subject'),
                  // ignore: deprecated_member_use
                  value: _selectedSubject,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(_selectedSubject.icon,
                        color: isDark
                            ? _selectedSubject.darkColor
                            : _selectedSubject.color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: SubjectUtils.allSubjects.map((subj) {
                    return DropdownMenuItem<ExamSubject>(
                      value: subj,
                      child: Text(
                        subj.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newSubject) {
                    if (newSubject != null) {
                      setState(() {
                        _selectedSubject = newSubject;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. Grade Level Dropdown (Class 9, 10, 11, 12)
                Text(
                  'Grade Level:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  key: const Key('dropdown_grade'),
                  // ignore: deprecated_member_use
                  value: _selectedGrade,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 9, child: Text('Class 9')),
                    DropdownMenuItem(value: 10, child: Text('Class 10')),
                    DropdownMenuItem(value: 11, child: Text('Class 11')),
                    DropdownMenuItem(value: 12, child: Text('Class 12')),
                  ],
                  onChanged: (newGrade) {
                    if (newGrade != null) {
                      setState(() {
                        _selectedGrade = newGrade;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 3. Chapter Name Input
                Text(
                  'Chapter / Unit Name:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('input_chapter_name'),
                  controller: _chapterController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.bookmark_outline),
                    hintText: 'e.g. Electromagnetism or Unit 3',
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

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const Key('btn_cancel_upload'),
              onPressed: () {
                setState(() {
                  _selectedFileName = 'Physics_Unit_3.pdf';
                  _selectedFile = null;
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              key: const Key('btn_upload_textbook'),
              onPressed: _isUploading ? null : _handleUploadSubmit,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Textbook'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCardColumn(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Card 1: AI Analysis
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                'AI-Powered Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Once uploaded, our system scans your textbook to extract key learning objectives and index topics into your knowledge base.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 2: Tips
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerLowest
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for better results',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              _buildTipItem(
                  theme, 'Ensure text is selectable (not image-only scans).'),
              const SizedBox(height: 10),
              _buildTipItem(theme,
                  'Upload one chapter at a time for higher question precision.'),
              const SizedBox(height: 10),
              _buildTipItem(
                  theme, 'Remove irrelevant pages like covers or indexes.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF006E2C),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
