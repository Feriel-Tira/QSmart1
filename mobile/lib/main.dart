import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartqueue/core/config/app_config.dart';
import 'package:smartqueue/core/config/routes.dart';
import 'package:smartqueue/core/config/theme.dart';
import 'package:smartqueue/core/di/service_locator.dart';
import 'package:smartqueue/features/auth/bloc/auth_bloc.dart';
import 'package:smartqueue/features/queue/bloc/queue_bloc.dart';
import 'package:smartqueue/features/ticket/bloc/ticket_bloc.dart';
import 'package:smartqueue/graphql/client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les services
  await setupServiceLocator();

  runApp(const SmartQueueApp());
}

class SmartQueueApp extends StatelessWidget {
  const SmartQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProviderWidget(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => getIt<AuthBloc>()
              ..add(AuthStatusChecked()),
          ),
          BlocProvider<QueueBloc>(
            create: (context) => getIt<QueueBloc>(),
          ),
          BlocProvider<TicketBloc>(
            create: (context) => getIt<TicketBloc>(),
          ),
        ],
        child: MaterialApp(
          title: AppConfig.instance.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}