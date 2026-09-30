import 'package:flutter/material.dart';



class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  // ignore: unused_field
  // late final KitchenController _controller;

  @override
  void initState() {
    super.initState();
    // _controller = KitchenController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Display')),
      body: const Center(
        child: Text('KDS placeholder (akan diisi list order PROCESSING/PAID)'),
      ),
    );
  }
}

