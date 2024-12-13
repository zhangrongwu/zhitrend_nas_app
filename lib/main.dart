import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    baseUrl: 'http://localhost:8000', // 在实际应用中应该从配置文件读取
  );
  
  final databaseService = DatabaseService();
  
  final downloadService = DownloadService(apiService);
  await downloadService.initialize();
  DownloadService.registerCallback();

  final searchService = SearchService(baseUrl: apiService.baseUrl);
  final shareService = ShareService(baseUrl: apiService.baseUrl);
  
  final syncService = SyncService(
    apiService: apiService,
    databaseService: databaseService,
  );

  runApp(MyApp(
    apiService: apiService,
    databaseService: databaseService,
    downloadService: downloadService,
    searchService: searchService,
    shareService: shareService,
    syncService: syncService,
  ));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final DatabaseService databaseService;
  final DownloadService downloadService;
  final SearchService searchService;
  final ShareService shareService;
  final SyncService syncService;

  const MyApp({
    super.key,
    required this.apiService,
    required this.databaseService,
    required this.downloadService,
    required this.searchService,
    required this.shareService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: apiService),
        Provider.value(value: databaseService),
        Provider.value(value: downloadService),
        Provider.value(value: searchService),
        Provider.value(value: shareService),
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProxyProvider<ApiService, FileManager>(
          create: (context) => FileManager(
            apiService: apiService,
            databaseService: databaseService,
            syncService: syncService,
          ),
          update: (context, apiService, previous) =>
              previous ?? FileManager(
                apiService: apiService,
                databaseService: databaseService,
                syncService: syncService,
              ),
        ),
        ChangeNotifierProxyProvider<ApiService, SelectionManager>(
          create: (context) => SelectionManager(apiService),
          update: (context, apiService, previous) =>
              previous ?? SelectionManager(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'ZhiTrend NAS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
