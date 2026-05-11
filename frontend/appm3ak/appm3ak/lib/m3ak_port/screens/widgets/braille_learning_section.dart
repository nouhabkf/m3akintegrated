import 'package:flutter/material.dart';
import 'package:appm3ak/m3ak_port/models/exercise_response.dart';
import 'package:appm3ak/m3ak_port/screens/widgets/exercise_card.dart';

class BrailleLearningSection extends StatelessWidget {
  final ExerciseResponse? currentExercise;
  final bool isLoading;
  final String? feedback;
  final Function(String) onExerciseSubmit;

  const BrailleLearningSection({
    super.key,
    required this.currentExercise,
    required this.isLoading,
    required this.feedback,
    required this.onExerciseSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_on,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Apprendre le Braille',  // ✅ Correction typo (était 'Apprendre')
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '3/10 Terminées',  // ✅ Correction typo (était 'Terminées')
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Contenu principal
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
          )
        else if (currentExercise != null)
          ExerciseCard(
            exercise: currentExercise!,
            feedback: feedback,
            onExerciseSubmit: onExerciseSubmit,
          )
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Aucun exercice disponible',  // ✅ Correction typo (était 'Aucun')
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}