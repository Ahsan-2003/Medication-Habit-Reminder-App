import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class CaregiverLinkScreen extends StatefulWidget {
  @override
  _CaregiverLinkScreenState createState() => _CaregiverLinkScreenState();
}

class _CaregiverLinkScreenState extends State<CaregiverLinkScreen> {
  final _codeController = TextEditingController();
  String _generatedCode = '';

  Future<void> _generateCode() async {
    final code = await context.read<AuthProvider>().generateInviteCode();
    setState(() => _generatedCode = code);
  }

  Future<void> _linkCaregiver() async {
    final code = _codeController.text.trim();
    final patientId = await FirestoreService.getUserIdByInviteCode(code);
    if (patientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid code')));
      return;
    }
    final caregiverId = context.read<AuthProvider>().firebaseUser!.uid;
    // Prevent self-link
    if (patientId == caregiverId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot link to yourself')));
      return;
    }
    await FirestoreService.linkCaregiver(patientId, caregiverId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Linked successfully!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Caregiver Linking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate invite code for your caregiver:'),
            ElevatedButton(
              onPressed: _generateCode,
              child: Text('Generate Code'),
            ),
            if (_generatedCode.isNotEmpty) Text('Your code: $_generatedCode'),
            Divider(),
            Text('Or enter a code to link as caregiver:'),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Enter code'),
            ),
            ElevatedButton(
              onPressed: _linkCaregiver,
              child: Text('Link as Caregiver'),
            ),
          ],
        ),
      ),
    );
  }
}
