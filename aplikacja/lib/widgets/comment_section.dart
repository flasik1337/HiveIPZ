import 'package:flutter/material.dart';
import '../models/comments.dart';
import '../database/database_helper.dart';
import '../styles/hive_colors.dart';

class CommentSection extends StatefulWidget {
  final String eventId;

  const CommentSection({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController commentController = TextEditingController();
  List<Comment> comments = [];
  bool isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  // Pobranie komentarzy z serwera
  Future<void> _fetchComments() async {
    setState(() {
      isLoadingComments = true;
    });
    
    try {
      // Pobieranie komentarzy z serwera poprzez DatabaseHelper
      final commentsData = await DatabaseHelper.getEventComments(widget.eventId);
      
      setState(() {
        comments = commentsData.map((commentJson) => Comment.fromJson(commentJson)).toList();
      });
    } catch (e) {
      print('Błąd podczas pobierania komentarzy: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się pobrać komentarzy')),
      );
      
      // W przypadku błędu - wyświetl przykładowe komentarze do testowania UI
      // Docelowo ten kod powinien zostać usunięty po pełnej implementacji API komentarzy
      setState(() {
        comments = [
          Comment(
            id: '1',
            userId: '123',
            username: 'Użytkownik1',
            text: 'Super wydarzenie! Na pewno przyjdę.',
            createdAt: DateTime.now().subtract(Duration(days: 2)),
          ),
          Comment(
            id: '2',
            userId: '456',
            username: 'Użytkownik2',
            text: 'Jaki jest plan na to wydarzenie?',
            createdAt: DateTime.now().subtract(Duration(hours: 5)),
          ),
        ];
      });
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  // Dodanie nowego komentarza
  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      // Dodawanie komentarza na serwerze poprzez DatabaseHelper
      await DatabaseHelper.addEventComment(widget.eventId, text);
      
      // Po pomyślnym dodaniu komentarza pobieramy zaktualizowaną listę komentarzy
      await _fetchComments();
    } catch (e) {
      print('Błąd podczas dodawania komentarza: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się dodać komentarza')),
      );
    }
  }

  // Formatowanie daty dla komentarzy
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dni temu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} godz. temu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min. temu';
    } else {
      return 'Przed chwilą';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Komentarze',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? const Center(child: Text('Nie ma jeszcze komentarzy'))
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(comment.createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.text),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Dodaj komentarz...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: HiveColors.main,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: HiveColors.main,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: HiveColors.main,
                ),
                onPressed: () {
                  _addComment(commentController.text).then((_) {
                    commentController.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Pomocnicza metoda do wyświetlania sekcji komentarzy w oknie modalnym
void showCommentsModal(BuildContext context, String eventId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommentSection(eventId: eventId),
      );
    },
  );
}