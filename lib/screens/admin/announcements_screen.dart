import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_notificaiton_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class AnnouncementsScreen extends StatefulWidget {
  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final String getNotificationsUrl = "${dotenv.env['BASE_URL']}/get_notifications.php";
  final String deleteNotificationUrl = "${dotenv.env['BASE_URL']}/delete_notification.php";
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(getNotificationsUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          if (data['success'] == true) {
            notifications = data['notifications'];
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
        isLoading = false;
      });
    }
  }

  String formatDate(String dateString) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final DateTime dateTime = formatter.parse(dateString);
    final DateFormat outputFormat = DateFormat('dd MMM yyyy HH:mm');
    return outputFormat.format(dateTime);
  }

  Future<void> deleteNotification(int notificationId) async {
  try {
    final response = await http.post(
      Uri.parse(deleteNotificationUrl),
      body: {
        'notification_id': notificationId.toString(),  // 'notification_id' burada int olarak gönderilmelidir
      },
    );

    final data = json.decode(response.body);
    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Duyuru başarıyla silindi"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        notifications.removeWhere((notification) => notification['id'] == notificationId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: ${data['message']}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bağlantı hatası: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Widget _buildNotificationCard(Map<String, dynamic> notification) {
    Future<int?> getAdminId() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt('userId');
    }

    return FutureBuilder<int?>(
      future: getAdminId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[300],
          ));
        }

        final int? currentAdminId = snapshot.data;
        bool canDelete = int.tryParse(notification['admin_id'].toString()) == currentAdminId;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Duyuru detayları için gelecekte kullanılabilir
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
                            color: Colors.blue[700],
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
                          if (canDelete)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red[400],
                                size: 22,
                              ),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text("Duyuruyu Sil"),
                                      content: Text("Bu duyuruyu silmek istediğinizden emin misiniz?"),
                                      actions: [
                                        TextButton(
                                          child: Text("İptal"),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                        TextButton(
                                          child: Text(
                                            "Sil",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await deleteNotification(
                                              int.parse(notification['id'].toString())
                                            );
                                            fetchNotifications();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications_none_rounded, size: 28),
            SizedBox(width: 12),
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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.blue[700],
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewNotificationPage(),
                  ),
                ).then((_) => fetchNotifications());
              },
            ),
          ),
        ],
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
