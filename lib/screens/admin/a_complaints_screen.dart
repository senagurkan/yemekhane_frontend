import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'saved_feedback_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AdminComplaintsScreen extends StatefulWidget {
  @override
  _AdminComplaintsScreenState createState() => _AdminComplaintsScreenState();
}
String getMonthName(int month) {
  const months = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık"
  ];
  return months[month - 1];
}
  final cardBorderRadius = 20.0;
  final primaryColor = Color(0xFFE53935); // Kırmızı tema rengi
  final shadowColor = Colors.black12;
  final cardElevation = 4.0;

String selectedCategory = 'all'; // Varsayılan olarak tüm kategoriler

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final String getComplaintsUrl = "${dotenv.env['BASE_URL']}/get_feedback.php";
    final String likeFeedbackUrl = "${dotenv.env['BASE_URL']}/like_feedback.php";

  List<dynamic> feedbacks = [];
  bool isLoading = true;
  String selectedSort = 'newest'; // Varsayılan sıralama
  DateTime selectedDate = DateTime.now(); // Varsayılan olarak mevcut ay ve yıl

  @override
  void initState() {
    super.initState();
    fetchFeedbacks();
  }
void updateMonth(int delta) {
  setState(() {
    selectedDate = DateTime(selectedDate.year, selectedDate.month + delta, 1);
  });
  fetchFeedbacks();
}


  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

Future<void> fetchFeedbacks() async {
  setState(() {
    isLoading = true;
  });

  try {
    final int? userId = await getUserId();
    if (userId == null) {
      print("Kullanıcı ID alınamadı.");
      return;
    }

    final url =
        "$getComplaintsUrl?user_id=$userId&month=${selectedDate.month}&year=${selectedDate.year}&sort=$selectedSort&category=$selectedCategory";
    print('Fetching feedbacks with URL: $url');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        if (data['success'] == true) {
          feedbacks = data['feedbacks'].map((feedback) {
            if (feedback['image_url'] != null && feedback['image_url'] != '') {
              feedback['image_url'] =
                  "${dotenv.env['BASE_URL']}/" + feedback['image_url'];
            }
            feedback['user_liked'] = feedback['user_liked'] ?? false;
            return feedback;
          }).toList();
        } else {
          feedbacks = [];
          print("Sunucu Hatası: ${data['message']}");
        }
      });
    } else {
      setState(() {
        feedbacks = [];
      });
      print("HTTP Hatası: ${response.statusCode}");
    }
  } catch (e) {
    setState(() {
      feedbacks = [];
    });
    print("Bağlantı Hatası: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

Future<void> toggleFeedbackSave(int feedbackId, bool isSaved) async {
  final String saveFeedbackUrl = "${dotenv.env['BASE_URL']}/save_feedback.php";
  final String action = isSaved ? 'unsave' : 'save'; // Kaydetme veya geri alma işlemi

  try {
    final int? userId = await getUserId();
    if (userId == null) {
      print("Yetkili ID alınamadı.");
      return;
    }

    final response = await http.post(
      Uri.parse(saveFeedbackUrl),
      body: {
        'admin_id': userId.toString(),
        'feedback_id': feedbackId.toString(),
        'action': action,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print(data['message']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      } else {
        print("İşlem başarısız: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İşlem başarısız: ${data['message']}")),
        );
      }
    } else {
      print("HTTP Hatası: ${response.statusCode}");
    }
  } catch (e) {
    print("Hata: $e");
  }
}


Widget _buildCategoryButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildCategoryButton('all', "Tümü"),
      _buildCategoryButton('istek', "İstek"),
      _buildCategoryButton('şikayet', "Şikayet"),
      _buildCategoryButton('diğer', "Diğer"),
    ],
  );
}

