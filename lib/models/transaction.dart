import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title; // الفئة: طعام، بنزين...
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final bool isExpense; // true = مصروف، false = دخل
  @HiveField(5)
  final bool isCash; // true = كاش، false = محفظة

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.isExpense = true,
    this.isCash = true,
  });
}