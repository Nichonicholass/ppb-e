class Note {
  final int id;
  final String text;

  const Note({required this.id, required this.text});

  Note copyWith({int? id, String? text}) {
    return Note(id: id ?? this.id, text: text ?? this.text);
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(id: json['id'] as int, text: (json['text'] as String?) ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text};
  }
}
