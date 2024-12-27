import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import '../login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'complaints_screen.dart';
import 'notification_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class StudentHomeScreen extends StatefulWidget {
  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<dynamic> weeklyMenus = [];
  bool isLoading = true;
  int _selectedIndex = 1;
  

  DateTime currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  final weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

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

  @override
void initState() {
  super.initState();
  fetchWeeklyMenus();
  fetchUnreadNotifications();
}


  IconData getCategoryIcon(String menuItem) {
    String itemLower = menuItem.toLowerCase();
    for (var category in categoryIcons.keys) {
      if (itemLower.contains(category)) {
        return categoryIcons[category]!;
      }
    }
    return categoryIcons['default']!;
  }

  Future<void> fetchWeeklyMenus() async {
    setState(() => isLoading = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = dateFormat.format(currentWeekStart);

    final String apiUrl = "${dotenv.env['BASE_URL']}/get_weekly_menus.php?start_date=$startDate";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['menus'] != null) {
          List<dynamic> menus = data['menus'];
          setState(() {
            weeklyMenus = menus;
            isLoading = false;
          });
        } else {
          setState(() {
            weeklyMenus = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        weeklyMenus = [];
        isLoading = false;
      });
    }
  }

void changeWeek(int weeks) {
  setState(() {
    currentWeekStart = currentWeekStart.add(Duration(days: 7 * weeks));
    isLoading = true; // Yeni haftayı yüklerken yükleme ekranı göster
  });

  fetchWeeklyMenus();
}
  // API işlemleri aynı kalacak
Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

int unreadNotifications = 0;

Future<void> fetchUnreadNotifications() async {
  print("fetchUnreadNotifications çalıştı!"); // Log ekle
  final prefs = await SharedPreferences.getInstance();
  final int? userId = await getUserId();

  if (userId == null) {
    print("Kullanıcı ID'si bulunamadı.");
    return;
  }

  final String apiUrl = "${dotenv.env['BASE_URL']}/get_unread_notifications.php?user_id=$userId";

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          unreadNotifications = data['unread_count'];
        });
        print("Okunmamış bildirim sayısı: $unreadNotifications");
      }
    }
  } catch (e) {
    print("Hata: $e");
  }
}


  String getFormattedDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return DateFormat('d MMMM', 'tr_TR').format(dateTime);
  }

  Widget _buildWeekNavigation() {
    final startDate = DateFormat('d MMMM', 'tr_TR').format(currentWeekStart);
    final endDate = DateFormat('d MMMM', 'tr_TR').format(
      currentWeekStart.add(Duration(days: 6)),
    );

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.red),
            onPressed: () => changeWeek(-1),
          ),
          Text(
            '$startDate - $endDate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.red),
            onPressed: () => changeWeek(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

if (weeklyMenus.isEmpty && !isLoading) {
  return CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: _buildWeekNavigation(),
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: 36), // Yazının üstüne boşluk ekler
      ),
      SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_meals,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Bu hafta için menü bulunamadı',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildWeekNavigation(),
        ),
        SliverPadding(
          padding: EdgeInsets.only(top: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final menu = weeklyMenus[index];
                final menuItems = menu['items'].split(',');
                final weekDay = weekDays[DateTime.parse(menu['date']).weekday - 1];

              return GestureDetector(
                onTap: () {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      print("Gönderilen menu nesnesi: $menu"); // Menü nesnesini yazdır
      return MenuDetailScreen(menu: menu);
    },
  ),
);


                },
                child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
Row(
  children: [
    Icon(
      Icons.calendar_month, // Daha uygun bir ikon seçebilirsiniz
      color: Colors.red,
      size: 28,
    ),
    SizedBox(width: 12),
    Text(
      weekDay, // Gün ismini göstermek için weekDay kullanıyoruz
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  ],
),

                            Text(
                              menu['date'],
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: menuItems.length,
                        itemBuilder: (context, itemIndex) {
                          final menuItem = menuItems[itemIndex].trim();
                          return ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                getCategoryIcon(menuItem),
                                color: Colors.red,
                              ),
                            ),
                            title: Text(
                              menuItem,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  menu['calories'] != null && menu['calories'] != 0
                                      ? '${menu['calories']} kcal'
                                      : 'Bilinmiyor',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.timer, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  '12:00 - 14:00',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
              childCount: weeklyMenus.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ComplaintsScreen();
      case 1:
        return _buildMainContent();
      case 2:
        return ProfileScreen();
      default:
        return _buildMainContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          title: Image.asset(
            'assets/logo.png',
            height: 50,
            fit: BoxFit.contain,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
leading: IconButton(
  icon: Icon(Icons.logout, color: Colors.red), // Çıkış ikonu
  onPressed: () {
    showModalBottomSheet(
      context: context,
                  backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32), // Daha geniş iç boşluk
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Çıkış Yap",
                style: TextStyle(
                  fontSize: 24, // Daha büyük yazı tipi
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Çıkış yapmak istediğinizden emin misiniz?",
                textAlign: TextAlign.center, // Ortalanmış metin
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 32), // Daha geniş boşluk
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Alt modalı kapat
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300], // Gri arka plan
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "İptal",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Çıkış işlemi
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      // Login ekranına yönlendirme
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Kırmızı arka plan
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Evet, Çıkış Yap",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // Beyaz yazı rengi
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  },
),
actions: [
  Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: IconButton(
          icon: Icon(
            Icons.notifications_rounded,
            color: Colors.red[700], // Eğer bu da kırmızı olacaksa değiştir
            size: 28,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationScreen()),
            );
            fetchUnreadNotifications();
          },
        ),
      ),
      if (unreadNotifications > 0)
        Positioned(
          right: 4,
          top: 4,
          child: TweenAnimationBuilder(
            duration: Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.5, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red, // Renk kırmızı olarak güncellendi
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4), // Gölge rengi de kırmızıya uygun
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: 22,
                minHeight: 22,
              ),
              child: Center(
                child: Text(
                  unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
    ],
  ),
]


        ),
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: "Şikayetler",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Ana Sayfa",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profil",
            ),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
