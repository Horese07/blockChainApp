import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_linking.dart';
import 'helloUI.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ContractLinking(),
      child: MaterialApp(
        title: 'Flutter DApp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: HelloUI(),
      ),
    );
  }
}
