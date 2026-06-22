import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/build.dart';
import '../../theme/app_theme.dart';
import '../builder/build_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Build> _builds = [];
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      final buildsResponse = await _supabase
          .from('builds')
          .select()
          .eq('user_id', widget.userId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final followResponse = await _supabase
            .from('user_follows')
            .select()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.userId)
            .maybeSingle();
        _isFollowing = followResponse != null;
      }

      setState(() {
        _profile = profileResponse;
        _builds = buildsResponse.map<Build>((b) => Build.fromJson(b)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (_isFollowing) {
        await _supabase
            .from('user_follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', widget.userId);
      } else {
        await _supabase.from('user_follows').insert({
          'follower_id': userId,
          'following_id': widget.userId,
        });
      }
      setState(() => _isFollowing = !_isFollowing);
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
      appBar: AppBar(title: Text(_profile?['username'] ?? 'Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profile not found'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeader(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_profile?['bio'] != null && _profile!['bio'].toString().isNotEmpty) ...[
                                Text('Bio', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(_profile!['bio'], style: TextStyle(color: Colors.grey[400])),
                                const SizedBox(height: 24),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Builds', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('${_builds.length} builds', style: TextStyle(color: Colors.grey[400])),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final build = _builds[index];
                            return _buildBuildTile(build);
                          },
                          childCount: _builds.length,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final username = _profile?['username'] as String? ?? 'Anonymous';
    final currentUserId = _supabase.auth.currentUser?.id;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.darkSurface),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(username, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (currentUserId != null && currentUserId != widget.userId)
            ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? AppTheme.darkCard : AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(_isFollowing ? 'Following' : 'Follow'),
            ),
        ],
      ),
    );
  }

  Widget _buildBuildTile(Build build) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BuildDetailScreen(build: build)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getTypeColor(build.buildType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.computer, color: _getTypeColor(build.buildType)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(build.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeColor(build.buildType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          BuildType.getDisplayName(build.buildType),
                          style: TextStyle(color: _getTypeColor(build.buildType), fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.favorite, size: 14, color: Colors.pink[300]),
                      const SizedBox(width: 4),
                      Text('${build.likesCount}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Text('${build.totalPrice.toStringAsFixed(0)} JOD', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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
