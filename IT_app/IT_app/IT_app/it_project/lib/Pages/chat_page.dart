import 'package:flutter/material.dart';

// gets the phone's GPS position.
import 'package:geolocator/geolocator.dart';

// handles login errors.
import 'auth_api.dart';
// stores the signed-in user and access token.
import 'auth_store.dart';
// handles chatbot messages and reports.
import 'chat_api.dart';

// reads the phone's current location.
Future<(double, double)> deviceLocation() async {

  // checks if location services are enabled.
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const ChatApiException(
      'Turn on location.',
    );
  }

  // checks location permission.
  var permission = await Geolocator.checkPermission();

  // requests permission if needed.
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  // stops if location permission is denied.
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const ChatApiException(
      'Allow location access in the app settings.',
    );
  }

  // gets the current GPS position.
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );

  // returns the latitude and longitude.
  return (position.latitude, position.longitude);
}

// stores each chat message and its report details.
class _Bubble {
  _Bubble({
    required this.isUser,
    required this.text,
    this.draft,
    this.isError = false,
    this.isLocal = false,
  });

  final bool isUser;
  final String text;
  final ReportDraft? draft;
  final bool isError;
  final bool isLocal;

  bool draftHandled = false;
}

// displays the chatbot and helps users report problems.
class ChatPage extends StatefulWidget {
  // allows custom clients and locations for testing.
  const ChatPage({super.key, this.api, this.locate});

  final ChatApi? api;
  final Future<(double, double)> Function()? locate;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// manages chat messages and report submissions.
class _ChatPageState extends State<ChatPage> {
  // sets up the chat client.
  late final ChatApi _api = widget.api ?? ChatApi();
  late final bool _ownsApi = widget.api == null;

  // manages the text input and scrolling.
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // displays the welcome message.
  final List<_Bubble> _messages = [
    _Bubble(
      isUser: false,
      isLocal: true,
      text:
      "Hi! I'm the Fix My City assistant. I can explain how the app works, "
          'tell you what is happening in your area, or help you report a problem.',
    ),
  ];

  // tracks message sending and report submission.
  bool _sending = false;
  bool _submitting = false;

  // releases resources when the screen closes.
  @override
  void dispose() {
    if (_ownsApi) _api.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // prepares previous messages for the chatbot.
  List<ChatMessage> _history() {
    final all = _messages
        .where((bubble) => !bubble.isError && !bubble.isLocal)
        .map(
          (bubble) => ChatMessage(
        role: bubble.isUser ? 'user' : 'assistant',
        content: bubble.text,
      ),
    )
        .toList();

    // sends only the latest 20 messages.
    return all.length > 20 ? all.sublist(all.length - 20) : all;
  }

  // scrolls to the latest message.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // displays an error message.
  void _addError(String message) {
    if (!mounted) return;
    setState(() => _messages.add(_Bubble(isUser: false, text: message, isError: true)));
    _scrollToEnd();
  }

  // sends a message and displays the reply.
  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    setState(() {
      _messages.add(_Bubble(isUser: true, text: trimmed));
      _sending = true;
    });

    _input.clear();
    _scrollToEnd();

    try {
      // sends the message using the user's access token.
      final reply = await AuthStore.withAccessToken(
            (_, token) => _api.send(token, _history()),
      );

      if (!mounted) return;
      setState(() => _messages.add(_Bubble(isUser: false, text: reply.reply, draft: reply.draft)));
    } on AuthApiException catch (error) {
      _addError(error.message);
    } on ChatApiException catch (error) {
      _addError(error.message);
    } catch (_) {
      _addError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  // submits the prepared report.
  Future<void> _submitDraft(_Bubble bubble) async {
    final draft = bubble.draft;
    final areaId = AuthStore.currentUser?.areaId;

    if (draft == null || _submitting) return;

    // checks that the user's area is available.
    if (areaId == null) {
      _addError('Your account has no area yet, so a report cannot be submitted.');
      return;
    }

    setState(() => _submitting = true);

    try {
      // gets the phone's location.
      final (latitude, longitude) = await (widget.locate ?? deviceLocation)();

      // submits the report using the access token.
      final joined = await AuthStore.withAccessToken(
            (_, token) => _api.submitReport(
          accessToken: token,
          areaId: areaId,
          draft: draft,
          latitude: latitude,
          longitude: longitude,
        ),
      );

      if (!mounted) return;

      // marks the draft as handled and displays the result.
      setState(() {
        bubble.draftHandled = true;
        _messages.add(
          _Bubble(
            isUser: false,
            isLocal: true,
            text: joined
                ? 'Done! This problem had already been reported, so your report was added to it.'
                : 'Done! Your report has been submitted.',
          ),
        );
      });
    } on AuthApiException catch (error) {
      _addError(error.message);
    } on ChatApiException catch (error) {
      _addError(error.message);
    } catch (_) {
      _addError('Could not submit the report. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
      _scrollToEnd();
    }
  }

  // builds the chatbot screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix My City assistant'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // displays the conversation.
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _typingIndicator();
                  return _bubbleView(_messages[index]);
                },
              ),
            ),
            // shows example questions before chatting starts.
            if (_messages.length == 1) _suggestions(),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  // displays suggested questions.
  Widget _suggestions() {
    const questions = [
      'How do I report an issue?',
      "What's happening in my area?",
      'Help me report a problem',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final question in questions)
            ActionChip(label: Text(question), onPressed: () => _send(question)),
        ],
      ),
    );
  }

  // provides the message input and send button.
  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: const InputDecoration(
                hintText: 'Ask a question or describe a problem',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Send',
            onPressed: _sending ? null : () => _send(_input.text),
            icon: const Icon(Icons.send, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // shows a loading indicator while waiting for a reply.
  Widget _typingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // displays a chat message.
  Widget _bubbleView(_Bubble bubble) {
    final background = bubble.isError
        ? Colors.orange.withValues(alpha: 0.15)
        : bubble.isUser
        ? Colors.red
        : Colors.white;
    final foreground = bubble.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: bubble.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bubble.text, style: TextStyle(color: foreground, fontSize: 15)),
            if (bubble.draft != null && !bubble.draftHandled) _draftCard(bubble),
          ],
        ),
      ),
    );
  }

  // displays the report details before submission.
  Widget _draftCard(_Bubble bubble) {
    final draft = bubble.draft!;

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
        style: const TextStyle(color: Colors.black87),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report ready to submit', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          line('Category', draft.categoryLabel),
          line('Problem', draft.issueTypeLabel),
          line('Location', draft.location),
          if (draft.description.isNotEmpty) line('Details', draft.description),
          const Text(
            'Your phone\'s current location will be used as the report\'s position.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _submitting ? null : () => _submitDraft(bubble),
                child: Text(_submitting ? 'Submitting...' : 'Submit report'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _submitting ? null : () => setState(() => bubble.draftHandled = true),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}