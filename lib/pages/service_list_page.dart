import 'package:flutter/material.dart';
import '../widgets/service_card.dart';

class ServiceListPage extends StatelessWidget {
  final String categoryName;

  const ServiceListPage({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(categoryName),
      ),
    );
  }
}

