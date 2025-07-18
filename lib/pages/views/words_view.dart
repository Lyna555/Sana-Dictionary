import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/word_model.dart';

class WordsView extends StatefulWidget {
  final List<SanaWord> words;
  final String textTitle;
  final VoidCallback onBack;
  final VoidCallback onReload;

  const WordsView({
    super.key,
    required this.words,
    required this.textTitle,
    required this.onBack,
    required this.onReload,
  });

  @override
  State<WordsView> createState() => _WordsViewState();
}

class _WordsViewState extends State<WordsView> with TickerProviderStateMixin {
  late List<SanaWord> filteredWords;
  final TextEditingController _searchController = TextEditingController();
  late List<AnimationController> _controllers;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    filteredWords = widget.words;
    _speech = stt.SpeechToText();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(widget.words.length, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      Future.delayed(Duration(milliseconds: 80 * index), () {
        if (mounted) controller.forward();
      });
      return controller;
    });
  }

  String normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll(RegExp(r'ة'), 'ه')
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  }

  void filterWords(String query) {
    final normalizedQuery = normalizeArabic(query.toLowerCase());

    setState(() {
      filteredWords = widget.words.where((word) {
        final normalizedWord = normalizeArabic(word.word.toLowerCase());
        return normalizedWord.contains(normalizedQuery);
      }).toList();
    });
  }

  Future<void> _startListening() async {
    var permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى منح إذن استخدام الميكروفون')),
        );
        return;
      }
    }

    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: 'ar-DZ',
        onResult: (result) {
          _searchController.text = result.recognizedWords;
          filterWords(result.recognizedWords);
        },
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التعرف على الصوت غير متاح')),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onReload(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                labelText: 'ابحث عن كلمة',
                labelStyle: const TextStyle(fontSize: 15),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    _isListening ? _stopListening() : _startListening();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: filterWords,
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredWords.length,
              itemBuilder: (context, index) {
                final word = filteredWords[index];
                final controller = index < _controllers.length
                    ? _controllers[index]
                    : AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 400),
                      )
                  ..forward();

                final opacity = Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: controller, curve: Curves.easeOut),
                );

                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: controller, curve: Curves.easeOut),
                );

                return FadeTransition(
                  opacity: opacity,
                  child: SlideTransition(
                    position: offset,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${word.word}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(214, 177, 99, 1.0),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(
                              'شرحها: ${word.explanation}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(
                              'توظيفها: ${word.example}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
