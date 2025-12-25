import 'package:flutter/material.dart';
import '../widgets/ai_insights_card.dart';
import '../theme/medical_icons.dart';

class AIInsightsScreen extends StatelessWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Health Insights',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main AI Insights Card (full version)
            const AIInsightsCard(isCompact: false),
            
            const SizedBox(height: 24),
            
            // Health Summary Cards
            _buildHealthSummarySection(context),
            
            const SizedBox(height: 24),
            
            // Export Options
            _buildExportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummarySection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Data Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Glucose',
                'Latest readings',
                MedicalIcons.glucose(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Medications',
                'Adherence tracking',
                MedicalIcons.medication(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Activity',
                'Physical exercise',
                MedicalIcons.activity(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Nutrition',
                'Meal tracking',
                MedicalIcons.nutrition(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String subtitle, Widget icon) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share with Healthcare Provider',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Card(
          child: ListTile(
            leading: MedicalIcons.export(),
            title: const Text('Export Health Report'),
            subtitle: const Text('Generate comprehensive report for your doctor'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () {
              // TODO: Implement export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export functionality coming soon!'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}