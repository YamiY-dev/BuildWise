import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import 'builder/build_screen.dart';
import 'builder/my_builds_screen.dart';
import 'community/community_screen.dart';
import 'ai/ai_assistant_screen.dart';
import 'pricing/price_tracking_screen.dart';
import 'challenges/challenges_screen.dart';
import 'visual/visual_builder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeDashboard(),
    const MyBuildsScreen(),
    const CommunityScreen(),
    const AIAssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'My Builds',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PC Builder Pro',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                            ).animate().fadeIn(duration: 600.ms).slideX(),
                            const SizedBox(height: 4),
                            Text(
                              'Build your dream PC',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.grey[400]),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildQuickActions(context),
                  const SizedBox(height: 30),
                  _buildFeaturesGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: 'New Build',
                icon: Icons.add_circle_outline,
                color: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuildScreen()),
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'AI Assist',
                icon: Icons.auto_awesome,
                color: AppTheme.accent,
                onTap: () {
                  context.read<AppState>().setCurrentIndex(3);
                },
              ).animate().fadeIn(delay: 200.ms).slideX(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        title: 'My Builds',
        subtitle: 'View saved builds',
        icon: Icons.folder_outlined,
        color: AppTheme.secondary,
        screen: const MyBuildsScreen(),
      ),
      _FeatureItem(
        title: 'Community',
        subtitle: 'Browse shared builds',
        icon: Icons.people_outline,
        color: Colors.purple,
        screen: const CommunityScreen(),
      ),
      _FeatureItem(
        title: 'Price Tracking',
        subtitle: 'Monitor prices',
        icon: Icons.trending_down,
        color: AppTheme.success,
        screen: const PriceTrackingScreen(),
      ),
      _FeatureItem(
        title: 'Challenges',
        subtitle: 'Compete & win',
        icon: Icons.emoji_events_outlined,
        color: AppTheme.warning,
        screen: const ChallengesScreen(),
      ),
      _FeatureItem(
        title: 'Visual Builder',
        subtitle: 'Drag & drop design',
        icon: Icons.view_in_ar_outlined,
        color: Colors.cyan,
        screen: const VisualBuilderScreen(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _buildFeatureCard(context, features[index])
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * (index + 1)))
                .slideY();
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem feature) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => feature.screen),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: feature.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature.icon, color: feature.color, size: 28),
            const SizedBox(height: 8),
            Text(
              feature.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              feature.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
