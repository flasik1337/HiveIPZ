class Event {
  final String id;
  final String name;
  final String location;
  final String description;
  final String type;
  final DateTime startDate;
  final int maxParticipants;
  final int registeredParticipants;
  final String imagePath;
  final int? userId;
  final double cena;

  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.type,
    required this.startDate,
    required this.maxParticipants,
    required this.registeredParticipants,
    required this.imagePath,
    this.userId,
    required this.cena,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      maxParticipants: json['max_participants'] as int,
      registeredParticipants: json['registered_participants'] as int,
      imagePath: json['image'] as String,
      userId: json['user_id'] != null ? json['user_id'] as int : null,
      cena: json['cena'] != null
          ? double.tryParse(json['cena'].toString()) ?? 0.0
          : 0.0,
    );
  }

  Event copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    String? type,
    DateTime? startDate,
    int? maxParticipants,
    int? registeredParticipants,
    String? imagePath,
    int? userId,
    double? cena,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.location,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredParticipants:
          registeredParticipants ?? this.registeredParticipants,
      imagePath: imagePath ?? this.imagePath,
      userId: userId ?? this.userId,
      cena: cena ?? this.cena,
    );
  }

  String dateFormated(DateTime startDate) {
    List<String> months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia'
    ];
    String result = '${startDate.day} ${months[startDate.month - 1]} ${startDate.year}';

    return (result);
  }


}
