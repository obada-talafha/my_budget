import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';
import '../models/debt.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إدارة الديون"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "لي (Owed to Me)"),
              Tab(text: "علي (I Owe)"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDebtList(provider, true),
            _buildDebtList(provider, false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => _showAddDebtDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildDebtList(MoneyProvider provider, bool isOwedToMe) {
    final filteredDebts = provider.debts.where((d) => d.isOwedToMe == isOwedToMe).toList();

    if (filteredDebts.isEmpty) {
      return const Center(child: Text("لا يوجد ديون"));
    }

    return ListView.builder(
      itemCount: filteredDebts.length,
      itemBuilder: (ctx, index) {
        final debt = filteredDebts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(debt.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text("${debt.amount} JOD", style: const TextStyle(fontSize: 16, color: Colors.teal)),
            leading: IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _showSettleDialog(ctx, provider, debt),
            ),
          ),
        );
      },
    );
  }

  void _showSettleDialog(BuildContext context, MoneyProvider provider, Debt debt) {
    // عند سداد الدين، يمكننا اختيار حذفه أو تحويله لعملية مالية
    // للتبسيط هنا سنقوم بحذفه فقط
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("تم سداد الدين؟"),
      content: const Text("هل تريد حذف هذا الدين من القائمة؟"),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("لا")),
        ElevatedButton(onPressed: (){
          provider.deleteDebt(debt);
          Navigator.pop(ctx);
        }, child: const Text("نعم، احذفه")),
      ],
    ));
  }

  void _showAddDebtDialog(BuildContext context, MoneyProvider provider) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    bool isOwedToMe = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("إضافة دين جديد"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم الشخص")),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: "المبلغ"), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(label: const Text("لي"), selected: isOwedToMe, onSelected: (v) => setState(() => isOwedToMe = true)),
                  const SizedBox(width: 10),
                  ChoiceChip(label: const Text("علي"), selected: !isOwedToMe, onSelected: (v) => setState(() => isOwedToMe = false)),
                ],
              )
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                provider.addDebt(nameController.text, double.parse(amountController.text), isOwedToMe);
                Navigator.pop(ctx);
              },
              child: const Text("حفظ"),
            )
          ],
        ),
      ),
    );
  }
}