import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class AddMenuScreen extends StatefulWidget {
  @override
  _AddMenuScreenState createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final TextEditingController _itemsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  DateTime? selectedDate;
  List<String> filledDates = [];
  bool containsGluten = false;
  bool isVegetarian = false;

  @override
  void initState() {
    super.initState();
    fetchFilledDates();
  }

 // Dolu tarihleri backend'den al
  Future<void> fetchFilledDates() async {
    final String apiUrl = "${dotenv.env['BASE_URL']}/get_filled_dates.php";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          filledDates = List<String>.from(json.decode(response.body));
        });
        print("Dolu Tarihler: $filledDates");
      } else {
        print("Dolu tarihleri alırken hata oluştu: ${response.statusCode}");
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
    }
  }

  // Menü kaydet
  Future<void> saveMenu() async {
    if (selectedDate == null || _itemsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tarih ve yemek içeriği doldurulmalıdır!")),
      );
      return;
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final String apiUrl = "${dotenv.env['BASE_URL']}/add_menu.php";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'date': formattedDate,
          'items': _itemsController.text,
          'calories': _caloriesController.text.isEmpty ? '0' : _caloriesController.text,
          'contains_gluten': containsGluten ? '1' : '0',
          'is_vegetarian': isVegetarian ? '1' : '0',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Menü başarıyla kaydedildi!")),
        );
      Navigator.pop(context, true); // Başarı durumunu ana ekrana ilet
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? "Bir hata oluştu.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı hatası: $e")),
      );
    }
  }

  DateTime getInitialDate() {
    DateTime today = DateTime.now();

    // Bugünden itibaren ilk seçilebilir tarihi bul
    for (int i = 0; i < 365; i++) {
      DateTime checkDate = today.add(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(checkDate);

      // Hafta sonu veya dolu tarih ise kontrolü geç
      if (!filledDates.contains(formattedDate) &&
          checkDate.weekday != DateTime.saturday &&
          checkDate.weekday != DateTime.sunday) {
        return checkDate; // İlk uygun tarihi döndür
      }
    }

    // Eğer tüm günler doluysa bugünü döndür (varsayılan olarak)
    return today;
  }

void showDateSelector() async {
  DateTime initialDate = getInitialDate(); // İlk seçilebilir tarihi al

  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
    selectableDayPredicate: (day) {
      String formattedDay = DateFormat('yyyy-MM-dd').format(day);
      bool isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      return !filledDates.contains(formattedDay) && !isWeekend;
    },
    builder: (context, child) {
      return Localizations(
        locale: const Locale('tr', 'TR'), // Türkçe yerelleştirme
        delegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!, // Seçili gün rengi
              onPrimary: Colors.white, // Seçili gün yazı rengi
              onSurface: Colors.grey[800]!, // Normal yazı rengi
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        ),
      );
    },
  );

  if (pickedDate != null) {
    setState(() {
      selectedDate = pickedDate;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Yeni Menü Ekle",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst Bilgi Kartı
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih Seçici
                  Text(
                    "Menü Tarihi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: showDateSelector,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                              size: 20, color: Colors.grey[600]),
                          SizedBox(width: 12),
                          Text(
                            selectedDate == null
                                ? "Tarih Seçiniz"
                                : DateFormat('dd MMMM yyyy', 'tr_TR')
                                    .format(selectedDate!),
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedDate == null 
                                  ? Colors.grey[600] 
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ana İçerik Kartı
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menü İçeriği
                  Text(
                    "Menü İçeriği",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _itemsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Günün menüsünü giriniz...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue[400]!),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Kalori
                  Text(
                    "Kalori Değeri",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "kcal",
                      suffixText: "kcal",
                      suffixStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue[400]!),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Özellikler
                  Text(
                    "Menü Özellikleri",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Switch(
                                value: containsGluten,
                                onChanged: (value) {
                                  setState(() => containsGluten = value);
                                },
                                activeColor: Colors.orange,
                              ),
                              Text(
                                "Gluten",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Switch(
                                value: isVegetarian,
                                onChanged: (value) {
                                  setState(() => isVegetarian = value);
                                },
                                activeColor: Colors.green,
                              ),
                              Text(
                                "Vejetaryen",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Kaydet Butonu
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: saveMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Menüyü Kaydet",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}