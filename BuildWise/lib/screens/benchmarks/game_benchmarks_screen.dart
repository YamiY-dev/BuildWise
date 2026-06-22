import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class GameBenchmarksScreen extends StatefulWidget {
  final Map<String, dynamic> gpuSpecs;
  final Map<String, dynamic> cpuSpecs;

  const GameBenchmarksScreen({
    super.key,
    required this.gpuSpecs,
    required this.cpuSpecs,
  });

  @override
  State<GameBenchmarksScreen> createState() => _GameBenchmarksScreenState();
}

class _GameBenchmarksScreenState extends State<GameBenchmarksScreen> {
  String _selectedResolution = '1080p';
  final List<String> _resolutions = ['1080p', '1440p', '4K'];

  final List<GameBenchmark> _games = [
    GameBenchmark(name: 'Fortnite', icon: Icons.sports_esports, baseMultiplier: 120),
    GameBenchmark(name: 'Valorant', icon: Icons.gamepad, baseMultiplier: 150),
    GameBenchmark(name: 'CS2', icon: Icons.gps_fixed, baseMultiplier: 140),
    GameBenchmark(name: 'GTA V', icon: Icons.directions_car, baseMultiplier: 80),
    GameBenchmark(name: 'Cyberpunk 2077', icon: Icons.location_city, baseMultiplier: 50),
    GameBenchmark(name: 'Minecraft', icon: Icons.grass, baseMultiplier: 300),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Benchmarks'),
        automaticallyImplyLeading: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_display),
            initialValue: _selectedResolution,
            onSelected: (value) => setState(() => _selectedResolution = value),
            itemBuilder: (context) => _resolutions.map((r) => PopupMenuItem(value: r, child: Text(r))).toList(),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final gpuPerformance = (widget.gpuSpecs['performance_score'] ?? 7) as int;
    final cpuPerformance = (widget.cpuSpecs['performance_score'] ?? 7) as int;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGameCard(_games[index], gpuPerformance, cpuPerformance, index),
            childCount: _games.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                '$_selectedResolution High Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated FPS based on component performance scores',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameBenchmark game, int gpuPerf, int cpuPerf, int index) {
    final fps = _calculateFps(game, gpuPerf, cpuPerf);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(game.icon, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildFpsIndicator(fps),
                          const SizedBox(width: 8),
                          Text(
                            _getFpsRating(fps),
                            style: TextStyle(
                              color: _getFpsColor(fps),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${fps.toInt()}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _getFpsColor(fps),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text('FPS', style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceBar(fps),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideX();
  }

  Widget _buildFpsIndicator(double fps) {
    Color color;
    if (fps >= 144) {
      color = AppTheme.success;
    } else if (fps >= 60) {
      color = AppTheme.primary;
    } else if (fps >= 30) {
      color = AppTheme.warning;
    } else {
      color = AppTheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            fps >= 144 ? 'Competitive' : fps >= 60 ? 'Playable' : fps >= 30 ? 'Low' : 'Unplayable',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(double fps) {
    final maxFps = 300.0;
    final percentage = (fps / maxFps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('30', style: TextStyle(color: Colors.grey[500], fontSize: 10))),
            Expanded(child: Center(child: Text('60', style: TextStyle(color: Colors.grey[500], fontSize: 10)))),
            Expanded(child: Center(child: Text('144', style: TextStyle(color: Colors.grey[500], fontSize: 10)))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: Text('300', style: TextStyle(color: Colors.grey[500], fontSize: 10)))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(4)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: constraints.maxWidth * percentage,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.error, AppTheme.warning, AppTheme.success, AppTheme.primary],
                        stops: [0.1, 0.2, 0.4, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  double _calculateFps(GameBenchmark game, int gpuPerf, int cpuPerf) {
    double base = game.baseMultiplier.toDouble();

    double resolutionMultiplier;
    switch (_selectedResolution) {
      case '1080p': resolutionMultiplier = 1.0; break;
      case '1440p': resolutionMultiplier = 0.65; break;
      case '4K': resolutionMultiplier = 0.35; break;
      default: resolutionMultiplier = 1.0;
    }

    final fps = (base * resolutionMultiplier * (gpuPerf / 10) + cpuPerf * 0.5);
    return fps.clamp(15, 360);
  }

  String _getFpsRating(double fps) {
    if (fps >= 144) return 'Excellent for competitive gaming';
    if (fps >= 60) return 'Smooth gameplay';
    if (fps >= 30) return 'Playable but may lag';
    return 'Not recommended';
  }

  Color _getFpsColor(double fps) {
    if (fps >= 144) return AppTheme.success;
    if (fps >= 60) return AppTheme.primary;
    if (fps >= 30) return AppTheme.warning;
    return AppTheme.error;
  }
}

class GameBenchmark {
  final String name;
  final IconData icon;
  final int baseMultiplier;

  GameBenchmark({
    required this.name,
    required this.icon,
    required this.baseMultiplier,
  });
}
