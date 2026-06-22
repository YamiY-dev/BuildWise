import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/build_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_card.dart';
import '../../widgets/compatibility_badge.dart';
import '../../widgets/selected_component_card.dart';
import '../components/component_list_screen.dart';
import 'save_build_dialog.dart';

class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  final List<String> _categories = [
    'CPU', 'GPU', 'RAM', 'Motherboard', 'SSD', 'PSU', 'Case', 'Cooler'
  ];

  final Map<String, IconData> _categoryIcons = {
    'CPU': Icons.memory,
    'GPU': Icons.videogame_asset,
    'RAM': Icons.storage,
    'Motherboard': Icons.developer_board,
    'SSD': Icons.sd_storage,
    'PSU': Icons.power,
    'Case': Icons.computer,
    'Cooler': Icons.thermostat,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuildProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build PC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BuildProvider>().clearBuild(),
          ),
        ],
      ),
      body: Consumer<BuildProvider>(
        builder: (context, buildProvider, _) {
          return Column(
            children: [
              _buildPriceHeader(buildProvider),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (buildProvider.hasIssues)
                              _buildCompatibilityWarnings(buildProvider),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = _categories[index];
                          final selected = buildProvider.selectedComponents[category];
                          final issues = buildProvider.compatibilityIssues[category] ?? [];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _buildCategoryCard(
                              context,
                              buildProvider,
                              category,
                              selected,
                              issues,
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY();
                        },
                        childCount: _categories.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
              _buildBottomActions(buildProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceHeader(BuildProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.totalPrice.toStringAsFixed(2)} JOD',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
              ],
            ),
          ),
          if (provider.selectedComponents.values.where((c) => c != null).length >= 3)
            TextButton.icon(
              onPressed: () => _showPerformanceEstimate(provider),
              icon: const Icon(Icons.analytics),
              label: const Text('Estimate'),
            ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityWarnings(BuildProvider provider) {
    final allIssues = provider.compatibilityIssues.values
        .expand((list) => list)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${allIssues.length} compatibility issue${allIssues.length > 1 ? 's' : ''} detected',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
          TextButton(
            onPressed: () => _showCompatibilityDetails(provider),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    BuildProvider provider,
    String category,
    dynamic selected,
    List issues,
  ) {
    return GestureDetector(
      onTap: () => _selectComponent(context, category),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: issues.isNotEmpty
                ? AppTheme.error.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcons[category],
                      color: _getCategoryColor(category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (selected == null)
                          Text(
                            'Tap to select',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[400],
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (issues.isNotEmpty)
                    CompatibilityBadge(count: issues.length),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (selected != null) ...[
                const SizedBox(height: 12),
                SelectedComponentCard(component: selected),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${selected.price.toStringAsFixed(2)} JOD',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => provider.removeComponent(category),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...issues.map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            issue.type == IssueType.error
                                ? Icons.error_outline
                                : Icons.warning_amber,
                            color: issue.type == IssueType.error
                                ? AppTheme.error
                                : AppTheme.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              issue.message,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: issue.type == IssueType.error
                                        ? AppTheme.error
                                        : AppTheme.warning,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'CPU': AppTheme.primary,
      'GPU': AppTheme.secondary,
      'RAM': Colors.purple,
      'Motherboard': Colors.orange,
      'SSD': Colors.cyan,
      'PSU': Colors.amber,
      'Case': Colors.blueGrey,
      'Cooler': Colors.lightBlue,
    };
    return colors[category] ?? AppTheme.primary;
  }

  Widget _buildBottomActions(BuildProvider provider) {
    final hasComponents = provider.selectedComponents.values
        .where((c) => c != null)
        .isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasComponents
                    ? () => _showPerformanceEstimate(provider)
                    : null,
                icon: const Icon(Icons.analytics),
                label: const Text('Performance'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasComponents
                    ? () => _showSaveDialog(provider)
                    : null,
                icon: const Icon(Icons.save),
                label: const Text('Save Build'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectComponent(BuildContext context, String category) async {
    final categoryData = context.read<BuildProvider>().categories
        .where((c) => c.name == category)
        .firstOrNull;

    if (categoryData != null) {
      await context.read<BuildProvider>().loadComponents(categoryData.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComponentListScreen(
            category: category,
            categoryId: categoryData.id,
          ),
        ),
      );
    }
  }

  void _showSaveDialog(BuildProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveBuildDialog(provider: provider),
    );
  }

  void _showPerformanceEstimate(BuildProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PerformanceSheet(provider: provider),
    );
  }

  void _showCompatibilityDetails(BuildProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compatibility Issues'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.compatibilityIssues.entries
                .where((e) => e.value.isNotEmpty)
                .map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ...entry.value.map((issue) => ListTile(
                              dense: true,
                              leading: Icon(
                                issue.type == IssueType.error
                                    ? Icons.error
                                    : Icons.warning,
                                color: issue.type == IssueType.error
                                    ? AppTheme.error
                                    : AppTheme.warning,
                              ),
                              title: Text(issue.message),
                            )),
                      ],
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSheet extends StatelessWidget {
  final BuildProvider provider;

  const _PerformanceSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final estimate = provider.estimatePerformance();
    final thermal = provider.estimateThermal();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Estimate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildScoreCard(
                      context,
                      'Gaming',
                      estimate.gamingScore,
                      Icons.videogame_asset,
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildScoreCard(
                      context,
                      'Productivity',
                      estimate.productivityScore,
                      Icons.work,
                      AppTheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoTile(
                  context,
                  'Bottleneck',
                  '${estimate.bottleneckPercentage.toStringAsFixed(1)}%',
                  estimate.bottleneckPercentage > 10
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
                _buildInfoTile(
                  context,
                  'Power Consumption',
                  '${estimate.estimatedPowerConsumption}W',
                  AppTheme.accent,
                ),
                _buildInfoTile(
                  context,
                  'Recommended PSU',
                  '${estimate.recommendedPsuWattage}W',
                  AppTheme.secondary,
                ),
                const Divider(height: 32),
                Text(
                  'Thermal Estimate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  context,
                  'CPU Temp (Load)',
                  '${thermal.estimatedCpuTemp.toInt()}°C',
                  thermal.estimatedCpuTemp > 75 ? AppTheme.warning : AppTheme.success,
                ),
                _buildInfoTile(
                  context,
                  'GPU Temp (Load)',
                  '${thermal.estimatedGpuTemp.toInt()}°C',
                  thermal.estimatedGpuTemp > 80 ? AppTheme.warning : AppTheme.success,
                ),
                _buildInfoTile(
                  context,
                  'Recommended Fans',
                  thermal.recommendedFans.toString(),
                  AppTheme.secondary,
                ),
                _buildInfoTile(
                  context,
                  'Airflow Quality',
                  thermal.airflowQuality,
                  AppTheme.primary,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    String title,
    int score,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              score.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
