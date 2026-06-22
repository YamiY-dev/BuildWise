import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/build_provider.dart';
import '../../models/component.dart';
import '../../theme/app_theme.dart';

class ComponentListScreen extends StatefulWidget {
  final String category;
  final int categoryId;

  const ComponentListScreen({
    super.key,
    required this.category,
    required this.categoryId,
  });

  @override
  State<ComponentListScreen> createState() => _ComponentListScreenState();
}

class _ComponentListScreenState extends State<ComponentListScreen> {
  String _sortBy = 'price';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Consumer<BuildProvider>(
        builder: (context, provider, _) {
          var components = List<Component>.from(provider.availableComponents);

          if (_searchQuery.isNotEmpty) {
            components = components.where((c) {
              return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  c.brand.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          switch (_sortBy) {
            case 'price':
              components.sort((a, b) => a.price.compareTo(b.price));
              break;
            case 'price_desc':
              components.sort((a, b) => b.price.compareTo(a.price));
              break;
            case 'performance':
              components.sort((a, b) =>
                  (b.performanceScore ?? 0).compareTo(a.performanceScore ?? 0));
              break;
          }

          return Column(
            children: [
              _buildFilters(),
              if (provider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (components.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No components found',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: components.length,
                    itemBuilder: (context, index) {
                      return _buildComponentCard(
                        context,
                        provider,
                        components[index],
                        index,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(8),
              items: const [
                DropdownMenuItem(value: 'performance', child: Text('Performance')),
                DropdownMenuItem(value: 'price', child: Text('Price (Low)')),
                DropdownMenuItem(value: 'price_desc', child: Text('Price (High)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCard(
    BuildContext context,
    BuildProvider provider,
    Component component,
    int index,
  ) {
    final isSelected = provider.selectedComponents[widget.category]?.id == component.id;
    final selectedCount = provider.selectedComponents.values.where((c) => c != null).length;

    return GestureDetector(
      onTap: () {
        provider.selectComponent(widget.category, component);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(widget.category),
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                component.brand,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (component.performanceScore != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: AppTheme.accent,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${component.performanceScore}/10',
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          component.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (component.model != null)
                          Text(
                            component.model!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: component.specs.entries.take(3).map((spec) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_formatSpecKey(spec.key)}: ${spec.value}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${component.price.toStringAsFixed(2)} JOD',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Selected',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        provider.selectComponent(widget.category, component);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Select'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 30 * index)).slideY(),
    );
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'CPU': Icons.memory,
      'GPU': Icons.videogame_asset,
      'RAM': Icons.storage,
      'Motherboard': Icons.developer_board,
      'SSD': Icons.sd_storage,
      'PSU': Icons.power,
      'Case': Icons.computer,
      'Cooler': Icons.thermostat,
    };
    return icons[category] ?? Icons.devices;
  }

  String _formatSpecKey(String key) {
    return key.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
