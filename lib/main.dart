import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/database_service.dart';
import 'services/file_manager.dart';
import 'services/selection_manager.dart';
import 'services/share_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.init();
  
  final apiService = ApiService(baseUrl: 'http://localhost:8000');
  final shareService = ShareService(baseUrl: apiService.baseUrl);
  final syncService = SyncService(
    apiService: apiService,
    databaseService: databaseService,
  );
  final fileManager = FileManager(
    apiService: apiService,
    databaseService: databaseService,
    syncService: syncService,
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        Provider<DatabaseService>(create: (_) => databaseService),
        Provider<ShareService>(create: (_) => shareService),
        Provider<SyncService>(create: (_) => syncService),
        Provider<FileManager>(create: (_) => fileManager),
        ChangeNotifierProvider<SelectionManager>(
          create: (_) => SelectionManager(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZhiTrend NAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
