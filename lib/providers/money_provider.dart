import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/debt.dart';

class MoneyProvider with ChangeNotifier {
  // الصناديق (Boxes)
  final Box<Transaction> _transactionBox = Hive.box<Transaction>('transactions');
  final Box<Debt> _debtBox = Hive.box<Debt>('debts');
  final Box _settingsBox = Hive.box('settings');

  // إعدادات
  int get salaryDay => _settingsBox.get('salaryDay', defaultValue: 25);
  double get currentCash => _settingsBox.get('cash', defaultValue: 0.0);
  double get currentWallet => _settingsBox.get('wallet', defaultValue: 0.0);

  // قوائم البيانات
  List<Transaction> get transactions => _transactionBox.values.toList();
  List<Debt> get debts => _debtBox.values.toList();

  // ------------------- إدارة العمليات المالية -------------------

  void addTransaction(String title, double amount, bool isExpense, bool isCash, DateTime date) {
    final newTx = Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      date: date,
      isExpense: isExpense,
      isCash: isCash,
    );

    _transactionBox.add(newTx);
    _updateBalance(amount, isExpense, isCash);
    notifyListeners();
  }

  void deleteTransaction(Transaction tx) {
    // عند الحذف نعكس العملية لتصحيح الرصيد
    _updateBalance(tx.amount, !tx.isExpense, tx.isCash);
    tx.delete();
    notifyListeners();
  }

  void _updateBalance(double amount, bool isExpense, bool isCash) {
    double newCash = currentCash;
    double newWallet = currentWallet;

    if (isCash) {
      newCash = isExpense ? newCash - amount : newCash + amount;
      _settingsBox.put('cash', newCash);
    } else {
      newWallet = isExpense ? newWallet - amount : newWallet + amount;
      _settingsBox.put('wallet', newWallet);
    }
  }

  // ------------------- منطق تقسيم الأسابيع (السبت - الجمعة) -------------------

  // 1. تحديد بداية الشهر المالي الحالي
  DateTime getStartOfFinancialMonth() {
    final now = DateTime.now();
    if (now.day >= salaryDay) {
      return DateTime(now.year, now.month, salaryDay);
    } else {
      // نحن في شهر جديد لكن قبل يوم الراتب، إذاً الشهر المالي بدأ الشهر الماضي
      return DateTime(now.year, now.month - 1, salaryDay);
    }
  }

  // 2. جلب عمليات الشهر المالي الحالي فقط
  List<Transaction> getCurrentMonthTransactions() {
    final start = getStartOfFinancialMonth();
    // الشهر المالي ينتهي قبل يوم الراتب القادم
    final end = DateTime(start.year, start.month + 1, salaryDay);

    return transactions.where((tx) {
      return tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(end);
    }).toList();
  }

  // 3. تقسيم العمليات إلى أسابيع (تبدأ السبت)
  Map<int, List<Transaction>> getWeeklyTransactions() {
    final monthlyTx = getCurrentMonthTransactions();
    monthlyTx.sort((a, b) => b.date.compareTo(a.date)); // الأحدث أولاً

    Map<int, List<Transaction>> weeks = {};

    // نبدأ من بداية الشهر المالي
    DateTime cycleStart = getStartOfFinancialMonth();

    for (var tx in monthlyTx) {
      // حساب رقم الأسبوع بناءً على الفرق بين تاريخ العملية وبداية الشهر
      // معادلة تقريبية للتبسيط: كل 7 أيام أسبوع
      // لتحقيق شرط "الاسبوع يبدأ السبت":
      // نبحث عن أول سبت بعد نزول الراتب لضبط "الأسبوع 1" و "الأسبوع 2"
      // لكن للتبسيط هنا سنقوم بتجميعها حسب رقم الأسبوع في السنة أو الشهر

      // الحل الأبسط والفعال: استخدام الفرق بالأيام مقسوم على 7 مع إزاحة يوم السبت
      final diff = tx.date.difference(cycleStart).inDays;
      int weekIndex = (diff / 7).floor() + 1;

      if (!weeks.containsKey(weekIndex)) {
        weeks[weekIndex] = [];
      }
      weeks[weekIndex]!.add(tx);
    }
    return weeks;
  }

  double getWeeklyTotal(List<Transaction> txs) {
    double total = 0;
    for (var tx in txs) {
      if (tx.isExpense) total += tx.amount;
    }
    return total;
  }

  // ------------------- إدارة الديون -------------------

  void addDebt(String name, double amount, bool isOwedToMe) {
    final newDebt = Debt(
      id: const Uuid().v4(),
      personName: name,
      amount: amount,
      isOwedToMe: isOwedToMe,
    );
    _debtBox.add(newDebt);
    notifyListeners();
  }

  void deleteDebt(Debt debt) {
    debt.delete();
    notifyListeners();
  }

  // ------------------- الإعدادات -------------------
  void setSalaryDay(int day) {
    _settingsBox.put('salaryDay', day);
    notifyListeners();
  }

  void setInitialBalance(double cash, double wallet) {
    _settingsBox.put('cash', cash);
    _settingsBox.put('wallet', wallet);
    notifyListeners();
  }
}