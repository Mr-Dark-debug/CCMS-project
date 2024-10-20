import 'package:ccms/auditor_page.dart';
import 'package:ccms/organization_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(CarbonCreditApp());
}

class CarbonCreditApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon Credit Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
      routes: {
        '/organization': (context) => OrganizationPage(),
        '/auditor': (context) => AuditorPage(),
      },
    );
  }
}
