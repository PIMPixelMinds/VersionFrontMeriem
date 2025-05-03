import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/auth_viewmodel.dart'; // adjust import path

class CheckLoginPage extends StatefulWidget {
  const CheckLoginPage({super.key});

  @override
  _CheckLoginPageState createState() => _CheckLoginPageState();
}

class _CheckLoginPageState extends State<CheckLoginPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final bool isLoggedIn = await authViewModel.isLoggedIn();

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Loading while checking
      ),
    );
  }
}