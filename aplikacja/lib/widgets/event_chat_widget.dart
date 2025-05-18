import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode

class EventChatWidget extends StatefulWidget {
  final String eventId;
  final int userId; // Zakładając, że masz sposób na uzyskanie ID bieżącego użytkownika

  const EventChatWidget({Key? key, required this.eventId, required this.userId}) : super(key: key);

  @override
  _EventChatWidgetState createState() => _EventChatWidgetState();
}

class _EventChatWidgetState extends State<EventChatWidget> {
  final TextEditingController _controller = TextEditingController();
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _messages = []; // Przechowuje wiadomości wraz z informacjami o użytkowniku
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToChat();
  }

  Future<void> _connectToChat() async {
    try {
      // Zmiana protokołu z https na wss i upewnienie się, że ścieżka jest poprawna
      final uri = Uri.parse('wss://vps.jakosinski.pl:5000/chat?userId=${widget.userId}&eventId=${widget.eventId}');
      print('Próba połączenia WebSocket: $uri');
      
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          if (mounted) {
            setState(() {
              try {
                final decodedMessage = jsonDecode(message);

                if (decodedMessage is Map<String, dynamic> && decodedMessage.containsKey('type')) {
                  if (decodedMessage['type'] == 'history') {
                    // Obsługa historii wiadomości
                    if (decodedMessage['data'] is List) {
                      _messages = List<Map<String, dynamic>>.from(decodedMessage['data']);
                    }
                  } else if (decodedMessage['type'] == 'new_message') {
                    // Obsługa nowej wiadomości
                     if (decodedMessage['data'] is Map<String, dynamic>) {
                       _messages.add(decodedMessage['data']);
                     }
                  }
                } else if (decodedMessage is Map<String, dynamic> && // Starsza obsługa, może być potrzebna dla niektórych serwerów
                    decodedMessage.containsKey('user_id') &&
                    decodedMessage.containsKey('content')) {
                  _messages.add(decodedMessage);
                }
              } catch (e) {
                print('Błąd dekodowania wiadomości: $e');
                // Obsługa wiadomości niebędących JSON-em lub dodanie ogólnego wyświetlania
                 _messages.add({'user_id': 0, 'nickname': 'System', 'content': message, 'is_system': true});
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Błąd połączenia z czatem: $error';
              _isLoading = false;
            });
            print('Błąd WebSocket: $error');
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              // Opcjonalnie, możesz spróbować połączyć się ponownie tutaj lub poinformować użytkownika.
              print('Połączenie WebSocket zostało zamknięte.');
            });
          }
        },
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się połączyć z WebSocket: $e';
          _isLoading = false;
        });
      }
      print('Błąd podczas ustanawiania połączenia WebSocket: $e');
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _channel != null) {
      final messageData = {
        'event_id': widget.eventId,
        'user_id': widget.userId,
        'content': _controller.text,
      };
      // Serwer oczekuje zdarzenia 'send_message' z danymi w formacie JSON
      _channel!.sink.add(jsonEncode({'event': 'send_message', 'data': messageData}));
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
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
              final bool isMe = message['user_id'] == widget.userId;
              final bool isSystem = message['is_system'] ?? false;
              final String nickname = message['nickname'] ?? 'Użytkownik ${message['user_id']}';

              if (isSystem) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(message['content'], style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                );
              }

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
                        nickname,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                      ),
                      SizedBox(height: 4),
                      Text(
                        message['content'] ?? 'Nieprawidłowy format wiadomości', // Obsługa przypadków, gdy treść może być null
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
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
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userId'); // Zakładając, że 'userId' jest przechowywane w SharedPreferences
}

