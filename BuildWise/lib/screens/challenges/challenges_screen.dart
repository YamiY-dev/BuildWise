import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/challenge.dart';
import '../../theme/app_theme.dart';
import '../builder/build_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _supabase = Supabase.instance.client;
  List<Challenge> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    try {
      final response = await _supabase
          .from('challenges')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      setState(() {
        _challenges = response.map<Challenge>((c) => Challenge.fromJson(c)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build Challenges')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challenges.isEmpty
              ? _buildEmptyState()
              : _buildChallengesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No active challenges', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text('Check back soon for new build challenges!', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildChallengesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challenges.length,
      itemBuilder: (context, index) {
        return _buildChallengeCard(_challenges[index], index);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTypeColor(challenge.challengeType).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: _getTypeColor(challenge.challengeType).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(_getTypeIcon(challenge.challengeType), size: 50, color: _getTypeColor(challenge.challengeType)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTypeColor(challenge.challengeType).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTypeLabel(challenge.challengeType),
                        style: TextStyle(color: _getTypeColor(challenge.challengeType), fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    if (challenge.endDate != null) ...[
                      Icon(Icons.timer_outlined, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(_getTimeRemaining(challenge.endDate!), style: TextStyle(color: AppTheme.warning, fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.description ?? '',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (challenge.constraints != null) ...[
                  _buildConstraints(challenge.constraints!),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _viewSubmissions(challenge),
                      icon: const Icon(Icons.leaderboard_outlined, size: 18),
                      label: const Text('Leaderboard'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _enterChallenge(challenge),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Enter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY();
  }

  Widget _buildConstraints(Map<String, dynamic> constraints) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: constraints.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getConstraintIcon(entry.key), size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text('${_formatConstraintKey(entry.key)}: ${entry.value}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _viewSubmissions(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${challenge.title} - Leaderboard'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Center(child: Text('Submissions will appear here')),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _enterChallenge(Challenge challenge) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildScreen()));
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'budget': return AppTheme.success;
      case 'quiet': return Colors.blueGrey;
      case 'itx': return Colors.cyan;
      case 'performance': return AppTheme.primary;
      default: return AppTheme.accent;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'budget': return Icons.savings;
      case 'quiet': return Icons.volume_off;
      case 'itx': return Icons.widgets_outlined;
      case 'performance': return Icons.speed;
      default: return Icons.emoji_events;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'budget': return 'Budget Build';
      case 'quiet': return 'Silent Build';
      case 'itx': return 'ITX Build';
      case 'performance': return 'Performance';
      default: return 'Challenge';
    }
  }

  String _getTimeRemaining(DateTime endDate) {
    final remaining = endDate.difference(DateTime.now());
    if (remaining.isNegative) return 'Ended';
    if (remaining.inDays > 0) return '${remaining.inDays}d left';
    if (remaining.inHours > 0) return '${remaining.inHours}h left';
    return '${remaining.inMinutes}m left';
  }

  IconData _getConstraintIcon(String key) {
    switch (key) {
      case 'max_budget': return Icons.attach_money;
      case 'form_factor': return Icons.dashboard;
      case 'noise_level': return Icons.volume_down;
      default: return Icons.rule;
    }
  }

  String _formatConstraintKey(String key) {
    return key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
