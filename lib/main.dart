import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SaknApp());
}

class SaknApp extends StatelessWidget {
  const SaknApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سكن الشباب',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'sans-serif',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

final List<String> members = [
  'حسام منصور',
  'شهاب سمير',
  'صالح احمد صالح',
  'كامل الشيباني',
];

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DutiesScreen(),
    ExpensesScreen(),
    ShoppingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_today), label: 'الأدوار والمهام'),
            NavigationDestination(icon: Icon(Icons.attach_money), label: 'المصاريف والقطة'),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'نواقص الغرفة'),
          ],
        ),
      ),
    );
  }
}

class DutiesScreen extends StatelessWidget {
  const DutiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayIndex = now.weekday % 4;

    final chef = members[dayIndex];
    final breadBoy = members[(dayIndex + 1) % 4];
    final cleaner = members[(dayIndex + 2) % 4];

    return Scaffold(
      appBar: AppBar(title: const Text('جدول اليوم ومناوبة السكن')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.teal.shade50,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('مهام اليوم الحالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(height: 25),
                    _buildDutyRow(Icons.restaurant, 'المسؤول عن الطباخة:', chef, Colors.orange),
                    const SizedBox(height: 12),
                    _buildDutyRow(Icons.bakery_dining, 'المسؤول عن الخبز والطلبات:', breadBoy, Colors.brown),
                    const SizedBox(height: 12),
                    _buildDutyRow(Icons.cleaning_services, 'المسؤول عن النظافة والترتيب:', cleaner, Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('طلاب الغرفة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(members[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyRow(IconData icon, String title, String name, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 15)),
        const Spacer(),
        Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المصاريف والقطة')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          double totalSpent = 0;
          Map<String, double> paidMap = {for (var m in members) m: 0.0};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final payer = data['paidBy'] as String;
            totalSpent += amount;
            if (paidMap.containsKey(payer)) {
              paidMap[payer] = paidMap[payer]! + amount;
            }
          }

          final sharePerPerson = totalSpent / 4;

          return Column(
            children: [
              Container(
                color: Colors.teal.shade100,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('إجمالي المصروف: ${totalSpent.toStringAsFixed(0)} | نصيب الفرد: ${sharePerPerson.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: members.map((m) {
                          final balance = paidMap[m]! - sharePerPerson;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Chip(
                              label: Text('$m: ${balance >= 0 ? "+${balance.toStringAsFixed(0)}" : balance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: balance >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  )),
                              backgroundColor: balance >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final item = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(item['title']),
                      subtitle: Text('دفعها: ${item['paidBy']}'),
                      trailing: Text('${item['amount']} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedPayer = members[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل مصروف جديد'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'الغرض (مثلاً: خضار، ماء)')),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedPayer,
                  isExpanded: true,
                  items: members.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                  onChanged: (val) => setState(() => selectedPayer = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('expenses').add({
                      'title': titleController.text,
                      'amount': double.parse(amountController.text),
                      'paidBy': selectedPayer,
                      'date': Timestamp.now(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('نواقص السكن')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemController,
                    decoration: const InputDecoration(hintText: 'اكتب الغرض الناقص...', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (itemController.text.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('shopping').add({
                        'item': itemController.text,
                        'isDone': false,
                        'createdAt': Timestamp.now(),
                      });
                      itemController.clear();
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('shopping').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return CheckboxListTile(
                      title: Text(data['item'], style: TextStyle(decoration: data['isDone'] ? TextDecoration.lineThrough : null)),
                      value: data['isDone'],
                      onChanged: (val) => doc.reference.update({'isDone': val}),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => doc.reference.delete(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
