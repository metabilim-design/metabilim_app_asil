import 'package:flutter/material.dart';
import 'package:metabilim/pages/coach/homework_flow/select_student_page.dart';

class HomeworkStartPage extends StatelessWidget {
  const HomeworkStartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödev Programı Oluştur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOptionCard(
                context: context,
                icon: Icons.add_circle_outline,
                title: 'Sıfırdan Program Oluştur',
                subtitle: 'Öğrenciniz için yeni bir haftalık veya aylık program tasarlayın.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SelectStudentPage(),
                  ));
                },
              ),
              const SizedBox(height: 20),
              _buildOptionCard(
                context: context,
                icon: Icons.history,
                title: 'Önceki Programdan Devam Et',
                subtitle: 'Mevcut bir programı kopyalayın veya düzenleyerek devam edin.',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bu özellik yakında eklenecektir.'),
                  ));
                },
                enabled: false, // Şimdilik devre dışı
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: enabled ? colorScheme.surfaceVariant.withOpacity(0.5) : colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: enabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}