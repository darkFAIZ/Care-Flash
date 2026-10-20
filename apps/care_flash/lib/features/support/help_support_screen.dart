import 'package:flutter/material.dart';

/// Help and support page with a scripted support chat.
///
/// The bot uses canned answers for now (no backend). It can be replaced with a
/// real support integration later without changing the UI.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const String route = '/support';

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromUser: false,
      text: 'Hi, I am the Care-Flash helper. Ask me about bookings, payment, '
          'safety or verification, or pick a topic below.',
    ),
  ];

  static const List<String> _topics = [
    'How do I book help?',
    'Payment and pricing',
    'Safety and reporting',
    'Verifying the caregiver',
    'Cancel a request',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(_ChatMessage(fromUser: true, text: text));
      _messages.add(_ChatMessage(fromUser: false, text: _reply(text)));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _reply(String input) {
    final text = input.toLowerCase();
    if (text.contains('book') || text.contains('request') || text.contains('help type')) {
      return 'Tap Need Help on the home page, choose a help type, set your '
          'boundary checklist, location, time and a caregiver gender filter, '
          'then review the price and pay.';
    }
    if (text.contains('pay') || text.contains('price') || text.contains('cost')) {
      return 'A caregiver costs IDR 25,000 per 30 minutes plus a 5% platform '
          'fee and the estimated Grab fare. You pay before the caregiver '
          'accepts, and you can retry if a payment fails.';
    }
    if (text.contains('safe') || text.contains('report') || text.contains('emergency')) {
      return 'During a session use Report, or press the physical safety button. '
          'This ends the session, notifies support and the emergency channel, '
          'and refunds your payment. End Early is separate.';
    }
    if (text.contains('verif') || text.contains('code') || text.contains('qr') || text.contains('nfc')) {
      return 'After payment you get a private client code. At arrival show it '
          'to the caregiver, then scan the safety button by QR or NFC. The '
          'session starts only after both checks pass.';
    }
    if (text.contains('cancel') || text.contains('refund')) {
      return 'You can cancel while matching. If no caregiver accepts, the '
          'booking is cancelled and your payment is refunded.';
    }
    if (text.contains('account') || text.contains('login') || text.contains('log in')) {
      return 'Use the Profile tab to find Settings and Log out. You can change '
          'the app language there too.';
    }
    return 'I am not sure about that yet. Try asking about bookings, payment, '
        'safety, verification or cancelling, or contact support.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help and support')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(message: _messages[index]),
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _topics.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(_topics[index]),
                  onPressed: () => _send(_topics[index]),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(),
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment =
        message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.fromUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = message.fromUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text, style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
      ),
    );
  }
}
