import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // Add this
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class NewFeedbackScreen extends StatefulWidget {
  @override
  _NewFeedbackScreenState createState() => _NewFeedbackScreenState();
}

class _NewFeedbackScreenState extends State<NewFeedbackScreen> {
  final String submitFeedbackUrl = "${dotenv.env['BASE_URL']}/add_feedback.php";
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory = 'istek';
  String _content = '';
  bool _isSubmitting = false;
  File? _selectedImage; // Fotoğraf için dosya


    // API işlemleri aynı kalacak
Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

Future<void> submitFeedback() async {
  setState(() {
    _isSubmitting = true;
  });

  try {
    final request = http.MultipartRequest('POST', Uri.parse(submitFeedbackUrl));
    final int? userId = await getUserId();

          if (userId == null) {
        print("Kullanıcı ID alınamadı. Giriş yapmış mı?");
        return;
      }
    request.fields['user_id'] = userId.toString(); // Kullanıcı ID'yi gerçek uygulamada dinamik al
    request.fields['category'] = _selectedCategory!;
    request.fields['content'] = _content;

    if (_selectedImage != null) {
      print("Fotoğraf Yolu: ${_selectedImage!.path}"); // Fotoğraf yolunu kontrol edin
request.files.add(await http.MultipartFile.fromPath(
  'image',
  _selectedImage!.path,
  contentType: MediaType('image', 'jpg'), // Define the content type
));

    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = json.decode(responseData);

    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İstek/Şikayet başarıyla gönderildi!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${data['message']}")),
      );
    }
  } catch (e) {
    print("Bağlantı hatası: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bağlantı hatası meydana geldi.")),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Yeni İstek/Şikayet",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori Seçimi
                Text(
                  "Kategori",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: [
                    DropdownMenuItem(
                      value: 'istek',
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.green),
                          SizedBox(width: 8),
                          Text("İstek"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'şikayet',
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Şikayet"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'diğer',
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Diğer"),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // İçerik Alanı
                Text(
                  "İçerik",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Buraya şikayet veya isteğinizi yazın...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Bu alan boş bırakılamaz.";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _content = value;
                  },
                ),
                SizedBox(height: 16),

                // Fotoğraf Ekleme
                Text(
                  "Fotoğraf Ekle (Opsiyonel)",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: _selectedImage == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text("Fotoğraf seçmek için tıklayın"),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),

                // Gönder Butonu
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              submitFeedback();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Gönder",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
