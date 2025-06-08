import 'package:flutter/material.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../models/chat_message.dart';

class EventChatWidget extends StatefulWidget {
  final String eventId;
  final int userId;

  const EventChatWidget({Key? key, required this.eventId, required this.userId}) : super(key: key);

  @override
  _EventChatWidgetState createState() => _EventChatWidgetState();
}

class _EventChatWidgetState extends State<EventChatWidget> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastMessageTimestamp;
  Timer? _pollingTimer;
  static const int pollInterval = 3000; // 3 sekundy

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await _fetchMessages();
      _startPolling();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie udało się załadować czatu: $e';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(milliseconds: pollInterval),
      (_) => _fetchMessages(),
    );
  }

  Future<void> _fetchMessages() async {
    try {
      final messagesData = await DatabaseHelper.getEventChatMessages(
        widget.eventId,
        since: _lastMessageTimestamp,
      );

      if (messagesData.isEmpty) return;

      final newMessages = messagesData
          .map((data) => ChatMessage.fromJson(data))
          .toList();

      if (newMessages.isNotEmpty) {
        setState(() {
          if (_lastMessageTimestamp == null) {
            _messages = newMessages;
          } else {
            final existingIds = _messages.map((m) => m.id).toSet();
            final uniqueNewMessages = newMessages.where((m) => !existingIds.contains(m.id)).toList();
            _messages.addAll(uniqueNewMessages);
          }
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _lastMessageTimestamp = _messages.last.timestamp;
        });
      }
    } catch (e) {
      print('Błąd podczas pobierania wiadomości: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    try {
      await DatabaseHelper.sendChatMessage(widget.eventId, _controller.text);
      _controller.clear();
      await _fetchMessages(); // Natychmiastowe odświeżenie po wysłaniu
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wysłać wiadomości: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)));
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final bool isMe = message.userId == widget.userId.toString();

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.nickname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        message.text,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, -1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Wpisz wiadomość...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onSubmitted: (text) => _sendMessage(),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Funkcja pomocnicza do pobierania ID użytkownika (zastąp rzeczywistą implementacją)
Future<int?> getCurrentUserId() async {
  try {
    final userIdString = await DatabaseHelper.getUserIdFromToken();
    return int.tryParse(userIdString);
  } catch (e) {
    print('Błąd podczas pobierania userId: $e');
    return null;
  }
}

