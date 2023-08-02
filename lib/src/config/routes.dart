abstract class Routes {
  static const root = '/';
  static const login = '/login';
  static const library = '/library';
  static const listen = '/listen';
  static const search = '/search';
  static const settings = '/settings';
  static const downloads = '/downloads';
  static const album = '$downloads/album';
}

extension RouteName on String {
  String get name => split('/').last;
}
