import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  SanaUser? _user;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _initialUsername;
  String? _initialEmail;
  bool _hasChanged = false;
  bool _isLoading = false;
  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ProfileService.getUserProfile();
      _initialUsername = user.username ?? '';
      _initialEmail = user.email ?? '';

      _usernameController.text = _initialUsername!;
      _emailController.text = _initialEmail!;

      _usernameController.addListener(_checkForChanges);
      _emailController.addListener(_checkForChanges);

      setState(() {
        _user = user;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _checkForChanges() {
    final hasChanged = _usernameController.text.trim() != _initialUsername ||
        _emailController.text.trim() != _initialEmail;

    if (_hasChanged != hasChanged) {
      setState(() => _hasChanged = hasChanged);
    }
  }

  Future<void> _updateUser() async {
    setState(() => _isLoading = true);
    try {
      await ProfileService.updateUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );
      _initialUsername = _usernameController.text.trim();
      _initialEmail = _emailController.text.trim();
      _hasChanged = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم التحديث بنجاح")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في التحديث: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isStrongPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    return regex.hasMatch(password);
  }

  bool _canChangePassword() {
    return _oldPasswordController.text.trim().isNotEmpty &&
        _isStrongPassword(_newPasswordController.text.trim()) &&
        _newPasswordController.text.trim() ==
            _confirmPasswordController.text.trim();
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("كلمة المرور الجديدة غير متطابقة")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ProfileService.changePassword(oldPass, newPass);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث كلمة المرور بنجاح")),
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في تغيير كلمة المرور: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف الحساب؟"),
        actions: [
          TextButton(
              child: const Text("إلغاء"),
              onPressed: () => Navigator.pop(context, false)),
          TextButton(
              child: const Text("تأكيد"),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ProfileService.deleteUser();
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل في حذف الحساب: $e")),
        );
      }
    }
  }

  Future<void> _pickImageAndUpload() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _newImageFile = File(pickedFile.path);
    });

    setState(() => _isLoading = true);
    try {
      await ProfileService.uploadProfilePhoto(File(pickedFile.path));
      final updatedUser = await ProfileService.getUserProfile();
      setState(() {
        _user = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث الصورة بنجاح")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في تحميل الصورة: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickImageAndUpload,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _newImageFile != null
                      ? FileImage(_newImageFile!)
                      : (_user?.photoUrl != null
                          ? NetworkImage(_user!.photoUrl!)
                          : const AssetImage('assets/images/user.png')
                              as ImageProvider),
                ),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.edit, size: 16, color: Colors.black),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _user?.username ?? '',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
          ExpansionTile(
            title: const Text("معلومات الحساب"),
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _hasChanged ? _updateUser : null,
                      child: const Text("تحديث الحساب"),
                    ),
            ],
          ),
          if (_user?.type == "eleve")
            ExpansionTile(
              title: const Text("المستوى الدراسي و الشعبة"),
              children: [
                TextFormField(
                  initialValue: "${_user?.level ?? ''} ثانوي",
                  decoration:
                      const InputDecoration(labelText: 'المستوى الدراسي'),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _user?.field == "lettres" ? "آداب" : "علوم",
                  decoration: const InputDecoration(labelText: 'الشعبة'),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
              ],
            )
          else
            const SizedBox.shrink(),
          ExpansionTile(
            title: const Text("تغيير كلمة المرور"),
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'كلمة المرور القديمة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  errorText: _isStrongPassword(_newPasswordController.text) ||
                          _newPasswordController.text.isEmpty
                      ? null
                      : 'كلمة المرور ضعيفة. يجب أن تكون على الأقل 8 حروف وتحتوي على أرقام وحروف',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  errorText: _newPasswordController.text ==
                              _confirmPasswordController.text ||
                          _confirmPasswordController.text.isEmpty
                      ? null
                      : 'كلمتا المرور غير متطابقتين',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _canChangePassword() ? _changePassword : null,
                child: const Text("تحديث كلمة المرور"),
              ),
              const SizedBox(height: 12),
            ],
          ),
          Divider(color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
                onPressed: _deleteUser,
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text("حذف الحساب",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
          ),
        ],
      ),
    );
  }
}
