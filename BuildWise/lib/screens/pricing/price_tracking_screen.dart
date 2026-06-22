import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/component.dart';
import '../../theme/app_theme.dart';

class PriceTrackingScreen extends StatefulWidget {
  const PriceTrackingScreen({super.key});

  @override
  State<PriceTrackingScreen> createState() => _PriceTrackingScreenState();
}

class _PriceTrackingScreenState extends State<PriceTrackingScreen> {
  final _supabase = Supabase.instance.client;
  List<Component> _watchlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final alerts = await _supabase.from('price_alerts').select('component_id');
      final componentIds = alerts.map((a) => a['component_id']).toList();

      if (componentIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final components = await _supabase
          .from('components')
          .select()
          .inFilter('id', componentIds);

      setState(() {
        _watchlist = components.map<Component>((c) => Component.fromJson(c)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAlert(BuildContext context) async {
    final categories = await _supabase.from('component_categories').select();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Price Alert'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final components = await _supabase
                      .from('components')
                      .select()
                      .eq('category_id', cat['id']);

                  if (!mounted) return;

                  showDialog(
                    context: context,
                    builder: (context) => _SelectComponentDialog(
                      components: components.map((c) => Component.fromJson(c)).toList(),
                      onSelected: _createAlert,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, color: AppTheme.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(cat['name'], textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _createAlert(Component component) async {
    Navigator.pop(context);

    final targetPrice = await showDialog<double>(
      context: context,
      builder: (context) => _SetTargetPriceDialog(currentPrice: component.price),
    );

    if (targetPrice == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('price_alerts').insert({
      'user_id': userId,
      'component_id': component.id,
      'target_price': targetPrice,
    });

    await _loadWatchlist();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Price alert created!'), backgroundColor: AppTheme.success),
    );
  }

  Future<void> _removeAlert(String componentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('price_alerts')
        .delete()
        .eq('user_id', userId)
        .eq('component_id', componentId);

    await _loadWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price Tracking')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _watchlist.isEmpty
              ? _buildEmptyState()
              : _buildWatchlist(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAlert(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.price_check_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No price alerts yet', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text('Add alerts to get notified when prices drop!', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildWatchlist() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _watchlist.length,
      itemBuilder: (context, index) {
        return _buildPriceCard(_watchlist[index]);
      },
    );
  }

  Widget _buildPriceCard(Component component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.memory, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(component.brand, style: TextStyle(color: AppTheme.primary, fontSize: 11)),
                      ),
                      const SizedBox(height: 4),
                      Text(component.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${component.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    Text('JOD', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(8)),
            child: _buildMiniChart(component),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Row(
                  children: [Icon(Icons.trending_down, color: AppTheme.success, size: 16), const SizedBox(width: 4), Text('Lowest: ${(component.price * 0.9).toStringAsFixed(2)} JOD', style: TextStyle(color: AppTheme.success, fontSize: 12))],
                ),
                const Spacer(),
                TextButton.icon(onPressed: () => _removeAlert(component.id), icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Remove'), style: TextButton.styleFrom(foregroundColor: AppTheme.error)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildMiniChart(Component component) {
    final List<FlSpot> spots = List.generate(30, (i) {
      final variation = (DateTime.now().millisecondsSinceEpoch + i * 86400000) % 100;
      final price = component.price * (1 - (variation / 1000));
      return FlSpot(i.toDouble(), price);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 29,
        minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.99,
        maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.01,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

class _SelectComponentDialog extends StatelessWidget {
  final List<Component> components;
  final Function(Component) onSelected;

  const _SelectComponentDialog({required this.components, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Component'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: components.length,
          itemBuilder: (context, index) {
            final c = components[index];
            return ListTile(
              title: Text(c.name),
              subtitle: Text(c.brand),
              trailing: Text('${c.price.toStringAsFixed(2)} JOD', style: TextStyle(color: AppTheme.primary)),
              onTap: () => onSelected(c),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

class _SetTargetPriceDialog extends StatefulWidget {
  final double currentPrice;

  const _SetTargetPriceDialog({required this.currentPrice});

  @override
  State<_SetTargetPriceDialog> createState() => _SetTargetPriceDialogState();
}

class _SetTargetPriceDialogState extends State<_SetTargetPriceDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: (widget.currentPrice * 0.9).toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Target Price'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current price: ${widget.currentPrice.toStringAsFixed(2)} JOD', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Target Price',
              suffixText: 'JOD',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, double.tryParse(_controller.text)),
          child: const Text('Set Alert'),
        ),
      ],
    );
  }
}
