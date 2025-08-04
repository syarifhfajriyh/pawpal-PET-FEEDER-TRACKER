import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Server {
  static Server _server;
  static String baseURL = env["BASE_URL"];

  Map<String, dynamic> _responseObj = {};

  static Duration timeoutLimit = Duration(seconds: 3);

  Server._createInstance();
  factory Server() {
    if (_server == null) {
      _server = Server._createInstance();
    }
    return _server;
  }

  Future<String> login(String id, String password) async {
    _responseObj.clear();
    var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    var request = http.Request('POST', Uri.parse('$baseURL/login'));
    request.bodyFields = {'id': id, 'password': password};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        if (_responseObj["success"] == true) {
          String token = _responseObj["token"];
          return token;
        }
        return "";
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> isAuthorized(String token, String id) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request =
        http.Request('POST', Uri.parse('$baseURL/account/isauthorized'));
    request.bodyFields = {'id': id};
    request.headers.addAll(headers);
    ;
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        if (_responseObj["success"] == true) {
          return true;
        } else if (_responseObj.containsKey("action") &&
            _responseObj["action"] == "LOGOUT") {
          return false;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> feedNow(
      String token, String id, int quantity) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('POST', Uri.parse('$baseURL/feed'));
    request.bodyFields = {'id': id, 'quantity': quantity.toString()};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> connectionStatus(String token, String id) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('POST', Uri.parse('$baseURL/socket/state'));
    request.bodyFields = {'id': id};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> scheduleFeed(
      String token, String id, String date, int quantity) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('POST', Uri.parse('$baseURL/feed/schedule'));
    request.bodyFields = {
      'id': id,
      'date': date,
      'quantity': quantity.toString()
    };
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> rescheduleFeed(
      String token, String id, String date) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('PUT', Uri.parse('$baseURL/feed/schedule'));
    request.bodyFields = {'id': id, 'date': date};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> scheduledFeedList(
      String token, String id) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('GET', Uri.parse('$baseURL/feed/schedule'));
    request.bodyFields = {'id': id};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> descheduleFeed(String token, String id) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request('DELETE', Uri.parse('$baseURL/feed/schedule'));
    request.bodyFields = {'id': id};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> sendNotificationToken(
      String token, String id, String fcmToken) async {
    _responseObj.clear();
    var headers = {
      'Authorization': token,
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request =
        http.Request('POST', Uri.parse('$baseURL/notification/token'));
    request.bodyFields = {'id': id, 'fcmToken': fcmToken};
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response =
          await request.send().timeout(timeoutLimit);
      if (response.statusCode == 200) {
        _responseObj = jsonDecode(await response.stream.bytesToString());
        return _responseObj;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
