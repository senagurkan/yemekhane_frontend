import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class EditMenuScreen extends StatefulWidget {
  final Map<String, dynamic> menu;

  EditMenuScreen({required this.menu});

  @override
  _EditMenuScreenState createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  final TextEditingController _itemsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  bool containsGluten = false;
  bool isVegetarian = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _itemsController.text = widget.menu['items'] ?? '';
    _caloriesController.text = widget.menu['calories']?.toString() ?? '0';
    containsGluten = widget.menu['contains_gluten'] == "1";
    isVegetarian = widget.menu['is_vegetarian'] == "1";
  }
Future<void> updateMenu(Map<String, dynamic> updatedMenu) async {
  final String apiUrl = "${dotenv.env['BASE_URL']}/update_menu.php";

  try {
    // Tüm değerleri String'e dönüştürüyoruz
    final updatedMenuAsString = updatedMenu.map((key, value) => MapEntry(key, value.toString()));

    print("Gönderilen Veri (String olarak): $updatedMenuAsString");

    final response = await http.post(
      Uri.parse(apiUrl),
      body: updatedMenuAsString, // String'e dönüştürülmüş map gönderiliyor
    );

    final data = json.decode(response.body);
    print("Sunucudan Gelen Yanıt: $data");

    if (response.statusCode == 200 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Menü başarıyla güncellendi!")),
      );
      Navigator.pop(context, true); // Başarı durumunda true döndür
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${data['message'] ?? 'Bilinmeyen bir hata oluştu.'}")),
      );
    }
  } catch (e) {
    print("Bağlantı Hatası: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bağlantı hatası: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 40),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Menü Düzenle",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _itemsController,
                decoration: InputDecoration(
                  labelText: "Menü İçeriği",
                  hintText: "Örn: Mercimek Çorbası, Izgara Tavuk",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Kalori",
                  hintText: "Örn: 500",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: containsGluten,
                    onChanged: (value) {
                      setState(() {
                        containsGluten = value!;
                      });
                    },
                  ),
                  Text("Gluten İçeriyor"),
                  SizedBox(width: 24),
                  Checkbox(
                    value: isVegetarian,
                    onChanged: (value) {
                      setState(() {
                        isVegetarian = value!;
                      });
                    },
                  ),
                  Text("Vejetaryen"),
                ],
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
onPressed: isLoading
    ? null
    : () {
        final updatedMenu = {
          'id': widget.menu['id'].toString(),
          'date': widget.menu['date'],
          'items': _itemsController.text,
          'calories': _caloriesController.text.isEmpty ? '0' : _caloriesController.text,
          'contains_gluten': containsGluten ? '1' : '0',
          'is_vegetarian': isVegetarian ? '1' : '0',
        };

        updateMenu(updatedMenu); // Parametre gönderiliyor
      },



                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Menüyü Güncelle",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
