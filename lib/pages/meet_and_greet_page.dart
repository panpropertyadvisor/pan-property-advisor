import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetAndGreetPage extends StatefulWidget {
  final Map<String, dynamic> selectedUser;

  const MeetAndGreetPage({super.key, required this.selectedUser});

  @override
  State<MeetAndGreetPage> createState() => _MeetAndGreetPageState();
}

class _MeetAndGreetPageState extends State<MeetAndGreetPage> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a message before sending."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final investor = FirebaseAuth.instance.currentUser;
    if (investor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to send a message."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final professional = widget.selectedUser;

      // Get investor name from Firestore if possible
      String investorName = investor.email ?? 'Investor';
      try {
        final investorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(investor.uid)
            .get();
        if (investorDoc.exists) {
          final data = investorDoc.data();
          investorName =
              data?['fullName'] ?? data?['name'] ?? investorName;
        }
      } catch (_) {}

      final professionalId =
          professional['id'] ?? professional['uid'] ?? '';
      final professionalRole = professional['role'] ?? '';

      final docRef =
          FirebaseFirestore.instance.collection('meet_requests').doc();

      await docRef.set({
        'investorId': investor.uid,
        'investorName': investorName,
        'investorEmail': investor.email ?? '',
        'professionalId': professionalId,
        'professionalName':
            professional['fullName'] ?? professional['name'] ?? '',
        'professionalEmail': professional['email'] ?? '',
        'professionalRole': professionalRole,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'paidAt': null,
      });

      final String recipientEmail = professional['email'] ?? '';
      final String investorEmailAddress = investor.email ?? 'No email provided';

      if (recipientEmail.isNotEmpty) {
        await FirebaseFirestore.instance.collection('mail').add({
          'to': recipientEmail,
          'replyTo': investor.email ?? '',
          'message': {
            'subject': 'New Meet & Greet Request from $investorName',
            'text': 'You have received a new meet & greet request from $investorName ($investorEmailAddress):\n\n$message',
            'html': '''
              <h3>New Meet & Greet Request</h3>
              <p><strong>From:</strong> $investorName ($investorEmailAddress)</p>
              <p><strong>Message:</strong></p>
              <p style="background-color: #f4f4f4; padding: 12px; border-radius: 4px;">$message</p>
            ''',
          },
        });
      }

      // Update investor profile so dashboard can disable Meet & Greet
      await FirebaseFirestore.instance.collection('users').doc(investor.uid).set({
        'activeMeetRequestId': docRef.id,
        'meetRequestStatus': 'pending',
        'selectedProfessionalId': professionalId,
        'selectedProfessionalRole': professionalRole,
      }, SetOptions(merge: true));

      if (!mounted) return;

      _messageController.clear();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Message Sent"),
          content: const Text(
            "Message sent. You will be contacted within 24–48 hours. If not, please contact us to raise a complaint.",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: const Color(0xFFFFD700),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop({
                  'requestId': docRef.id,
                  'status': 'pending',
                  'id': professionalId,
                  'data': professional,
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send message: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.selectedUser['fullName'] ??
        widget.selectedUser['name'] ??
        'Professional';
    final role = widget.selectedUser['role'] == 'mortgage_broker'
        ? 'Mortgage Broker'
        : 'Buyers Agent';
    final email = widget.selectedUser['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Meet & Greet: $name"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.person,
                          color: Color(0xFFFFD700), size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(role,
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(email, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Start Communication",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Send an initial message to introduce yourself and share details about your investment goals.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText:
                    "Hi $name, I'm interested in working with you on my next property investment...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFD700),
                        ),
                      )
                    : const Icon(Icons.send, color: Color(0xFFFFD700)),
                label: Text(
                  _isSending ? "Sending..." : "Send Message",
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}