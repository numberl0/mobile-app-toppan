import 'package:flutter/material.dart';

import 'login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // double _fontSize = 16.0;

  LoginController _controller = LoginController();

   @override
  void initState() {
    super.initState();
    loginCheck();
  }

  void loginCheck() async {
    try {
      await _controller.isTokenValid(context);
    } catch (err, stacktree) {
      print("Error during login check: $err");
      print("Stacktree : $stacktree");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration:  const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromARGB(255, 132, 194, 252),
              Color.fromARGB(255, 45, 152, 240),
              Color.fromARGB(255, 48, 114, 236),
              Color.fromARGB(255, 0, 93, 199),
            ],
          )
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: _page(),
        ),
    );
  }

  Widget _page() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Center(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _icon(),
              const SizedBox(height: 50),
              InputField(
                hintText: "Username",
                controller: _controller.usernameController,
                isPassword: false,
              ),
              const SizedBox(height: 30),
              InputField(
                hintText: "Password",
                controller: _controller.passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 50),
              _loginBtn(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(){
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        shape: BoxShape.circle
      ),
      child: const Icon(Icons.person, color:  Colors.white, size: 160,),
    );
  }


  Widget _loginBtn() {
    return ElevatedButton(
      onPressed: () {
        _controller.login(context);
      },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Colors.lightBlue
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Text(
          "เข้าสู่ระบบ",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.blue),
        ),
      ),
    );
  }

}

class InputField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;

  const InputField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
  }) : super(key: key);

  @override
  _PasswordInputFieldState createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<InputField> {
  bool _obscureText = true; // Initially hide password

  @override
  Widget build(BuildContext context) {
    var border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.white),
    );

    return TextField(
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 24),
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white),
        enabledBorder: border,
        focusedBorder: border,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText; // Toggle password visibility
                  });
                },
              )
            : null,
      ),
    );
  }
}
