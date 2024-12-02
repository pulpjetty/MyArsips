import 'dart:convert';
import 'dart:async';  // Import this to use Timer
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myarsips/network_utils/constant.dart'; // Your URL constant
import 'package:myarsips/views/pdfview.dart'; // Ensure the import is correct
import 'package:myarsips/views/login.dart'; // Login Page
import 'package:myarsips/network_utils/api.dart'; // Import the Network class

void main() {
  runApp(CupertinoApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? farsip;
  String? lname;
  String? nsurat;
  bool loading = true;
  List<dynamic> pdfList = []; // List of all PDFs
  int _currentIndex = 0; // To track the selected tab in the bottom navigation
  late Timer _timer; // Declare the timer
  TextEditingController _searchController = TextEditingController();

  // Fetch the PDF list from the API
  Future<void> fetchAllPdf() async {
    try {
      final response = await http.get(Uri.parse(url + 'api/arsips'));

      if (response.statusCode == 200) {
        setState(() {
          pdfList = jsonDecode(response.body);
          loading = false;
        });
      } else {
        print("Failed to load PDFs. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error fetching PDFs: $e");
    }
  }

  // Load user data
  _loadUserData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user') ?? '{}');

    if (user != null) {
      setState(() {
        farsip = user['title'];
        lname = user['lastname'];
        nsurat = user['nomor_surat'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAllPdf();
    _loadUserData();

    // Start a timer to refresh the page every 5 seconds (or as needed)
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchAllPdf();
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    _searchController.dispose(); // Dispose of the search controller
    super.dispose();
  }

  // Filter the PDF list based on the search query
  List<dynamic> _filteredPdfList() {
    String query = _searchController.text.toLowerCase();
    return pdfList.where((pdf) {
      return pdf['title'].toLowerCase().contains(query) ||
          pdf['nomor_surat'].toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (_currentIndex == 1) {
            logout();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_alt_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.arrow_right_circle_fill),
            label: 'Logout',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return CupertinoPageScaffold(
              child: CustomScrollView(
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: Text('MyArsips'),
                  ),
                  // Add the search bar under the navigation bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        onChanged: (query) {
                          setState(() {}); // Trigger a rebuild when the search query changes
                        },
                        placeholder: 'Search PDF',
                      ),
                    ),
                  ),
                  // Main content with dynamic filtered PDF list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        var filteredList = _filteredPdfList();
                        return CupertinoListTile(
                          leading: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(CupertinoIcons.doc_chart_fill),
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => PdfViewPage(
                                    url: url + "api/arsips/" + filteredList[index]["file"],
                                    title: filteredList[index]["title"],
                                  ),
                                ),
                              );
                            },
                          ),
                          title: Text(filteredList[index]["title"]),
                          subtitle: Text(
                            'ISBN: ${filteredList[index]["nomor_surat"]}',
                          ),
                        );
                      },
                      childCount: _filteredPdfList().length,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Logout function
  void logout() async {
    try {
      var res = await Network().getData('/logout');
      var body = json.decode(res.body);

      if (body['success']) {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        await localStorage.remove('user');
        await localStorage.remove('token');

        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => Login()),
              (Route<dynamic> route) => false,
        );
        print("Logout successful.");
      } else {
        print("Logout failed: ${body['message']}");
      }
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}
