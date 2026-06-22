import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/build.dart';
import '../../models/component.dart';
import '../../providers/build_provider.dart';
import '../../theme/app_theme.dart';
import '../benchmarks/game_benchmarks_screen.dart';

class BuildDetailScreen extends StatelessWidget {
  final Build build;

  const BuildDetailScreen({super.key, required this.build});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(build.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(
              'Check out my PC build: ${build.name} - ${build.totalPrice.toStringAsFixed(2)} JOD',
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildComponentList(context),
                  const Divider(height: 40),
                  if (build.description != null && build.description!.isNotEmpty)
                    _buildDescription(context, build.description!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${build.totalPrice.toStringAsFixed(2)} JOD',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor(build.buildType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  BuildType.getDisplayName(build.buildType),
                  style: TextStyle(
                    color: _getTypeColor(build.buildType),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.public, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    build.isPublic ? 'Public' : 'Private',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildComponentList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Components',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...build.components.entries.map((entry) {
          final component = Component.fromJson(entry.value);
          return _buildComponentCard(context, entry.key, component);
        }),
      ],
    );
  }

  Widget _buildComponentCard(BuildContext context, String category, Component component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: _getCategoryColor(category),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.brand,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      component.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '${component.price.toStringAsFixed(2)} JOD',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (component.specs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: component.specs.entries.take(4).map((spec) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_formatSpecKey(spec.key)}: ${spec.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[300],
                        ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildDescription(BuildContext context, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _formatSpecKey(String key) {
    return key.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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

  Color _getTypeColor(String type) {
    switch (type) {
      case BuildType.gaming:
        return AppTheme.primary;
      case BuildType.workstation:
        return AppTheme.secondary;
      case BuildType.budget:
        return AppTheme.warning;
      default:
        return AppTheme.accent;
    }
  }
}
