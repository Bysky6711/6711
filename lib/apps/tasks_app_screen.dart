import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/shared_widgets.dart';

class TasksAppScreen extends StatelessWidget {
  const TasksAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Zadania / misje', icon: Icons.extension_rounded),
        const SizedBox(height: 16),
        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Moduł misji', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Tutaj później dodasz wybór uczestników zadania, zwycięzców i nagrody w kartach mocy.', style: TextStyle(color: AppColors.white.withValues(alpha: 0.70), fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
