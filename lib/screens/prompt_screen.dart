import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/tab_index_provider.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({Key? key}) : super(key: key);

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen>
    with SingleTickerProviderStateMixin {
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
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter a prompt.")));
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.67.181:8000/generate'),
        body: {'prompt': prompt},
      );

      if (response.statusCode == 200) {
        final quizData = jsonDecode(response.body);
        print("✅ AI Output: $quizData");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Quiz generated!, you can check your quiz in MyQuiz Tab",
            ),
            action: SnackBarAction(
              label: "My Quiz",
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Provider.of<SelectedIndexProvider>(
                  context,
                  listen: false,
                ).updateSelectedIndex(1);
              },
              textColor: Colors.white,
            ),
            backgroundColor: Colors.blueAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate quiz")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      _promptController.text = "";
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _fileError = null;
    });
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
      setState(() {
        _fileError = 'Failed to pick file: ${e.toString()}';
      });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a prompt.')));
        setState(() => _isUploading = false);
        return;
      }

      final url = Uri.parse("http://192.168.67.181:8000/generate-from-file");
      var request = http.MultipartRequest('POST', url);
      request.fields['prompt'] = prompt;
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path!),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("🎉 Quiz JSON from file: $jsonData");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Enter Your Prompt",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _promptController,
                          enabled: _isGenerating ? false : true,
                          maxLines: 4,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText: "Type your Keywords here... \nExample: \"Mathematics Quiz\"",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _onGeneratePressed,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isGenerating ? "Generating..." : "Generate",
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Upload PDF or CSV",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: Text(_selectedFileName ?? 'Choose File'),
                                onPressed: _pickFile,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(color: Colors.blueAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedFileType != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Chip(
                                  label: Text(_selectedFileType!.toUpperCase()),
                                  backgroundColor: Colors.blue[50],
                                ),
                              ),
                          ],
                        ),
                        if (_fileError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _fileError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _uploadPromptController,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText: "Write a custom prompt for your file...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : _onUploadGeneratePressed,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isUploading
                                ? "Generating..."
                                : "Generate from File",
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
