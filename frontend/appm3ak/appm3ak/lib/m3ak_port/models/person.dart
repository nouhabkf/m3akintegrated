class Person {
  final String id;
  final String name;
  final String relation;
  final List<List<double>> embeddings; // Plusieurs embeddings pour robustesse
  final DateTime createdAt;

  Person({
    required this.id,
    required this.name,
    required this.relation,
    required this.embeddings,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'embeddings': embeddings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      relation: json['relation'] as String,
      embeddings: (json['embeddings'] as List)
          .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

