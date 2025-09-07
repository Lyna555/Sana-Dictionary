import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/text_model.dart';

class TextsView extends StatefulWidget {
  final List<SanaText> texts;
  final Function(int, String) onTextSelected;
  final VoidCallback onReload;

  const TextsView({
    super.key,
    required this.texts,
    required this.onTextSelected,
    required this.onReload,
  });

  @override
  State<TextsView> createState() => _TextsViewState();
}

class _TextsViewState extends State<TextsView> with TickerProviderStateMixin {
  late List<SanaText> filteredTexts;
  final TextEditingController _searchController = TextEditingController();
  late List<AnimationController> _controllers = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    filteredTexts = widget.texts;
    _speech = stt.SpeechToText();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(widget.texts.length, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      Future.delayed(Duration(milliseconds: 100 * index), () {
        if (mounted) controller.forward();
      });
      return controller;
    });
  }

  String normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll(RegExp(r'ة'), 'ه')
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '');
  }

  void filterTexts(String query) {
    final normalizedQuery = normalizeArabic(query.toLowerCase());

    setState(() {
      filteredTexts = widget.texts.where((text) {
        final normalizedTitle = normalizeArabic(text.title.toLowerCase());
        return normalizedTitle.contains(normalizedQuery);
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
          filterTexts(result.recognizedWords);
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
    return Scaffold(
      body: Column(
        children: [
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: const Text(
              'قائمة النصوص',
              style: TextStyle(
                color: Color.fromRGBO(214, 177, 99, 1.0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                labelText: 'ابحث عن نص',
                labelStyle: const TextStyle(fontSize: 14),
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
              onChanged: filterTexts,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => widget.onReload(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredTexts.length,
                itemBuilder: (context, index) {
                  final text = filteredTexts[index];
                  final controller = index < _controllers.length
                      ? _controllers[index]
                      : AnimationController(
                    vsync: this,
                    duration: const Duration(milliseconds: 400),
                  )..forward();

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
                      child: GestureDetector(
                        onTap: () =>
                            widget.onTextSelected(text.id, text.title),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              opacity: 0.7,
                              image: NetworkImage(text.photoURL ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        text.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        text.author ?? '-',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ],
                            )
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
