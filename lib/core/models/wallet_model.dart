class Transaction {
  final String id;
  final String type; // 'cash-in' atau 'cash-out'
  final num amount;
  final String description;
  final String status; // 'confirmed' atau 'pending'
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    if (json['timestamp'] != null && json['timestamp']['_seconds'] != null) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
        json['timestamp']['_seconds'] * 1000,
      );
    } else {
      parsedTimestamp = DateTime.now();
    }

    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'cash-in',
      amount: json['amount'] ?? 0,
      description: json['description'] ?? 'Tidak ada deskripsi',
      status: json['status'] ?? 'pending',
      timestamp: parsedTimestamp,
    );
  }
}

class Wallet {
  final num currentBalance;
  final num heldBalance;
  final bool withdrawalBlocked;
  final String? withdrawalBlockedReason;
  final List<Transaction> transactions;

  Wallet({
    required this.currentBalance,
    required this.heldBalance,
    this.withdrawalBlocked = false,
    this.withdrawalBlockedReason,
    required this.transactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    var transactionsList = json['transactions'] as List<dynamic>? ?? [];
    List<Transaction> parsedTransactions = transactionsList
        .map((i) => Transaction.fromJson(i))
        .toList();

    return Wallet(
      currentBalance: json['currentBalance'] ?? 0,
      heldBalance: json['heldBalance'] ?? 0,
      withdrawalBlocked: json['withdrawalBlocked'] == true,
      withdrawalBlockedReason: json['withdrawalBlockedReason']?.toString(),
      transactions: parsedTransactions,
    );
  }
}
