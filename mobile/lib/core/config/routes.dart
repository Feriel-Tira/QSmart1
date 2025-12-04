import 'package:flutter/material.dart';
import 'package:smartqueue/features/auth/pages/login_page.dart';
import 'package:smartqueue/features/auth/pages/register_page.dart';
import 'package:smartqueue/features/queue/pages/home_page.dart';
import 'package:smartqueue/features/queue/pages/queue_detail_page.dart';
import 'package:smartqueue/features/ticket/pages/ticket_page.dart';
import 'package:smartqueue/features/profile/pages/profile_page.dart';
import 'package:smartqueue/features/splash/pages/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String queueDetail = '/queue-detail';
  static const String ticket = '/ticket';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case queueDetail:
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => QueueDetailPage(queueId: args),
        );
      case ticket:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TicketPage(
            ticketId: args['ticketId'],
            queueId: args['queueId'],
          ),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}