import 'package:app/helper/LocalStorage.dart';
import 'package:app/helper/Server.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Server server = Server();
  LocalStorage localStorage = LocalStorage();

  String _username = "";
  String _password = "";
  String _errorMessage = "";
  bool _connecting = false;

  bool _validate(String username, String password) {
    if (username != "" &&
        password != "" &&
        password.length >= 8 &&
        username.length >= 5) {
      return true;
    }
    String errorMessage = "";
    if (username == "" && password == "") {
      errorMessage = "Device ID and password required.";
    } else if (username == "") {
      errorMessage = "Device ID required.";
    } else if (password == "") {
      errorMessage = "Password required.";
    } else {
      errorMessage = "Invalid credentials.";
    }
    setState(() {
      _errorMessage = errorMessage;
    });
    return false;
  }

  void _login() async {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    if (this._errorMessage != "") {
      setState(() {
        _errorMessage = "";
      });
    }
    setState(() {
      _connecting = !_connecting;
    });
    bool validated = this._validate(this._username, this._password);
    String token;
    if (validated) {
      token = await server.login(this._username, this._password);
      if (token == "") {
        setState(() {
          _errorMessage = "Invalid Credentials.";
        });
      } else if (token == null) {
        setState(() {
          _errorMessage = "Request failed.";
        });
      } else {
        await localStorage.set("token", token);
        await localStorage.set("id", this._username);
        Navigator.pop(context, true);
      }
    }
    setState(() {
      _connecting = !_connecting;
    });
  }

  @override
  Widget build(BuildContext context) {
    Container messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15), topRight: Radius.circular(15)),
        color: _errorMessage == ""
            ? Theme.of(context).textTheme.bodyText2.color.withOpacity(0.1)
            : Colors.red,
      ),
      child: Center(
        child: Text(
          '$_errorMessage',
          style: TextStyle(
            color: Color(0xFFffffff),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
    return Container(
      child: Center(
        child: Column(
          children: [
            messageBar,
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Image.asset(
                "assets/logo.png",
                height: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Form(
                child: Column(
                  children: [
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "",
                        labelText: "Device ID",
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .bodyText2
                              .color
                              .withOpacity(0.5),
                          fontSize: 15.0,
                        ),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyText2.color,
                        fontSize: 16.0,
                      ),
                      onChanged: (String value) {
                        _username = value;
                      },
                    ),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "",
                        labelText: "Password",
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .bodyText2
                              .color
                              .withOpacity(0.5),
                          fontSize: 15.0,
                        ),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyText2.color,
                        fontSize: 16.0,
                      ),
                      onChanged: (String value) {
                        _password = value;
                      },
                    ),
                    Container(
                      width: 140,
                      child: _connecting
                          ? Center(
                              child: RefreshProgressIndicator(),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                onPrimary: Color(0xFF0e2a47),
                                primary: Theme.of(context).primaryColor,
                              ),
                              child: Text(
                                'Connect',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.0,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              onPressed: _connecting ? () {} : this._login,
                            ),
                      margin: new EdgeInsets.only(top: 20.0),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
