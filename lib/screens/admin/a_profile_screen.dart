import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AdminProfileScreen extends StatefulWidget {
  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final String getUserInfoUrl = "${dotenv.env['BASE_URL']}/get_user_info.php";
  final String updateUsernameUrl = "${dotenv.env['BASE_URL']}/update_username.php";
  final String updateIconColorUrl = "${dotenv.env['BASE_URL']}/update_icon_color.php";
  final String getMyCommentsUrl = "${dotenv.env['BASE_URL']}/get_my_comments.php";
  final String deleteMyCommentsUrl = "${dotenv.env['BASE_URL']}/delete_my_comments.php";

  String username = "";
  String nickname = "";
  Color iconColor = Colors.grey;
  List<dynamic> userComments = [];
  bool isLoading = true;
  bool isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchUserComments();
  }

  // API calls remain the same
  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> fetchUserInfo() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        print("Kullanıcı ID alınamadı.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(Uri.parse("$getUserInfoUrl?user_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            username = data['user']['username'];
            nickname = data['user']['nickname'];
            iconColor = Color(int.parse(data['user']['color'].replaceAll('#', '0xff')));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserComments() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        setState(() {
          isLoadingComments = false;
        });
        return;
      }

      final response = await http.get(Uri.parse("$getMyCommentsUrl?user_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            userComments = data['comments'];
            isLoadingComments = false;
          });
        }
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  

  Future<void> _showColorPickerDialog() async {
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.brown,
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("İkon Rengini Seç"),
        content: Container(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () async {
                  await _updateIconColor(colors[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black12,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateIconColor(Color color) async {
    try {
      final userId = await getUserId();
      if (userId == null) return;

      final hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

      final response = await http.post(
        Uri.parse(updateIconColorUrl),
        body: {'user_id': userId.toString(), 'color': hexColor},
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          iconColor = color;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Renk başarıyla güncellendi"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${data['message']}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      final userId = await getUserId();
      if (userId == null) return;

      final response = await http.post(
        Uri.parse(updateUsernameUrl),
        body: {'user_id': userId.toString(), 'nickname': newUsername},
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          nickname = newUsername;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kullanıcı adı başarıyla güncellendi"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${data['message']}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
    }
  }

  Future<void> _showEditUsernameDialog() async {
    final TextEditingController controller = TextEditingController(text: nickname);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Kullanıcı Adını Düzenle"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Yeni kullanıcı adı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Kullanıcı adı boş olamaz";
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                _updateUsername(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text("Kaydet"),
          ),
        ],
      ),
    );
  }

 Widget _buildProfileHeader() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.all(24),
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
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 400,
              height: 100,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _showColorPickerDialog,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          nickname,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          username,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSettingsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Ayarlar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B3DD9),
              ),
            ),
          ),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: "Kullanıcı Adını Düzenle",
            iconColor: Colors.blue,
            onTap: _showEditUsernameDialog,
          ),
          Divider(height: 1, indent: 70),
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: "İkon Rengini Değiştir",
            iconColor: Colors.green,
            onTap: _showColorPickerDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

        return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profil",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            fetchUserInfo(),
            fetchUserComments(),
          ]);
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              _buildProfileHeader(),
              SizedBox(height: 24),
              _buildSettingsSection(),
              ],
            
          ),
        ),
      ),
    );
  }
}