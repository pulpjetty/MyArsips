import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myarsips/network_utils/constant.dart';

class Network {
  final String _url = url + 'api/v1'; // Base URL
  var token;

  // Fetch the token from SharedPreferences
  _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    String? storedToken = localStorage.getString('token');
    if (storedToken != null) {
      token = jsonDecode(storedToken)['token'];
    }
  }

  // Send POST request with data
  authData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    // Convert the fullUrl String to Uri using Uri.parse()
    var uri = Uri.parse(fullUrl);
    return await http.post(
      uri,
      body: jsonEncode(data),
      headers: await _setHeaders(),
    );
  }

  // Send GET request with authentication
  getData(apiUrl) async {
    var fullUrl = _url + apiUrl;
    // Convert the fullUrl String to Uri using Uri.parse()
    var uri = Uri.parse(fullUrl);
    await _getToken();
    return await http.get(
      uri,
      headers: await _setHeaders(),
    );
  }

  // Set the headers for the requests
  _setHeaders() async {
    return {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // Use the token in Authorization header
    };
  }
}
