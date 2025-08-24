import 'package:flutter/material.dart';

class FieldsView extends StatefulWidget {
  final void Function(String field) onFieldSelected;

  const FieldsView({Key? key, required this.onFieldSelected}) : super(key: key);

  @override
  State<FieldsView> createState() => _FieldsViewState();
}

class _FieldsViewState extends State<FieldsView> with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _titleController;
  late AnimationController _buttonsController;

  late Animation<double> _cardScale;
  late Animation<double> _titleFade;
  late Animation<double> _buttonsScale;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _titleFade =
        CurvedAnimation(parent: _titleController, curve: Curves.easeIn);

    // 👇 Button pop-up scale animation
    _buttonsScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutBack),
    );

    // Sequential animation start
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _titleController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          _buttonsController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _titleController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ScaleTransition(
              scale: _cardScale,
              child: Card(
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(145, 204, 200, 1.0),
                        Color.fromRGBO(225, 199, 143, 1.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_bordred.png',
                        height: 150,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'رفيقك لفهم لغة الضاد',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 3,
                            ),
                            Shadow(
                              color: Color.fromRGBO(214, 177, 99, 1.0),
                              offset: Offset(-1, -1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                FadeTransition(
                  opacity: _titleFade,
                  child: const Text(
                    'اختر الشعبة',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
                ScaleTransition(
                  scale: _buttonsScale,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFieldButton(
                        label: 'علوم',
                        image: 'assets/images/science.png',
                        gradientColors: [
                          const Color.fromRGBO(178, 250, 250, 1.0),
                          const Color.fromRGBO(128, 222, 234, 1.0),
                        ],
                        onTap: () => widget.onFieldSelected('science'),
                      ),
                      const SizedBox(width: 20),
                      _buildFieldButton(
                        label: 'آداب',
                        image: 'assets/images/lettre.png',
                        gradientColors: [
                          const Color.fromRGBO(255, 220, 200, 1.0),
                          const Color.fromRGBO(255, 204, 128, 1.0),
                        ],
                        onTap: () => widget.onFieldSelected('lettres'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFieldButton({
    required String label,
    required String image,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 50),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
