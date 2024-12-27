import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String getNotificationsUrl = "${dotenv.env['BASE_URL']}/get_notifications.php";
  final String markAsReadUrl = "${dotenv.env['BASE_URL']}/mark_as_read.php";

  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
  setState(() {
    isLoading = true; // Yükleme başlat
  });

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId'); // Kullanıcı ID'sini al

  if (userId == null) {
    print("Kullanıcı ID'si bulunamadı.");
    setState(() {
      isLoading = false;
    });
    return;
  }

  try {
    final response = await http.get(
      Uri.parse("${dotenv.env['BASE_URL']}/get_notifications_student.php?user_id=$userId"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        if (data['success'] == true) {
          notifications = sortNotifications(data['notifications']);
        } else {
          notifications = [];
          print("Sunucu Hatası: ${data['message']}");
        }
      });
    } else {
      print("HTTP Hatası: ${response.statusCode}");
      setState(() {
        notifications = [];
      });
    }
  } catch (e) {
    print("Bağlantı Hatası: $e");
    setState(() {
      notifications = [];
    });
  } finally {
    setState(() {
      isLoading = false; // Yükleme tamamlandı
    });
  }
}


  List<dynamic> sortNotifications(List<dynamic> notifications) {
    notifications.sort((a, b) {
      final bool aRead = a['read_at'] != null;
      final bool bRead = b['read_at'] != null;
      if (aRead && !bRead) return 1; // Okunmamış bildirimler üstte
      if (!aRead && bRead) return -1;
      return 0;
    });
    return notifications;
  }

Future<void> markAsRead(int notificationId) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');

  try {
    final response = await http.post(
      Uri.parse("${dotenv.env['BASE_URL']}/mark_as_read.php"),
      body: {
        'user_id': userId.toString(),
        'notification_id': notificationId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print("Bildirim okundu olarak işaretlendi.");
        await fetchNotifications(); // Listeyi yenile
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



  String formatDate(String dateString) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final DateTime dateTime = formatter.parse(dateString);
    final DateFormat outputFormat = DateFormat('dd MMM yyyy HH:mm');
    return outputFormat.format(dateTime);
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
  bool isRead = notification['read_at'] != null;

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isRead ? Colors.white : Colors.red[50], // Okunmuş: Beyaz, Okunmamış: Açık sarı
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRead
              ? null // Okunmuşsa tıklanmasın
              : () async {
                  await markAsRead(notification['id']); // API çağrısı
                  fetchNotifications(); // Listeleri güncelle
                },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.announcement_outlined,
                      size: 24,
                      color: isRead ? Colors.grey : Colors.blue[700],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          formatDate(notification['sent_at']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Image.asset(
                'assets/logo.png', // Logonuzun yolunu burada belirtin
                height: 50,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 8),
              Text(
                "Duyurular",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[700],
              ),
            )
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Henüz bir duyuru bulunmamaktadır.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchNotifications,
                  color: Colors.blue[700],
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  ),
                ),
    );
  }
}
