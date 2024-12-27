import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'student/student_home_screen.dart';
import 'admin/admin_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showFlushbar(BuildContext context, String message, Color color) {
    Flushbar(
      message: message,
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(15),
      backgroundColor: color.withOpacity(0.9),
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(Icons.error_outline, size: 28.0, color: Colors.white),
    ).show(context);
  }

void _login(BuildContext context) async {
  final username = _usernameController.text;
  final password = _passwordController.text;

  final String apiUrl = '${dotenv.env['BASE_URL']}/login.php';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {'username': username, 'password': password},
    );

    final Map<String, dynamic> responseData = json.decode(response.body);

    if (responseData['success'] == true) {
      final int role = int.parse(responseData['role']);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', int.parse(responseData['user_id']));
      await prefs.setInt('role', role);

      if (role == 2) {
        // Öğrenci ana ekranına yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentHomeScreen()),
        );
      } else if (role == 1) {
        // Admin ana ekranına yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeScreen()), // Admin ekranı
        );
      } else {
        _showFlushbar(
          context,
          "Geçersiz rol tanımlaması. Lütfen yetkiliye başvurun.",
          Colors.orange,
        );
      }
    } else {
      _showFlushbar(
        context,
        "Geçersiz kullanıcı adı veya şifre. Lütfen tekrar deneyin.",
        Colors.red,
      );
    }
  } catch (e) {
    _showFlushbar(
      context,
      "Bağlantı hatası: $e",
      Colors.red,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Container(
        height: screenHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background design
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 50),
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 30,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 40),
                          Text(
                            "Hoş Geldiniz",
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Lezzetli yemeklerin buluşma noktası",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 40),
                          // Glass effect container
                          Container(
                            padding: EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _usernameController,
                                  hint: "Kullanıcı Adı",
                                  icon: Icons.person_outline,
                                ),
                                SizedBox(height: 20),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: "Şifre",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                ),
                                SizedBox(height: 30),
                                _buildLoginButton(),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),

                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(icon, color: Colors.red[400]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _login(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          "Giriş Yap",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}