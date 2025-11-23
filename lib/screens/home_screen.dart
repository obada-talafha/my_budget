import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl; // نستخدم as لتجنب تضارب الأسماء
import '../providers/money_provider.dart';
import '../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedWeekIndex = 0; // 0 تعني الكل، 1 الأسبوع الأول، الخ

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final weeklyData = provider.getWeeklyTransactions();
    final weeksKeys = weeklyData.keys.toList()..sort(); // ترتيب الأسابيع

    // تحديد القائمة المعروضة بناءً على الأسبوع المختار
    List<Transaction> displayedTransactions = [];
    if (_selectedWeekIndex == 0) {
      // عرض الكل للشهر الحالي
      displayedTransactions = provider.getCurrentMonthTransactions();
    } else {
      displayedTransactions = weeklyData[_selectedWeekIndex] ?? [];
    }

    // ترتيب العمليات الأحدث فوق
    displayedTransactions.sort((a, b) => b.date.compareTo(a.date));


    return Scaffold(
      body: Column(
        children: [
          // --- الجزء العلوي: البطاقة والرصيد ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Text("إجمالي الرصيد", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(
                    "${(provider.currentCash + provider.currentWallet).toStringAsFixed(2)} JOD",
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBalanceItem("كاش", provider.currentCash, Icons.money),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildBalanceItem("محفظة/بنك", provider.currentWallet, Icons.account_balance_wallet),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- شريط الأسابيع ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _buildWeekTab(0, "كل الشهر", _selectedWeekIndex == 0),
                ...weeksKeys.map((weekNum) {
                  return _buildWeekTab(weekNum, "الأسبوع $weekNum", _selectedWeekIndex == weekNum);
                }).toList(),
              ],
            ),
          ),

          // --- ملخص المصاريف للأسبوع المختار ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedWeekIndex == 0 ? "مصاريف الشهر" : "مصاريف الأسبوع $_selectedWeekIndex",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "${provider.getWeeklyTotal(displayedTransactions).toStringAsFixed(2)} JOD",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),

          // --- قائمة العمليات ---
          Expanded(
            child: ListView.builder(
              itemCount: displayedTransactions.length,
              itemBuilder: (ctx, index) {
                final tx = displayedTransactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.isExpense ? Colors.red[50] : Colors.green[50],
                    child: Icon(
                      tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(tx.title),
                  subtitle: Text(intl.DateFormat('EEEE d/M - hh:mm a').format(tx.date)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${tx.amount} JOD",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.isExpense ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        tx.isCash ? "كاش" : "محفظة",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onLongPress: () => provider.deleteTransaction(tx),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTransactionDialog(context, provider),
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text("$amount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildWeekTab(int index, String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWeekIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, MoneyProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    bool isCash = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("إضافة عملية"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أزرار الفئات السريعة
              Wrap(
                spacing: 5,
                children: ["طعام", "مواصلات", "فواتير", "ترفيه", "سوبرماركت"].map((cat) {
                  return ActionChip(
                    label: Text(cat),
                    onPressed: () => titleController.text = cat,
                  );
                }).toList(),
              ),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "الوصف")),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "المبلغ"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("النوع: "),
                  ChoiceChip(
                    label: const Text("مصروف"),
                    selected: isExpense,
                    selectedColor: Colors.red[100],
                    onSelected: (val) => setState(() => isExpense = true),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("دخل (+)"),
                    selected: !isExpense,
                    selectedColor: Colors.green[100],
                    onSelected: (val) => setState(() => isExpense = false),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("المصدر: "),
                  ChoiceChip(
                    label: const Text("كاش"),
                    selected: isCash,
                    onSelected: (val) => setState(() => isCash = true),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("محفظة"),
                    selected: !isCash,
                    onSelected: (val) => setState(() => isCash = false),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  provider.addTransaction(
                    titleController.text,
                    double.parse(amountController.text),
                    isExpense,
                    isCash,
                    DateTime.now(),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }
}