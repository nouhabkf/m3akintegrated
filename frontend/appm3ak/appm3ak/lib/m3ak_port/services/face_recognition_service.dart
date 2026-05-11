import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appm3ak/m3ak_port/models/person.dart';
import 'package:appm3ak/m3ak_port/models/face_detection_result.dart';
import 'package:appm3ak/m3ak_port/models/face_test_result.dart';

class FaceRecognitionService {
  static const String _facesKey = 'm3ak_faces_database';

  /// Normalise un embedding (vecteur unitaire)
  List<double> _normalizeEmbedding(List<double> embedding) {
    double norm = 0.0;
    for (final value in embedding) {
      norm += value * value;
    }
    norm = sqrt(norm);
    
    if (norm == 0.0) return embedding;
    
    return embedding.map((v) => v / norm).toList();
  }

  /// Calcule la distance cosinus entre deux embeddings (normalisés)
  double _cosineDistance(List<double> a, List<double> b) {
    if (a.length != b.length) return 1.0;

    // Normaliser les embeddings pour une meilleure comparaison
    final normalizedA = _normalizeEmbedding(a);
    final normalizedB = _normalizeEmbedding(b);

    double dotProduct = 0.0;
    for (int i = 0; i < normalizedA.length; i++) {
      dotProduct += normalizedA[i] * normalizedB[i];
    }

    // Distance cosinus = 1 - similarité cosinus
    // Plus la valeur est proche de 0, plus les visages sont similaires
    return 1.0 - dotProduct.clamp(-1.0, 1.0);
  }

  /// Calcule la moyenne des embeddings d'une personne (plus robuste)
  List<double> _averageEmbeddings(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];
    
    final int dim = embeddings.first.length;
    final List<double> average = List.filled(dim, 0.0);
    
    for (final embedding in embeddings) {
      for (int i = 0; i < dim && i < embedding.length; i++) {
        average[i] += embedding[i];
      }
    }
    
    for (int i = 0; i < dim; i++) {
      average[i] /= embeddings.length;
    }
    
