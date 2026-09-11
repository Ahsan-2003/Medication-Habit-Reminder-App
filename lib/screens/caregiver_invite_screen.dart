import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/caregiver_link_model.dart';
import '../providers/auth_provider.dart';
import '../providers/caregiver_provider.dart';

class CaregiverInviteScreen extends StatefulWidget {
  const CaregiverInviteScreen({super.key});

  @override
  State<CaregiverInviteScreen> createState() => _CaregiverInviteScreenState();
}

class _CaregiverInviteScreenState extends State<CaregiverInviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<CaregiverProvider>().loadPatientLink(
          authProvider.currentUser!.id,
        );
      }
    });
  }

  Future<void> _generateInvite() async {
    final authProvider = context.read<AuthProvider>();
    final caregiverProvider = context.read<CaregiverProvider>();

    if (authProvider.currentUser == null) return;

    final link = await caregiverProvider.createInvite(
      patientId: authProvider.currentUser!.id,
      patientName: authProvider.currentUser!.name,
    );

    if (!mounted) return;

    if (link != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code generated!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            caregiverProvider.errorMessage ?? 'Failed to generate invite',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _revokeLink(CaregiverLinkModel link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Caregiver?'),
        content: Text(
          'This will remove ${link.caregiverName ?? "the caregiver"} from your account. '
          'They will no longer be able to see your progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final caregiverProvider = context.read<CaregiverProvider>();
    final success = await caregiverProvider.revokeLink(link.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Caregiver removed' : 'Failed to remove'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiverProvider = context.watch<CaregiverProvider>();
    final link = caregiverProvider.patientLink;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: link == null
            ? _buildNoLinkView(caregiverProvider)
            : link.isLinked
            ? _buildLinkedView(link)
            : _buildPendingView(link),
      ),
    );
  }

  Widget _buildNoLinkView(CaregiverProvider provider) {
    return Center(
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
            'No Caregiver Linked',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Generate an invite code and share it with a family member or caregiver so they can check in on your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: provider.isLoading ? null : _generateInvite,
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(
              provider.isLoading ? 'Generating...' : 'Generate Invite Code',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView(CaregiverLinkModel link) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Waiting for Caregiver',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this code with your caregiver',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Invite Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copyCode(link.inviteCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    link.inviteCode,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.copy, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap to copy',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Steps for your caregiver:\n'
              '1. Install MediRemind app\n'
              '2. Sign up as Caregiver\n'
              '3. Tap "Link to Patient"\n'
              '4. Enter this code',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.8),
            ),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => _revokeLink(link),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text(
              'Cancel Invite',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedView(CaregiverLinkModel link) {
    // ⭐ Watch the provider for live updates
    final provider = context.watch<CaregiverProvider>();
    final liveLink = provider.patientLink ?? link;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Linked header ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Caregiver Linked',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            liveLink.caregiverName ?? 'Caregiver',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Can view your progress',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Settings ──
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Missed Dose Alerts toggle
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Missed Dose Alerts'),
                  subtitle: const Text('Notify caregiver when you miss a dose'),
                  trailing: Switch(
                    value: liveLink.notifyOnMissedDose,
                    onChanged: (value) async {
                      final success = await provider.updateMissedDoseSettings(
                        linkId: liveLink.id,
                        notifyOnMissedDose: value,
                        graceMinutes: liveLink.missedDoseGraceMinutes,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? value
                                      ? 'Missed dose alerts enabled'
                                      : 'Missed dose alerts disabled'
                                : 'Failed to update',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    activeColor: Colors.teal,
                  ),
                ),
                const Divider(height: 1),

                // Grace Period
                ListTile(
                  leading: Icon(
                    Icons.timer,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Grace Period'),
                  subtitle: Text(
                    _formatGracePeriod(liveLink.missedDoseGraceMinutes),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showGraceePeriodPicker(liveLink),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Remove caregiver ──
          TextButton.icon(
            onPressed: () => _revokeLink(liveLink),
            icon: const Icon(Icons.link_off, color: Colors.red),
            label: const Text(
              'Remove Caregiver',
              style: TextStyle(color: Colors.red),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatGracePeriod(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes ~/ 60;
    return '$hours hour${hours > 1 ? "s" : ""}';
  }

  Future<void> _showGraceePeriodPicker(CaregiverLinkModel link) async {
    final options = [15, 30, 60, 120, 240]; // minutes

    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grace Period',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'How long to wait after a missed dose before alerting your caregiver',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...options.map((minutes) {
              final label = minutes < 60
                  ? '$minutes minutes'
                  : '${minutes ~/ 60} hour${minutes >= 120 ? "s" : ""}';

              return RadioListTile<int>(
                value: minutes,
                groupValue: link.missedDoseGraceMinutes,
                onChanged: (value) => Navigator.pop(context, value),
                title: Text(label),
                activeColor: Colors.teal,
              );
            }),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      final provider = context.read<CaregiverProvider>();
      await provider.updateMissedDoseSettings(
        linkId: link.id,
        notifyOnMissedDose: link.notifyOnMissedDose,
        graceMinutes: selected,
      );
    }
  }
}
