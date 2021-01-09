class Endpoints {
  static final String scheme = "http";
  //static final String domain = "192.168.88.227:8085";
  //static final String domain = "192.168.0.108:8085";
  static final String domain = "mayak.ga";
  static final String gmapApi = '';

  static final String baseUrl = scheme + '://' + domain;
  static final String apiUrl = baseUrl + "/api";
  //static final String apiUrl = baseUrl;
  static final String wash = apiUrl + '/wash';
  static final String login = wash + "/login";
  static final String categories = wash + "/categories";
  static final String services = wash + "/services";
  static final String washers = wash + "/washers";
  static final String washer = wash + "/washer";
  static final String prices = wash + "/prices";
  static final String finish = wash + "/finish";
  static final String allday = wash + "/allday";
  static final String paid = wash + "/paid";
  static final String washes = apiUrl + "/washes";
  static final String fcmToken = apiUrl + "/user/fcm-token";
  static final String import = wash + "/import";
  static final String export = wash + "/export";
  static final String lastapi = wash + "/lastapi";
  static final String deleted = wash + "/deleted";
}
