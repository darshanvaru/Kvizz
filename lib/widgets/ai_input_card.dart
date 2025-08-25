import 'package:flutter/material.dart';

class PromptInputCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onGeneratePressed;

  const PromptInputCard({
    super.key,
    required this.controller,
    required this.onGeneratePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF8F9FA)
                : Theme.of(context).colorScheme.surface,
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
                  // color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: "Type your prompt here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  // fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onGeneratePressed,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  "Generate",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}