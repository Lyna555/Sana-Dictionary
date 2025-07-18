import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../models/text_model.dart';
import '../models/word_model.dart';
import '../models/user_model.dart';
import '../services/text_service.dart';
import '../services/word_service.dart';
import '../services/profile_service.dart';
import '../main.dart';
import 'login_page.dart';
import 'views/texts_view.dart';
import 'views/words_view.dart';
import 'views/profile_view.dart';
import 'views/fields_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<SanaText>>? _textsFuture;
  Future<List<SanaWord>>? _wordsFuture;
  SanaUser? _user;

  int? selectedTextId;
  String? selectedTextTitle;
  String? selectedField;
  bool _isProfileView = false;
  bool _hasInternet = true;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    final user = await ProfileService.getUserProfile();
    setState(() {
      _user = user;
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  void onFieldSelected(String field) {
    setState(() {
      selectedField = field;
      _textsFuture = TextService.getAllTexts(field);
    });
  }

  void selectText(int textId, String title) {
    setState(() {
      selectedTextId = textId;
      selectedTextTitle = title;
      _wordsFuture = WordService.getTextWords(textId);
      _isProfileView = false;
    });
  }

  void goBackToTexts() {
    setState(() {
      selectedTextId = null;
      selectedTextTitle = null;
      _wordsFuture = null;
      _isProfileView = false;
      selectedField = null; // Reset to FieldsView
    });
  }

  void showProfile() {
    setState(() {
      selectedTextId = null;
      selectedTextTitle = null;
      _wordsFuture = null;
      _isProfileView = true;
    });
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(93, 151, 144, 1.0),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _confirmLogout(context),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          showProfile();
                        },
                        child: CircleAvatar(
                          radius: 35,
                          backgroundImage: _user?.photoUrl != null
                              ? NetworkImage(_user!.photoUrl!)
                              : const AssetImage('assets/images/user.png')
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _user?.username ?? "",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('الصفحة الرئيسية',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            tileColor: _getTileColor(),
            iconColor: const Color.fromRGBO(214, 177, 99, 1.0),
            onTap: () {
              Navigator.pop(context);
              goBackToTexts();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('بخصوص التطبيق',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            iconColor: const Color.fromRGBO(214, 177, 99, 1.0),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'معجم سنا',
                applicationVersion: '1.0.0',
                children: const [
                  Text(
                      'هذا التطبيق يوفر شرحًا للكلمات الصعبة في نصوص كتب اللغة العربية الخاصة بطور الثانوية.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('تواصل معنا',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            iconColor: const Color.fromRGBO(214, 177, 99, 1.0),
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'bouglina3@gmail.com',
                query: Uri.encodeFull('subject=معجم سنا - استفسار أو اقتراح'),
              );

              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(
                  emailLaunchUri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تعذر فتح تطبيق البريد الإلكتروني')),
                  );
                }
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              themeNotifier.value == ThemeMode.dark
                  ? 'الوضع النهاري'
                  : 'الوضع الليلي',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            secondary: Icon(themeNotifier.value == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (bool value) async {
              final prefs = await SharedPreferences.getInstance();
              final mode = value ? ThemeMode.dark : ThemeMode.light;
              setState(() => themeNotifier.value = mode);
              await prefs.setString('themeMode', value ? 'dark' : 'light');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('تأكيد'),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color? _getTileColor() {
    return themeNotifier.value == ThemeMode.dark
        ? Colors.grey[700]
        : Colors.grey[200];
  }

  Future<bool> _handleBackPress() async {
    if (selectedTextId != null) {
      setState(() {
        selectedTextId = null;
        selectedTextTitle = null;
        _wordsFuture = null;
      });
      return false;
    } else if (selectedField != null) {
      setState(() {
        selectedField = null;
        _textsFuture = null;
      });
      return false;
    } else if (_isProfileView) {
      setState(() {
        _isProfileView = false;
      });
      return false;
    } else {
      DateTime now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
        _lastBackPressed = now;
        Fluttertoast.showToast(
          msg: "اضغط مرة أخرى للخروج من التطبيق",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.7),
          textColor: Colors.white,
          fontSize: 14,
        );
        return false;
      }
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        drawer: _buildDrawer(context),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 30),
              color: Colors.white,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            selectedTextTitle ??
                (_isProfileView
                    ? 'الملف الشخصي'
                    : selectedField == null
                        ? 'الصفحة الرئيسية'
                        : 'قائمة النصوص'),
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromRGBO(93, 151, 144, 1.0),
          actions: (selectedTextId != null ||
                  _isProfileView ||
                  selectedField != null)
              ? [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      if (selectedTextId != null) {
                        // Back from Words View to Texts View
                        setState(() {
                          selectedTextId = null;
                          selectedTextTitle = null;
                          _wordsFuture = null;
                        });
                      } else if (selectedField != null || _isProfileView) {
                        // Back from Texts View or Profile to Fields View
                        setState(() {
                          selectedField = null;
                          _textsFuture = null;
                          _isProfileView = false;
                        });
                      }
                    },
                  )
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareApp,
                  )
                ],
        ),
        body: _isProfileView
            ? const ProfileView()
            : selectedTextId != null
                ? _buildWordsList()
                : selectedField == null
                    ? FieldsView(onFieldSelected: onFieldSelected)
                    : _buildTextList(),
      ),
    );
  }

  void _shareApp() {
    Share.share('https://play.google.com/store/apps/details?id=dev.voksu.hizo');
  }

  Widget _buildTextList() {
    if (!_hasInternet) return _buildNoInternetWidget();

    return FutureBuilder<List<SanaText>>(
      future: _textsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorWidget();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/box.png",
                scale: 2.5,
              ),
              const Text('لا توجد نصوص')
            ],
          ));
        }

        return TextsView(
          texts: snapshot.data!,
          onTextSelected: selectText,
          onReload: () {
            if (selectedField != null) {
              setState(() {
                _textsFuture = TextService.getAllTexts(selectedField!);
              });
            }
          },
        );
      },
    );
  }

  Widget _buildWordsList() {
    if (!_hasInternet) return _buildNoInternetWidget();

    return FutureBuilder<List<SanaWord>>(
      future: _wordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorWidget();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد كلمات'));
        }

        return WordsView(
          words: snapshot.data!,
          textTitle: selectedTextTitle ?? '',
          onBack: goBackToTexts,
          onReload: () {
            setState(() {
              _wordsFuture = WordService.getTextWords(selectedTextId!);
            });
          },
        );
      },
    );
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/no-internet.png', width: 180),
          const SizedBox(height: 16),
          const Text(
            'يرجى التحقق من اتصالك بالإنترنت',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/internal-error.png', width: 180),
          const SizedBox(height: 16),
          const Text(
            'خلل في النظام!\nيرجى إعادة المحاولة لاحقًا',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
