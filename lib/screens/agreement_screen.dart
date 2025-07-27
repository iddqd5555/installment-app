import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgreementScreen extends StatelessWidget {
  const AgreementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อตกลงผ่อนทอง', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: accent)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Center(
        child: Text(
          'หน้าข้อตกลงผ่อนทอง',
          style: GoogleFonts.prompt(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
        ),
      ),
    );
  }
}
