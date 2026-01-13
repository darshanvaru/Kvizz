import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:kvizz/api_endpoints.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/tab_index_provider.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _uploadPromptController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  String? _selectedFileName;
  String? _selectedFileType;
  String? _fileError;
  PlatformFile? _selectedFile;

  bool _isGenerating = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _uploadPromptController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onGeneratePressed() async {
    try {
      setState(() => _isGenerating = true);
      final prompt = _promptController.text.trim();
      if (prompt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a prompt.")));
        return;
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.medusaAIGenerateFromPrompt),
        body: {'prompt': prompt},
      );

      if (response.statusCode == 200) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text("Quiz generated! Check MyQuiz Tab."),
            action: SnackBarAction(
              label: "My Quiz",
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Provider.of<TabIndexProvider>(context, listen: false).updateSelectedIndex(1);
              },
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        }
      } else {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to generate quiz")));
        }      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }    } finally {
      _promptController.clear();
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _pickFile() async {
    setState(() => _fileError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _selectedFileName = _selectedFile!.name;
          _selectedFileType = _selectedFile!.extension;
        });
      }
    } catch (e) {
      setState(() => _fileError = 'Failed to pick file: ${e.toString()}');
    }
  }

  void _onUploadGeneratePressed() async {
    setState(() => _isUploading = true);
    try {
      final prompt = _uploadPromptController.text.trim();
      if (_selectedFile == null) {
        setState(() {
          _fileError = 'Please select a PDF or CSV file.';
          _isUploading = false;
        });
        return;
      }
      if (prompt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a prompt.')));
        setState(() => _isUploading = false);
        return;
      }

      final url = Uri.parse(ApiEndpoints.medusaAIGenerateFromFile);
      var request = http.MultipartRequest('POST', url);
      request.fields['prompt'] = prompt;
      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path!));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint("🎉 Quiz JSON from file: $jsonData");
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server error: ${response.statusCode}")));
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error: $e")));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prompt Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text("Enter Your Prompt", style: theme.textTheme.titleLarge),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _promptController,
                          enabled: !_isGenerating,
                          maxLines: 4,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText: "Type your keywords...\nExample: 'Math Quiz for Class 10'",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _onGeneratePressed,
                          icon: _isGenerating
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isGenerating ? "Generating..." : "Generate"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // File Upload Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text("Upload PDF or CSV", style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: Text(_selectedFileName ?? 'Choose File'),
                                onPressed: _pickFile,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: colorScheme.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            if (_selectedFileType != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Chip(
                                  label: Text(_selectedFileType!.toUpperCase()),
                                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                                ),
                              ),
                          ],
                        ),
                        if (_fileError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _fileError!,
                              style: TextStyle(color: colorScheme.error, fontSize: 13),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _uploadPromptController,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText: "Write a custom prompt for your file...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _onUploadGeneratePressed,
                          icon: _isUploading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isUploading ? "Generating..." : "Generate from File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
