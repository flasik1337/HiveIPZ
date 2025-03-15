import 'package:flutter/material.dart';
import '../models/event.dart';

class EventListTile extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventListTile({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2, // napróbę zobaczymy co to jest
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(event.cena == 0 ? null : Icons.attach_money),
                    ],
                  ),
                  Text(
                    event.dateFormated(event.startDate),
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber
                    ),
                  ),

                  const SizedBox(height: 4,),

                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8,),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                event.location,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const SizedBox(width: 8),
                              // tutaj można dodać coś dodatkowego jak nam dojdzie, np ile punktów albo co
                            ],
                          ),
                        ),
                        Text(
                          event.cena == 0 ? "Wejście darmowe" : "${event.cena.toStringAsFixed(2)} zł",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: event.cena == 0 ? Colors.green.shade300 : Colors.black,
                          ),
                        ),
                      ],
                  ),
                ],
              ),
            ),
        ),
    );
  }
}
