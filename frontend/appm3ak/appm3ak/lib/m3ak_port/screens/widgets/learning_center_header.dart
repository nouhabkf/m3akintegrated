import 'package:flutter/material.dart';

class LearningCenterHeader extends StatelessWidget {
  const LearningCenterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Learning Center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          Icon(
            Icons.school,
            size: 32,
            color: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }
}