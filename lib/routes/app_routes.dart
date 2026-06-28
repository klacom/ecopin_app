// Accessible by everyone

class PublicAppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String unauthorized = '/unauthorized';

  static const publicRoutes = [login, register, unauthorized];
}

// Only accessible by authenticated users

class ProtectedAppRoutes {
  static const String maps = '/maps';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String createReport = '/create-report';

  static const protectedRoutes = [maps, reports, notifications, profile, createReport];
}
