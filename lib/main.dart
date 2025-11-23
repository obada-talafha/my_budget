import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
// Imports
import 'models/transaction.dart';
import 'models/debt.dart';
import 'providers/money_provider.dart';
import 'screens/home_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // تسجيل المودلز (سيتم تفعيل هذا الكود بعد توليد الملفات)
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(DebtAdapter());

  // فتح الصناديق
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Debt>('debts');
  await Hive.openBox('settings');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoneyProvider()),
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
      debugShowCheckedModeBanner: false,
      title: 'مدير المصاريف',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Segoe UI', // خط يدعم العربية بشكل جيد افتراضياً
      ),
      // ندعم اللغة العربية (RTL)
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const DebtsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "الرئيسية"),
          NavigationDestination(icon: Icon(Icons.people), label: "الديون"),
          NavigationDestination(icon: Icon(Icons.settings), label: "الإعدادات"),
        ],
      ),
    );
  }
}