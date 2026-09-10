import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/caregiver_provider.dart';
import 'link_to_patient_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<CaregiverProvider>().loadCaregiverLinks(
          authProvider.currentUser!.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final caregiverProvider = context.watch<CaregiverProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: caregiverProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : caregiverProvider.caregiverLinks.isEmpty
          ? _buildEmptyState()
          : _buildPatientList(caregiverProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LinkToPatientScreen(),
            ),
          );

          if (result == true && mounted) {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.currentUser != null) {
              context.read<CaregiverProvider>().loadCaregiverLinks(
                authProvider.currentUser!.id,
              );
            }
          }
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Link New Patient'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Patients Linked',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask your patient to share their 6-character invite code and link their account to monitor their progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LinkToPatientScreen(),
                  ),
                );

                if (result == true && mounted) {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.currentUser != null) {
                    context.read<CaregiverProvider>().loadCaregiverLinks(
                      authProvider.currentUser!.id,
                    );
                  }
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Link to Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(CaregiverProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.caregiverLinks.length,
      itemBuilder: (context, index) {
        final link = provider.caregiverLinks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.teal.withOpacity(0.2),
              child: Text(
                link.patientName.isNotEmpty
                    ? link.patientName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            title: Text(
              link.patientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Linked ${_formatDate(link.linkedAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to patient adherence view (Feature 7)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing ${link.patientName}\'s progress'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'recently';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
