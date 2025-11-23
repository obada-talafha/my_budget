import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 1)
class Debt extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String personName;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final bool isOwedToMe; // true = أريد منه، false = يريد مني

  Debt({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isOwedToMe,
  });
}