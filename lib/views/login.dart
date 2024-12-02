import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:myarsips/network_utils/api.dart';
import 'package:myarsips/views/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Sistem Informasi Pegawai',
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String email = '';  // Initialize variables to store email and password
  String password = '';
  String errorMessage = '';  // Store error message to display in the UI

  // Function to handle the login logic
  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        errorMessage = '';  // Clear any previous error message
      });

      var data = {
        'email': email,
        'password': password,
      };

      try {
        var res = await Network().authData(data, '/login');
        var body = json.decode(res.body);

        if (body['success']) {
          SharedPreferences localStorage = await SharedPreferences.getInstance();
          localStorage.setString('token', json.encode(body['token']));
          localStorage.setString('user', json.encode(body['user']));

          // Navigate to the home screen after successful login
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => Home()),
          );
        } else {
          // Update error message if login fails
          setState(() {
            errorMessage = body['message'];
          });
        }
      } catch (e) {
        // Update error message if network or API call fails
        setState(() {
          errorMessage = 'Error: $e';
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Login'),
      ),
      child: SafeArea(
        child: Container(
          color: CupertinoColors.systemBlue,
          child: Center(
            child: Form(
              key: _formKey,  // Use the form key here for validation
              child: CupertinoFormSection(
                header: Text("Login"),
                children: <Widget>[
                  CupertinoFormRow(
                    child: CupertinoTextFormFieldRow(
                      placeholder: "Email",
                      prefix: Icon(CupertinoIcons.mail),
                      validator: (emailValue) {
                        if (emailValue?.isEmpty ?? true) {
                          return 'Please enter email';
                        }
                        email = emailValue ?? '';  // Capture the email value
                        return null;
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    child: CupertinoTextFormFieldRow(
                      placeholder: "Password",
                      obscureText: true,
                      prefix: Icon(CupertinoIcons.lock),
                      validator: (passwordValue) {
                        if (passwordValue?.isEmpty ?? true) {
                          return 'Please enter password';
                        }
                        password = passwordValue ?? '';  // Capture the password value
                        return null;
                      },
                    ),
                  ),
                  // Display error message under the login button
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CupertinoButton(
                      color: CupertinoColors.activeBlue,
                      child: Text(_isLoading ? 'Processing...' : 'Login'),
                      onPressed: _login,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
