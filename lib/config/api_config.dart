class ApiConfig {
  // static const String apiBaseUrl = 'http://192.168.31.193:5000';  // genymotion use backend ip
  // static const String apiBaseUrl = 'http://10.0.2.2:5000';
  static const String apiBaseUrl = 'http://127.0.0.1:5000';
  // static const String apiBaseUrl = 'https://51axsujz29jr.share.zrok.io';
  // static const String apiBaseUrl = 'http://192.168.31.193:5000';
  static const String authPipe  = 'auth';
  static const String visitorPipe = 'visitor';

  //Visitor
  // static const String vApp_vPhotoPath  = 'D:\Flutter_workspace\toppan_app\visitor_app_photo\visitor';
  // static const String vApp_ePhotoPath  = 'D:\Flutter_workspace\toppan_app\visitor_app_photo\employee';

  static const http200 = 200; //Status Ok
  static const http500 = 500; //
  static const http503 = 503; //Proxy is not active
}