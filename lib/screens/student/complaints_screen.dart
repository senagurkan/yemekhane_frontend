import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_feedback_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class ComplaintsScreen extends StatefulWidget {
  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
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

String selectedCategory = 'all'; // Varsayılan olarak tüm kategoriler

  final cardBorderRadius = 20.0;
  final primaryColor = Color(0xFFE53935); // Kırmızı tema rengi
  final shadowColor = Colors.black12;
  final cardElevation = 4.0;

class _ComplaintsScreenState extends State<ComplaintsScreen> {
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
              feedback['image_url'] = "${dotenv.env['BASE_URL']}/" + feedback['image_url'];
            }
            feedback['user_liked'] = feedback['user_liked'] ?? false;
            return feedback;
          }).toList();
        } else {
          // Geri bildirim bulunamadığında listeyi temizle
          feedbacks = [];
          print("Sunucu Hatası: ${data['message']}");
        }
      });
    } else {
      setState(() {
        feedbacks = []; // HTTP hatası durumunda da listeyi temizle
      });
      print("HTTP Hatası: ${response.statusCode}");
    }
  } catch (e) {
    setState(() {
      feedbacks = []; // Hata durumunda da listeyi temizle
    });
    print("Bağlantı Hatası: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
 Future<void> likeFeedback(int feedbackId) async {
  final int? userId = await getUserId();

  if (userId == null) {
    print("Kullanıcı ID alınamadı. Giriş yapmış mı?");
    return;
  }

  try {
    final response = await http.post(
      Uri.parse(likeFeedbackUrl),
      body: {
        'feedback_id': feedbackId.toString(),
        'user_id': userId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print(data['message']);
        fetchFeedbacks(); // Listeyi güncelle
      } else {
        print("Hata: ${data['message']}");
      }
    } else {
      print("HTTP Hatası: ${response.statusCode}");
    }
  } catch (e) {
    print("Bağlantı Hatası: $e");
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

  Widget _buildNewFeedbackButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewFeedbackScreen()),
          ).then((_) => fetchFeedbacks());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardBorderRadius),
          ),
          elevation: cardElevation,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 24),
            SizedBox(width: 12),
            Text(
              "Yeni İstek/Şikayet Ekle",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Yatay kenar boşluğu
    padding: EdgeInsets.all(16), // İçerik için alan
    decoration: BoxDecoration(
      color: Colors.white, // Beyaz arka plan
      border: Border.all(color: Colors.grey[300]!), // Gri çerçeve
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
            // Kullanıcı Avatarı
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
            // Kullanıcı Bilgileri
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
          ],
        ),
        SizedBox(height: 16),
        // Geri Bildirim İçeriği
        Text(
          feedback['content'],
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        // Görsel
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
        SizedBox(height: 16),
        // Beğeni Butonu ve Sayısı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => likeFeedback(feedback['feedback_id']),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: feedback['user_liked'] == true
                        ? primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.thumb_up,
                    color: feedback['user_liked'] == true
                        ? primaryColor
                        : Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(10),
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
                icon: Icon(Icons.arrow_back_ios,
                  size: 20,
                  color: primaryColor,
                ),
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
                  size: 20,
                  color: primaryColor,
                ),
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
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () => fetchFeedbacks(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yeni Geri Bildirim Ekle Butonu
             Card(
  elevation: 0, // Gölgeyi kaldırmak için sıfır yapıldı
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(cardBorderRadius),
    side: BorderSide( // Çerçeve eklemek için
      color: Colors.grey[300]!, // İnce gri bir çerçeve
      width: 1, // Çerçevenin genişliği
    ),
  ),
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewFeedbackScreen(),
                        ),
                      ).then((_) => fetchFeedbacks());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(cardBorderRadius),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 22,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Yeni İstek/Şikayet Ekle",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Filtreler
              _buildFilters(),
              SizedBox(height: 16),

              // Geri Bildirim Listesi
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardBorderRadius),
                  child: _buildFeedbackSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
    }