abstract class Routes {
  static const root = '/';
  static const login = '/login';
  static const library = '/library';
  static const listen = '/listen';
  static const search = '/search';
  static const artist = '/artist';
  static const settings = '/settings';
  static const downloads = '/downloads';
  static const palette = '/palette';
  static const album = '/album';
}

extension RouteName on String {
  String get name => substring(1);
}
