// The Arrays are to keep track of what routes are public or not.

// Accessible by everyone

class PublicAppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String unauthorized = '/unauthorized';

  static const publicRoutes = [login, register, unauthorized];
}

// Only accessible by authenticated users

class ProtectedAppRoutes {
  static const String maps = '/maps';
  static const String reports = '/reports';

  static const protectedRoutes = [maps, reports];
}
