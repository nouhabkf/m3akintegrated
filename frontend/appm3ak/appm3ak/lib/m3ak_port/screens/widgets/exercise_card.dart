import 'package:flutter/material.dart';
import 'package:appm3ak/m3ak_port/models/exercise_response.dart';

class ExerciseCard extends StatefulWidget {
  final ExerciseResponse exercise;
  final String? feedback;
  final Function(String) onExerciseSubmit;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.feedback,
    required this.onExerciseSubmit,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void didUpdateWidget(ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Réinitialiser le champ quand le feedback est null (nouvel exercice)
    if (widget.feedback == null && oldWidget.feedback != null) {
      _controller.clear();
      _isButtonEnabled = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateButtonState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Text(
              widget.exercise.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 12),

            // Motif Braille avec police spéciale
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motif Braille:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SelectableText(
                      widget.exercise.braillePattern,
                      style: const TextStyle(
                        fontSize: 56,
                        fontFamily: 'NotoSansSymbols2',  // Police Braille
                        letterSpacing: 8,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Appuyez longuement pour copier',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Difficulté
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDifficultyColor(widget.exercise.difficulty),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Difficulté: ${_getDifficultyText(widget.exercise.difficulty)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Champ de texte
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Votre réponse',
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
                hintText: 'Tapez votre réponse ici...',
              ),
              onChanged: (value) {
                // Le listener s'occupe déjà de mettre à jour l'état
              },
              onSubmitted: (_) {
                if (_isButtonEnabled) {
                  _submitAnswer();
                }
              },
            ),

            const SizedBox(height: 16),

            // Feedback
            if (widget.feedback != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (widget.feedback!.toLowerCase().contains('bravo') ||
                      widget.feedback!.toLowerCase().contains('✅'))
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      (widget.feedback!.toLowerCase().contains('bravo') ||
                          widget.feedback!.toLowerCase().contains('✅'))
                          ? Icons.check_circle
                          : Icons.info,
                      color: (widget.feedback!.toLowerCase().contains('bravo') ||
                          widget.feedback!.toLowerCase().contains('✅'))
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.feedback!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bouton Valider
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Valider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitAnswer() {
    final answer = _controller.text.trim();
    if (answer.isNotEmpty) {
      widget.onExerciseSubmit(answer);
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.blue;
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1: return 'Facile';
      case 2: return 'Moyen';
      case 3: return 'Difficile';
      default: return 'Niveau $difficulty';
    }
  }
}