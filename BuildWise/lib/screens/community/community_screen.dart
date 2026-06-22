import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/build.dart';
import '../../theme/app_theme.dart';
import '../builder/build_detail_screen.dart';
import 'user_profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _builds = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadBuilds();
  }

  Future<void> _loadBuilds() async {
    setState(() => _isLoading = true);

    try {
      var query = _supabase.from('builds').select('''
        *, profiles:builds_user_id_fkey(username, avatar_url)
      ''');

      if (_filterType != 'all') {
        query.eq('build_type', _filterType);
      }

      final response = await query
          .eq('is_public', true)
          .order('likes_count', ascending: false)
          .limit(50);

      setState(() {
        _builds = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(String buildId, bool isLiked) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (isLiked) {
        await _supabase
            .from('build_likes')
            .delete()
            .eq('build_id', buildId)
            .eq('user_id', userId);
        await _supabase.rpc('decrement_likes', args: {'build_id': buildId});
      } else {
        await _supabase.from('build_likes').insert({
          'build_id': buildId,
          'user_id': userId,
        });
        await _supabase.rpc('increment_likes', args: {'build_id': buildId});
      }
      await _loadBuilds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Builds'),
      ),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _builds.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    final filters = {'all': 'All', 'gaming': 'Gaming', 'workstation': 'Workstation', 'budget': 'Budget'};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = _filterType == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterType = entry.key);
                  _loadBuilds();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No community builds yet', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text('Share your build to inspire others!', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildList() {
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

  Widget _buildCard(Map<String, dynamic> build, int index) {
    final profile = build['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] as String? ?? 'Anonymous';
    final avatarUrl = profile?['avatar_url'] as String?;
    final buildModel = Build.fromJson(build);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuildDetailScreen(build: buildModel),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.computer, size: 60, color: Colors.grey[700]),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTypeColor(build['build_type'] as String).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        BuildType.getDisplayName(build['build_type'] ?? 'custom'),
                        style: TextStyle(
                          color: _getTypeColor(build['build_type'] as String),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(userId: build['user_id']),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.darkSurface,
                              child: avatarUrl != null
                                  ? const Icon(Icons.person, size: 16)
                                  : Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${build['total_price']} JOD',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    build['name'] ?? 'Untitled Build',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.hardware, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${(build['components'] as Map).length} components',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.favorite_border, color: Colors.pink[300]),
                        onPressed: () => _toggleLike(build['id'], false),
                      ),
                      Text(
                        '${build['likes_count'] ?? 0}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'gaming': return AppTheme.primary;
      case 'workstation': return AppTheme.secondary;
      case 'budget': return AppTheme.warning;
      default: return AppTheme.accent;
    }
  }
}
