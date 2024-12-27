import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class SavedFeedbacksScreen extends StatefulWidget {
  @override
  _SavedFeedbacksScreenState createState() => _SavedFeedbacksScreenState();
}

class _SavedFeedbacksScreenState extends State<SavedFeedbacksScreen> {
  final String savedFeedbacksUrl = "${dotenv.env['BASE_URL']}/get_saved_feedbacks.php";
  final String unsaveFeedbackUrl = "${dotenv.env['BASE_URL']}/unsave_feedback.php";
  List<dynamic> savedFeedbacks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSavedFeedbacks();
  }

  Future<void> fetchSavedFeedbacks() async {
  setState(() {
    isLoading = true;
  });

  try {
    final int? userId = await getUserId();
    if (userId == null) {
      print("Yetkili ID alınamadı.");
      return;
    }

    final url = "$savedFeedbacksUrl?admin_id=$userId";
    print('Fetching saved feedbacks with URL: $url');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        if (data['success'] == true) {
          savedFeedbacks = data['feedbacks'].map((feedback) {
            // Görsel URL'sini tam URL'ye dönüştür
            if (feedback['image_url'] != null && feedback['image_url'] != '') {
              feedback['image_url'] =
                  "${dotenv.env['BASE_URL']}/" + feedback['image_url'];
            }
            return feedback;
          }).toList();
        } else {
          savedFeedbacks = [];
          print("Sunucu Hatası: ${data['message']}");
        }
      });
    } else {
      setState(() {
        savedFeedbacks = [];
      });
      print("HTTP Hatası: ${response.statusCode}");
    }
  } catch (e) {
    setState(() {
      savedFeedbacks = [];
    });
    print("Bağlantı Hatası: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  Future<void> unsaveFeedback(int feedbackId) async {
    try {
      final int? userId = await getUserId();
      if (userId == null) {
        print("Yetkili ID alınamadı.");
        return;
      }

      final response = await http.post(
        Uri.parse(unsaveFeedbackUrl),
        body: {
          'admin_id': userId.toString(),
          'feedback_id': feedbackId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print("Kaydı geri alma işlemi başarılı.");
          setState(() {
            savedFeedbacks.removeWhere((feedback) => feedback['feedback_id'] == feedbackId);
          });
        } else {
          print("Kaydı geri alma başarısız: ${data['message']}");
        }
      } else {
        print("HTTP Hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Kaydı geri alma sırasında hata oluştu: $e");
    }
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
  final String userNickname = feedback['user_nickname'] ?? "Anonim";
  final String userColor = feedback['user_color'] ?? "#FF0000"; // Varsayılan renk kırmızı

  // Kullanıcı rengi HEX kodunu Color objesine çeviriyoruz
  Color avatarColor = Color(int.parse("0xFF" + userColor.substring(1)));

  return Container(
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white, // Arka plan beyaz
      border: Border.all(color: Colors.grey[300]!), // Gri ince çerçeve
      borderRadius: BorderRadius.circular(12), // Hafif yuvarlak köşeler
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
        ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: avatarColor, // Kullanıcı rengi
            radius: 25,
            child: Text(
              userNickname.isNotEmpty ? userNickname[0].toUpperCase() : "?",
              style: TextStyle(
                color: Colors.white, // Harf için kontrast renk
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                userNickname,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feedback['category'] ?? "Kategori Yok",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.bookmark_remove, color: Colors.red),
            onPressed: () => unsaveFeedback(feedback['feedback_id']),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            feedback['content'] ?? "",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        if (feedback['image_url'] != null && feedback['image_url'].isNotEmpty)
          Container(
            margin: EdgeInsets.all(16),
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                feedback['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[100],
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.favorite, size: 16, color: Colors.red[300]),
              SizedBox(width: 4),
              Text(
                "${feedback['like_count'] ?? 0}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Spacer(),
              Text(
                feedback['created_at'] ?? "",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
     return Scaffold(
    backgroundColor: Colors.grey[50],
appBar: AppBar(
  title: Text(
    "Kaydedilen Geri Bildirimler",
    style: TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme: IconThemeData(color: Colors.black87),

),
    body: isLoading
      ? Center(child: CircularProgressIndicator(color: Colors.red))
      : savedFeedbacks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Kaydedilen geri bildirim bulunamadı",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12),
            itemCount: savedFeedbacks.length,
            itemBuilder: (context, index) => _buildFeedbackCard(savedFeedbacks[index]),
          ),
  );
  }
}
