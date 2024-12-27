import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuDetailScreen extends StatefulWidget {
  final Map<String, dynamic> menu;

  MenuDetailScreen({required this.menu});

  @override
  _MenuDetailScreenState createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  List<dynamic> comments = [];
  int userRating = 0;
  final TextEditingController commentController = TextEditingController();
  bool isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
    fetchUserRating();
  }

  // API işlemleri aynı kalacak
Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> fetchComments() async {
    final String apiUrl = "${dotenv.env['BASE_URL']}/get_comments.php";

    try {
      final response = await http.get(
        Uri.parse("$apiUrl?menu_id=${widget.menu['id']}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            comments = data['comments'];
            isLoadingComments = false;
          });
        }
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  Future<void> fetchUserRating() async {
    final String apiUrl = "${dotenv.env['BASE_URL']}/get_user_rating.php";

    try {
      final int? userId = await getUserId();

      if (userId == null) {
        print("Kullanıcı ID alınamadı. Giriş yapmış mı?");
        return;
      }

      final response = await http.get(
        Uri.parse("$apiUrl?menu_id=${widget.menu['id']}&user_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            userRating = data['rating'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
    }
  }

  Future<void> addRating(int rating) async {
  final String apiUrl = "${dotenv.env['BASE_URL']}/add_rating.php";

  try {
    final int? userId = await getUserId();
    if (userId == null) {
      print("Kullanıcı ID alınamadı.");
      return;
    }

    print("Gönderilen menu_id: ${widget.menu['id']}"); // `menu_id`'yi yazdırın
    print("Gönderilen user_id: $userId");
    print("Gönderilen rating: $rating");

    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'menu_id': widget.menu['id'].toString(),
        'user_id': userId.toString(),
        'rating': rating.toString(),
      },
    );

    final data = json.decode(response.body);
    print("API Yanıtı: $data");

    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Puan başarıyla kaydedildi.")),
      );
      setState(() {
        userRating = rating;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${data['message']}")),
      );
    }
  } catch (e) {
    print("Bağlantı Hatası: $e");
  }
}



  Future<void> addComment(String comment) async {
    final String apiUrl = "${dotenv.env['BASE_URL']}/add_comment.php";

    try {
      final int? userId = await getUserId();
      if (userId == null) {
        print("Kullanıcı ID alınamadı.");
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'menu_id': widget.menu['id'].toString(),
          'user_id': userId.toString(),
          'comment': comment,
        },
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yorum başarıyla eklendi.")),
        );
        commentController.clear();
        fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${data['message']}")),
        );
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
    }
  }

  IconData getCategoryIcon(String menuItem) {
    final Map<String, IconData> categoryIcons = {
      'çorba': Icons.soup_kitchen,
      'pilav': Icons.rice_bowl,
      'makarna': Icons.dinner_dining,
      'et': Icons.kebab_dining,
      'tavuk': Icons.egg,
      'salata': Icons.eco,
      'tatlı': Icons.cake,
      'default': Icons.restaurant,
    };
    String itemLower = menuItem.toLowerCase();
    for (var category in categoryIcons.keys) {
      if (itemLower.contains(category)) {
        return categoryIcons[category]!;
      }
    }
    return categoryIcons['default']!;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = widget.menu['items'].split(',');
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menü Başlığı
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                "Günün Menüsü",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Menü Kartı
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
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
                children: [
                  // Menü Öğeleri
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: menuItems.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = menuItems[index].trim();
                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(getCategoryIcon(item), 
                            color: Colors.red[700], 
                            size: 20
                          ),
                        ),
                        title: Text(
                          item,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),

                  // Menü Detayları
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                          Icons.local_fire_department,
                          "${widget.menu['calories']} kcal",
                          Colors.orange,
                        ),
_buildInfoChip(
  Icons.grass,
  "Vejetaryen",
  Colors.green,
  isActive: widget.menu['is_vegetarian'] == 1, // int olan değeri bool'a çeviriyoruz
),
_buildInfoChip(
  Icons.grain,
  "Gluten",
  Colors.brown,
  isActive: widget.menu['contains_gluten'] == 1, // int olan değeri bool'a çeviriyoruz
),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Değerlendirme Bölümü
            Container(
              margin: EdgeInsets.fromLTRB(24, 24, 24, 16),
              padding: EdgeInsets.all(16),
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
                  Text(
                    "Değerlendirme",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () => addRating(index + 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Yorum Bölümü
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.all(16),
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
                  Text(
                    "Yorumlar",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: "Yorumunuzu yazın...",
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
                        borderSide: BorderSide(color: Colors.red[700]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          addComment(commentController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Yorum Gönder",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Yorumlar Listesi
                  if (isLoadingComments)
                    Center(child: CircularProgressIndicator())
                  else if (comments.isEmpty)
                    Center(
                      child: Text(
                        "Henüz yorum yapılmamış.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  else
                    ...comments.map((comment) => _buildCommentCard(comment)).toList(),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color, {bool isActive = true}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? color : Colors.grey,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
  // Güvenli renk dönüşümü
  Color userColor = Colors.grey; // Varsayılan renk
  try {
    if (comment['color'] != null) {
      final colorString = comment['color'].toString().replaceAll(' ', '');
      if (colorString.startsWith('#')) {
        userColor = Color(int.parse(colorString.replaceAll('#', '0xff')));
      }
    }
  } catch (e) {
    print('Renk dönüşüm hatası: $e');
    userColor = Colors.grey; // Hata durumunda varsayılan renk
  }

  return Container(
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Kullanıcı ikonu ve rengi
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: userColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (comment['nickname'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            // Kullanıcı bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment['nickname'] ?? 'Anonim',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    comment['created_at'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.only(left: 52),
          child: Text(
            comment['comment'] ?? '',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ],
    ),
  );
}
}