    return average;
  }

  /// Trouve la meilleure correspondance pour un embedding
  FaceRecognitionResult? _findBestMatch(
    List<double> queryEmbedding,
    List<Person> persons,
    double threshold,
  ) {
    // Normaliser l'embedding de requête
    final normalizedQuery = _normalizeEmbedding(queryEmbedding);
    
    double bestDistance = double.infinity;
    Person? bestPerson;

    for (final person in persons) {
      // Utiliser la moyenne des embeddings de la personne (plus robuste)
      final avgEmbedding = _averageEmbeddings(person.embeddings);
      if (avgEmbedding.isEmpty) continue;
      
      final normalizedAvg = _normalizeEmbedding(avgEmbedding);
      final distance = _cosineDistance(normalizedQuery, normalizedAvg);
      
      // Aussi comparer avec chaque embedding individuel (prendre le meilleur)
      double minDistance = distance;
      for (final embedding in person.embeddings) {
        final normalized = _normalizeEmbedding(embedding);
        final dist = _cosineDistance(normalizedQuery, normalized);
        if (dist < minDistance) {
          minDistance = dist;
        }
      }
      
      if (minDistance < bestDistance) {
        bestDistance = minDistance;
        bestPerson = person;
      }
    }

    // Seuil adaptatif : être TRÈS permissif pour améliorer la reconnaissance
    double adaptiveThreshold = threshold;
    if (persons.length == 1) {
      adaptiveThreshold = 0.98; // Très permissif pour une seule personne
    } else if (persons.length <= 3) {
      adaptiveThreshold = 0.90;
    } else {
      adaptiveThreshold = 0.85; // Plus permissif même avec plusieurs personnes
    }

    if (bestDistance < adaptiveThreshold && bestPerson != null) {
      return FaceRecognitionResult(
        recognized: true,
        personName: bestPerson.name,
        relation: bestPerson.relation,
        confidence: 1.0 - bestDistance, // Convertir distance en confiance
      );
    }

    return null;
  }

  /// Ajoute une personne à la base de données
  Future<void> addPerson(
    String name,
    String relation,
    List<List<double>> embeddings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final persons = await getAllPersons();

    final newPerson = Person(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relation: relation,
      embeddings: embeddings,
      createdAt: DateTime.now(),
    );

    persons.add(newPerson);

    final jsonList = persons.map((p) => p.toJson()).toList();
    await prefs.setString(_facesKey, jsonEncode(jsonList));
  }

  /// Récupère toutes les personnes
  Future<List<Person>> getAllPersons() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_facesKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Person.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Reconnaît un visage à partir d'un embedding
  Future<FaceRecognitionResult?> recognizeFace(
    List<double> embedding, {
    double threshold = 0.6,
  }) async {
    final persons = await getAllPersons();
    if (persons.isEmpty) return null;

    return _findBestMatch(embedding, persons, threshold);
  }

  /// Teste la reconnaissance avec des statistiques détaillées
  Future<FaceTestResult> testRecognition(
    List<double> embedding, {
    double threshold = 0.6,
  }) async {
    final persons = await getAllPersons();
    final allMatches = <PersonMatch>[];

    if (persons.isEmpty) {
      return FaceTestResult(
        recognized: false,
        confidence: 0.0,
        distance: 1.0,
        threshold: threshold,
        faceDetected: true,
        embeddingGenerated: true,
        totalPersons: 0,
        totalEmbeddings: 0,
        allMatches: [],
      );
    }

    // Normaliser l'embedding de requête
    final normalizedQuery = _normalizeEmbedding(embedding);
    
    double bestDistance = double.infinity;
    Person? bestPerson;

    for (final person in persons) {
      // Utiliser la moyenne des embeddings
      final avgEmbedding = _averageEmbeddings(person.embeddings);
      if (avgEmbedding.isNotEmpty) {
        final normalizedAvg = _normalizeEmbedding(avgEmbedding);
        final distance = _cosineDistance(normalizedQuery, normalizedAvg);
        
        allMatches.add(PersonMatch(
          personName: person.name,
          relation: person.relation,
          distance: distance,
          confidence: 1.0 - distance,
        ));

        if (distance < bestDistance) {
          bestDistance = distance;
          bestPerson = person;
        }
      }
      
      // Aussi comparer avec chaque embedding individuel
      for (final personEmbedding in person.embeddings) {
        final normalized = _normalizeEmbedding(personEmbedding);
        final distance = _cosineDistance(normalizedQuery, normalized);
        
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPerson = person;
        }
      }
    }

    // Trier par distance (meilleur match en premier) et dédupliquer
    allMatches.sort((a, b) => a.distance.compareTo(b.distance));
    
    // Garder seulement le meilleur match par personne
    final Map<String, PersonMatch> bestPerPerson = {};
    for (final match in allMatches) {
      final key = '${match.personName}_${match.relation}';
      if (!bestPerPerson.containsKey(key) || match.distance < bestPerPerson[key]!.distance) {
        bestPerPerson[key] = match;
      }
    }
    allMatches.clear();
    allMatches.addAll(bestPerPerson.values);
    allMatches.sort((a, b) => a.distance.compareTo(b.distance));

    // Seuil adaptatif pour le test aussi
    double adaptiveThreshold = threshold;
    if (persons.length == 1) {
      adaptiveThreshold = 0.98;
    } else if (persons.length <= 3) {
      adaptiveThreshold = 0.90;
    } else {
      adaptiveThreshold = 0.85;
    }
    
    final recognized = bestDistance < adaptiveThreshold && bestPerson != null;

    return FaceTestResult(
      recognized: recognized,
      personName: bestPerson?.name,
      relation: bestPerson?.relation,
      confidence: recognized ? (1.0 - bestDistance) : 0.0,
      distance: bestDistance,
      threshold: threshold,
      faceDetected: true,
      embeddingGenerated: true,
      totalPersons: persons.length,
      totalEmbeddings: persons.fold(0, (sum, p) => sum + p.embeddings.length),
      allMatches: allMatches,
    );
  }

  /// Supprime une personne par son nom
  Future<bool> deletePerson(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final persons = await getAllPersons();

    persons.removeWhere((p) => p.name.toLowerCase() == name.toLowerCase());

    final jsonList = persons.map((p) => p.toJson()).toList();
    await prefs.setString(_facesKey, jsonEncode(jsonList));

    return true;
  }

  /// Vérifie si une personne existe
  Future<bool> personExists(String name) async {
    final persons = await getAllPersons();
    return persons.any((p) => p.name.toLowerCase() == name.toLowerCase());
  }

  /// Compte le nombre de personnes
  Future<int> getPersonCount() async {
    final persons = await getAllPersons();
    return persons.length;
  }
}

