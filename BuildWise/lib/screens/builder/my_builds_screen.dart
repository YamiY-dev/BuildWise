import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/build.dart';
import '../../theme/app_theme.dart';
import 'build_detail_screen.dart';

class MyBuildsScreen extends StatefulWidget {
  const MyBuildsScreen({super.key});

  @override
  State<MyBuildsScreen> createState() => _MyBuildsScreenState();
}

class _MyBuildsScreenState extends State<MyBuildsScreen> {
  final _supabase = Supabase.instance.client;
  List<Build> _builds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuilds();
  }

  Future<void> _loadBuilds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('builds')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _builds = response.map<Build>((b) => Build.fromJson(b)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBuild(String buildId) async {
    try {
      await _supabase.from('builds').delete().eq('id', buildId);
      await _loadBuilds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting build: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Builds'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _builds.isEmpty
              ? _buildEmptyState()
              : _buildBuildsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_outlined,
            size: 80,
            color: Colors.grey[600],
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'No builds yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your dream PC',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildsList() {
    return RefreshIndicator(
      onRefresh: _loadBuilds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _builds.length,
        itemBuilder: (context, index) {
          final build = _builds[index];
          return _buildCard(build, index);
        },
      ),
    );
  }

  Widget _buildCard(Build build, int index) {
    final componentCount = build.components.length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuildDetailScreen(build: build),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
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
                      color: _getTypeColor(build.buildType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(build.buildType),
                      color: _getTypeColor(build.buildType),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          build.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(build.buildType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                BuildType.getDisplayName(build.buildType),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getTypeColor(build.buildType),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$componentCount components',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                        '${build.totalPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'JOD',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.public, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    build.isPublic ? 'Public' : 'Private',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  if (build.isPublic) ...[
                    Icon(Icons.favorite, size: 14, color: Colors.pink[300]),
                    const SizedBox(width: 4),
                    Text(
                      '${build.likesCount}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const Spacer(),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/build-detail',
                          arguments: {'build': build},
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY();
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case BuildType.gaming:
        return Icons.videogame_asset;
      case BuildType.workstation:
        return Icons.work;
      case BuildType.budget:
        return Icons.savings;
      default:
        return Icons.build;
    }
  }
}
