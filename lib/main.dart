import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/file_manager.dart';
import 'services/download_service.dart';
import 'services/search_service.dart';
import 'services/share_service.dart';
import 'services/selection_manager.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService(
    baseUrl: 'http://192.168.1.6:8000',  // 更新为实际的服务器IP地址
  );
  
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  final downloadService = DownloadService(apiService);
  await DownloadService.initialize();
  DownloadService.registerCallback();

  final searchService = SearchService(baseUrl: apiService.baseUrl);
  final shareService = ShareService(baseUrl: apiService.baseUrl);
  
  final syncService = SyncService(
    apiService: apiService,
    databaseService: databaseService,
  );
  await syncService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<DownloadService>.value(value: downloadService),
        Provider<SearchService>.value(value: searchService),
        Provider<ShareService>.value(value: shareService),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider(create: (_) => SelectionManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