Widget _buildCategoryButton(String category, String label) {
  final isSelected = selectedCategory == category;

  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: isSelected ? primaryColor : Colors.white,
      foregroundColor: isSelected ? Colors.white : primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor),
      ),
      elevation: isSelected ? 4 : 0,
    ),
    onPressed: () {
      setState(() {
        selectedCategory = category;
      });
      fetchFeedbacks();
    },
    child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
  );
}

 
Widget _buildMonthNavigation() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Geri ok
      IconButton(
        icon: Icon(Icons.arrow_left),
        onPressed: () {
          setState(() {
            // Bir önceki aya geç
            selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
          });
          fetchFeedbacks(); // Yeni ay için verileri çek
        },
      ),
      // Şu anki ay ve yıl
      Text(
        "${getMonthName(selectedDate.month)} ${selectedDate.year}",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      // İleri ok
      IconButton(
        icon: Icon(Icons.arrow_right),
        onPressed: () {
          setState(() {
            // Bir sonraki aya geç
            selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
          });
          fetchFeedbacks(); // Yeni ay için verileri çek
        },
      ),
    ],
  );
}


Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, // Beyaz arka plan
      border: Border.all(color: Colors.grey[300]!), // İnce gri çerçeve
      borderRadius: BorderRadius.circular(12), // Hafif yuvarlatılmış köşeler
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1), // Hafif gölge
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    feedback['user_color'] != null
                        ? Color(int.parse("0xFF${feedback['user_color'].substring(1)}"))
                        : primaryColor,
                    feedback['user_color'] != null
                        ? Color(int.parse("0xFF${feedback['user_color'].substring(1)}")).withOpacity(0.8)
                        : primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  feedback['user_nickname'] != null && feedback['user_nickname'].isNotEmpty
                      ? feedback['user_nickname'][0].toUpperCase()
                      : "?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback['user_nickname'] ?? "Bilinmeyen Kullanıcı",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feedback['category'],
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            // Kaydetme İkonu
            IconButton(
              icon: Icon(
                feedback['is_saved'] == true ? Icons.bookmark : Icons.bookmark_border,
                color: primaryColor,
              ),
              onPressed: () {
                toggleFeedbackSave(feedback['feedback_id'], feedback['is_saved'] == true);
                setState(() {
                  feedback['is_saved'] = !(feedback['is_saved'] ?? false); // Kaydetme durumu tersine çevrilir
                });
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          feedback['content'],
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        if (feedback['image_url'] != null && feedback['image_url'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                feedback['image_url'],
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.favorite,
                color: primaryColor.withOpacity(0.7),
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                "${feedback['like_count']} Beğeni",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



 Widget _buildFilters() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, size: 20, color: primaryColor),
              onPressed: () => updateMonth(-1),
            ),
            Text(
              "${getMonthName(selectedDate.month)} ${selectedDate.year}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                  size: 20, color: primaryColor),
              onPressed: () => updateMonth(1),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: selectedSort,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.sort, color: primaryColor),
            items: [
              DropdownMenuItem(
                value: 'newest',
                child: Text("En Yeniler"),
              ),
              DropdownMenuItem(
                value: 'most_liked',
                child: Text("En Çok Beğenilenler"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedSort = value!;
              });
              fetchFeedbacks();
            },
          ),
        ),
        SizedBox(height: 16),
        _buildCategoryButtons(), // Kategori butonlarını burada çağırıyoruz
      ],
    ),
  );
}

  Widget _buildFeedbackSection() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.red));
    }


  if (feedbacks.isEmpty) {
    return Center(
      child: Text(
        "${getMonthName(selectedDate.month)} ${selectedDate.year} için geri bildirim bulunamadı.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

    return ListView.builder(
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        return _buildFeedbackCard(feedbacks[index]);
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
appBar: AppBar(
  title: Text(
    "Geri Bildirimler",
    style: TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme: IconThemeData(color: Colors.black87),
  actions: [
    IconButton(
      icon: Icon(Icons.archive, color: Colors.red), // Kaydedilenler ikonu
      onPressed: () async {
        // SavedFeedbacksScreen'e geçiş
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SavedFeedbacksScreen()),
        );
        // Geri dönüldüğünde feedbackleri yenile
        fetchFeedbacks();
      },
    ),
  ],
),


      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            SizedBox(height: 16),
            Expanded(
              child: _buildFeedbackSection(),
            ),
          ],
        ),
      ),
    );
  }
}