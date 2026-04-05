import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'homepage.dart';
import 'pending_approval_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _teacherSubject = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  String _selectedRole = 'student';
  PlatformFile? _degreeCertificateFile;
  Uint8List? _degreeCertificateBytes;
  PlatformFile? _teachingLicenseFile;
  Uint8List? _teachingLicenseBytes;
  PlatformFile? _transcriptFile;
  Uint8List? _transcriptBytes;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _teacherSubjectError;
  String? _degreeCertificateError;
  String? _teachingLicenseError;
  String? _transcriptError;

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _teacherSubjectError = null;
      _degreeCertificateError = null;
      _teachingLicenseError = null;
      _transcriptError = null;

      if (_name.text.trim().isEmpty) {
        _nameError = "Please enter your full name";
        valid = false;
      }

      if (_email.text.trim().isEmpty) {
        _emailError = "Please enter your email address";
        valid = false;
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email.text.trim())) {
        _emailError = "Please enter a valid email address";
        valid = false;
      }

      if (_password.text.isEmpty) {
        _passwordError = "Please create a password";
        valid = false;
      } else {
        final p = _password.text;
        if (p.length < 6) {
          _passwordError = "Password must be at least 6 characters";
          valid = false;
        } else if (!p.contains(RegExp(r'[a-z]'))) {
          _passwordError = "Must include at least one lowercase letter (a-z)";
          valid = false;
        } else if (!p.contains(RegExp(r'[A-Z]'))) {
          _passwordError = "Must include at least one uppercase letter (A-Z)";
          valid = false;
        } else if (!p.contains(RegExp(r'[0-9]'))) {
          _passwordError = "Must include at least one number (0-9)";
          valid = false;
        } else if (!p.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) {
          _passwordError =
              "Must include at least one special character (@, #, \$, %, etc.)";
          valid = false;
        }
      }

      if (_selectedRole == 'teacher') {
        if (_teacherSubject.text.trim().isEmpty) {
          _teacherSubjectError = "Please enter your teaching subject";
          valid = false;
        }

        if (_degreeCertificateFile == null || _degreeCertificateBytes == null) {
          _degreeCertificateError = "Please upload your degree certificate";
          valid = false;
        }
        if (_teachingLicenseFile == null || _teachingLicenseBytes == null) {
          _teachingLicenseError = "Please upload your teaching license";
          valid = false;
        }
        if (_transcriptFile == null || _transcriptBytes == null) {
          _transcriptError = "Please upload your transcript";
          valid = false;
        }
      }
    });
    return valid;
  }

  void _showNetworkError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 40, color: Color(0xFFE53935)),
              ),
              const SizedBox(height: 20),
              const Text("No Internet Connection",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Please check your connection and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Try Again",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 40, color: Color(0xFFE53935)),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Got it",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F8F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 40, color: Color(0xFF43A047)),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Continue",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPasswordStrength(String p) {
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[a-z]'))) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) score++;
    if (score <= 2) return "Weak";
    if (score <= 3) return "Fair";
    if (score == 4) return "Good";
    return "Strong";
  }

  Color _getStrengthColor(String strength) {
    switch (strength) {
      case "Weak":
        return const Color(0xFFE53935);
      case "Fair":
        return const Color(0xFFFF9800);
      case "Good":
        return const Color(0xFF2196F3);
      case "Strong":
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickDocument({
    required void Function(PlatformFile file, Uint8List bytes) onPicked,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) return;

    setState(() {
      onPicked(picked, bytes);
    });
  }

  Future<void> _doSignup() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _teacherSubjectError = null;
      _degreeCertificateError = null;
      _teachingLicenseError = null;
      _transcriptError = null;
    });

    if (!_validate()) return;

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

	      await credential.user!.updateDisplayName(_name.text.trim());
	
	      if (credential.user != null) {
	        final String? firebaseIdToken = await credential.user!.getIdToken();
	        if (firebaseIdToken == null) {
	          throw Exception('Failed to get Firebase ID token');
	        }
	        final approvalStatus =
	            _selectedRole == 'teacher' ? 'pending' : 'approved';
	
final user = await ApiService.registerUserWithDocument(
            firebaseIdToken: firebaseIdToken,
            uid: credential.user!.uid,
            email: _email.text.trim(),
            name: _name.text.trim(),
            role: _selectedRole,
            approvalStatus: approvalStatus,
            teacherSubject:
                _selectedRole == 'teacher' ? _teacherSubject.text.trim() : null,
            
            // 👇 เอา ! ออกให้หมด แล้วใช้ ? สำหรับดึงชื่อไฟล์แทน
            degreeCertificateBytes:
                _selectedRole == 'teacher' ? _degreeCertificateBytes : null,
            degreeCertificateUrl:
                _selectedRole == 'teacher' ? _degreeCertificateFile?.name : null,
            
            teachingLicenseBytes:
                _selectedRole == 'teacher' ? _teachingLicenseBytes : null,
            teachingLicenseUrl:
                _selectedRole == 'teacher' ? _teachingLicenseFile?.name : null,
            
            transcriptBytes: 
                _selectedRole == 'teacher' ? _transcriptBytes : null,
            transcriptUrl:
                _selectedRole == 'teacher' ? _transcriptFile?.name : null,
          );

        if (!mounted) return;

        final enriched = {
          ...user,
          'name': user['name'] ?? user['displayName'] ?? _name.text.trim(),
        };

        if (_selectedRole == 'teacher') {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(userData: enriched)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'email-already-in-use':
          setState(() => _emailError = "An account with this email already exists");
          break;

        case 'weak-password':
          setState(() => _passwordError = "Password must be at least 6 characters");
          break;

        case 'invalid-email':
          setState(() => _emailError = "Please enter a valid email address");
          break;

        case 'network-request-failed':
          _showNetworkError();
          break;

        case 'too-many-requests':
          _showErrorDialog(
            "Too Many Attempts",
            "Please wait a moment before trying again.",
          );
          break;

        default:
          _showErrorDialog(
            "Sign Up Failed",
            e.message ?? "An unexpected error occurred. Please try again.",
          );
      }
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        _showNetworkError();
      } else {
        final display = e.toString().replaceFirst('Exception: ', '');
        _showErrorDialog(
          "Something went wrong",
          display.isNotEmpty ? display : "An unexpected error occurred. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
    bool obscure = false,
    bool showToggle = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: errorText != null
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFF1F2F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFE53935)
                    : const Color(0xFF4A6CF7),
                width: 1.5,
              ),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRole == value;

    return Expanded(
      child: InkWell(
	        onTap: () {
	          setState(() {
	            _selectedRole = value;
	            _teacherSubjectError = null;
	            _degreeCertificateError = null;
	            _teachingLicenseError = null;
	            _transcriptError = null;
	          });
	        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF3FF) : const Color(0xFFF1F2F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF4A6CF7) : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFF4A6CF7) : Colors.grey[700],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPicker({
    required String title,
    required PlatformFile? file,
    required String? errorText,
    required VoidCallback? onTap,
  }) {
    final hasFile = file != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: errorText != null
                  ? const Color(0xFFFFF0F0)
                  : const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFE53935)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasFile
                        ? Icons.description_outlined
                        : Icons.upload_file_outlined,
                    color: const Color(0xFF4A6CF7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasFile ? file!.name : "Upload PDF/JPG/PNG",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasFile
                            ? "Tap to change file"
                            : "Accepted: PDF, JPG, JPEG, PNG",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _teacherSubject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedRole == 'teacher'
                        ? "Apply as a teacher and wait for approval"
                        : "Join us and start learning today",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "I want to join as",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleOption(
                        value: "student",
                        icon: Icons.school_outlined,
                        title: "Student",
                        subtitle: "Start learning right away",
                      ),
                      const SizedBox(width: 12),
                      _buildRoleOption(
                        value: "teacher",
                        icon: Icons.menu_book_outlined,
                        title: "Teacher",
                        subtitle: "Submit documents for review",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _name,
                    label: "Full Name",
                    hint: "Your name",
                    errorText: _nameError,
                    onChanged: (_) => setState(() => _nameError = null),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _email,
                    label: "Email address",
                    hint: "example@gmail.com",
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _emailError = null),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _password,
                    label: "Password",
                    hint: "At least 6 characters",
                    errorText: _passwordError,
                    obscure: _obscurePassword,
                    showToggle: true,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onChanged: (_) => setState(() => _passwordError = null),
                  ),
                  if (_password.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Builder(builder: (_) {
                      final strength = _getPasswordStrength(_password.text);
                      final color = _getStrengthColor(strength);
                      final score = [
                        _password.text.length >= 8,
                        _password.text.contains(RegExp(r'[a-z]')),
                        _password.text.contains(RegExp(r'[A-Z]')),
                        _password.text.contains(RegExp(r'[0-9]')),
                        _password.text
                            .contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]')),
                      ].where((e) => e).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i < score
                                        ? color
                                        : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Password strength: $strength",
                            style: TextStyle(fontSize: 12, color: color),
                          ),
                        ],
                      );
                    }),
                  ],
                  if (_selectedRole == 'teacher') ...[
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _teacherSubject,
                      label: "Teaching Subject",
                      hint: "English, Math, Science...",
                      errorText: _teacherSubjectError,
                      onChanged: (_) =>
                          setState(() => _teacherSubjectError = null),
                    ),
                    const SizedBox(height: 16),
                    _buildDocumentPicker(
                      title: "Degree Certificate",
                      file: _degreeCertificateFile,
                      errorText: _degreeCertificateError,
                      onTap: _loading
                          ? null
                          : () => _pickDocument(
                                onPicked: (file, bytes) {
                                  _degreeCertificateFile = file;
                                  _degreeCertificateBytes = bytes;
                                  _degreeCertificateError = null;
                                },
                              ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentPicker(
                      title: "Teaching License",
                      file: _teachingLicenseFile,
                      errorText: _teachingLicenseError,
                      onTap: _loading
                          ? null
                          : () => _pickDocument(
                                onPicked: (file, bytes) {
                                  _teachingLicenseFile = file;
                                  _teachingLicenseBytes = bytes;
                                  _teachingLicenseError = null;
                                },
                              ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentPicker(
                      title: "Transcript",
                      file: _transcriptFile,
                      errorText: _transcriptError,
                      onTap: _loading
                          ? null
                          : () => _pickDocument(
                                onPicked: (file, bytes) {
                                  _transcriptFile = file;
                                  _transcriptBytes = bytes;
                                  _transcriptError = null;
                                },
                              ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _doSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        disabledBackgroundColor:
                            const Color(0xFF4A6CF7).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _selectedRole == 'teacher'
                                  ? "Submit for Approval"
                                  : "Create Account",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ",
                          style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Sign in",
                          style: TextStyle(
                            color: Color(0xFF4A6CF7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
