import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final salaryDayController = TextEditingController(text: provider.salaryDay.toString());
    final cashController = TextEditingController(text: provider.currentCash.toString());
    final walletController = TextEditingController(text: provider.currentWallet.toString());

    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("تحديد يوم الراتب", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: salaryDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(helperText: "يوم نزول الراتب (مثلاً 25)"),
              onSubmitted: (val) => provider.setSalaryDay(int.parse(val)),
            ),
            const Divider(height: 40),
            const Text("تعديل الرصيد الحالي يدوياً", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: cashController, decoration: const InputDecoration(labelText: "رصيد الكاش الحالي")),
            TextField(controller: walletController, decoration: const InputDecoration(labelText: "رصيد المحفظة الحالي")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                provider.setInitialBalance(
                  double.parse(cashController.text),
                  double.parse(walletController.text),
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التحديث")));
              },
              child: const Text("تحديث الأرصدة"),
            )
          ],
        ),
      ),
    );
  }
}