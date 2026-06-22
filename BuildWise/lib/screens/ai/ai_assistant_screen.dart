import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/component.dart';
import '../../providers/build_provider.dart';
import '../builder/build_screen.dart';

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  final List<String> _quickPrompts = [
    'I have 700 JD for gaming',
    'Best workstation under 1000 JD',
    'Budget streaming PC build',
    'High-end gaming setup',
    'DDR4 vs DDR5 for Ryzen',
    'Best value GPU right now',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : _buildChatView(),
          ),
          _buildQuickPrompts(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 60,
                color: AppTheme.primary,
              ),
            ).animate().scale(duration: 600.ms),
            const SizedBox(height: 24),
            Text(
              'PC Build Assistant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Tell me your budget and requirements,\nI\'ll suggest the perfect build for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Gaming PC under 500 JD'),
                _buildSuggestionChip('Workstation for video editing'),
                _buildSuggestionChip('Budget build around 300 JD'),
              ],
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _sendMessage(text),
      backgroundColor: AppTheme.darkCard,
      side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.darkCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: message.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analyzing...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    )
                  : message.isUser
                      ? Text(message.content)
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyMedium,
                            strong: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
            ),
          ),
          if (message.isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, size: 20),
            ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildQuickPrompts() {
    if (_messages.isNotEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              _quickPrompts[index],
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _sendMessage(_quickPrompts[index]),
            backgroundColor: AppTheme.darkCard,
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about PC builds...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isTyping
                        ? null
                        : () => _sendMessage(_messageController.text),
                  ),
                ),
                onSubmitted: _isTyping ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(Message(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(Message(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _generateBuildSuggestion(text);

      setState(() {
        _messages.removeLast();
        _messages.add(Message(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(Message(
          content: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  Future<String> _generateBuildSuggestion(String query) async {
    final supabase = Supabase.instance.client;

    final budgetRegex = RegExp(r'(\d+)\s*(JD|jd|jod|JOD)');
    final budgetMatch = budgetRegex.firstMatch(query);
    double? budget = budgetMatch != null ? double.tryParse(budgetMatch.group(1)!) : null;

    final isGaming = query.toLowerCase().contains('gaming');
    final isWorkstation = query.toLowerCase().contains('workstation') ||
        query.toLowerCase().contains('editing') ||
        query.toLowerCase().contains('programming');
    final isBudget = query.toLowerCase().contains('budget') ||
        query.toLowerCase().contains('cheap');

    var cpuQuery = supabase.from('components').select().eq('category_id', 1);
    var gpuQuery = supabase.from('components').select().eq('category_id', 2);

    final cpus = (await cpuQuery).map((j) => Component.fromJson(j)).toList();
    final gpus = (await gpuQuery).map((j) => Component.fromJson(j)).toList();

    final StringBuilder = StringBuffer();
    StringBuilder.writeln('Based on your request, here\'s my recommendation:\n');

    if (budget != null && budget < 300) {
      StringBuilder.writeln('### Budget Constraints\n');
      StringBuilder.writeln(
          'With a budget of **$budget JOD**, you\'re looking at an entry-level build. '
          'I recommend focusing on upgradeable components.\n');
    }

    if (isGaming) {
      StringBuilder.writeln('### Gaming Build Focus\n');
      if (budget != null && budget >= 500) {
        final gpu = gpus.where((g) => g.price <= budget! * 0.35).reduceOrNull((a, b) =>
                (a.performanceScore ?? 0) > (b.performanceScore ?? 0) ? a : b) ??
            gpus.first;

        final remainingBudget = budget - gpu.price;
        final cpu = cpus.where((c) => c.price <= remainingBudget * 0.2).reduceOrNull((a, b) =>
                (a.performanceScore ?? 0) > (b.performanceScore ?? 0) ? a : b) ??
            cpus.first;

        StringBuilder.writeln('• **GPU**: ${gpu.brand} ${gpu.name} - ${gpu.price.toStringAsFixed(2)} JOD');
        if (gpu.specs['vram'] != null) {
          StringBuilder.writeln('  - ${gpu.specs['vram']}GB VRAM');
        }
        StringBuilder.writeln();

        StringBuilder.writeln('• **CPU**: ${cpu.brand} ${cpu.name} - ${cpu.price.toStringAsFixed(2)} JOD');
        StringBuilder.writeln('  - Socket: ${cpu.specs['socket']}');
        StringBuilder.writeln();

        StringBuilder.writeln('\n*This configuration should handle ${gpu.performanceScore! >= 8 ? "1080p/1440p" : "1080p"} gaming well!*');
      }
    } else if (isWorkstation) {
      StringBuilder.writeln('### Workstation Build Focus\n');
      if (budget != null && budget >= 700) {
        final cpu = cpus.where((c) => c.price <= budget! * 0.25).reduceOrNull((a, b) =>
                c.threads > b.threads ? a : b) ??
            cpus.first;

        StringBuilder.writeln('• **CPU**: ${cpu.brand} ${cpu.name} - ${cpu.price.toStringAsFixed(2)} JOD');
        StringBuilder.writeln('  - ${cpu.specs['cores']} cores / ${cpu.specs['threads']} threads');
        StringBuilder.writeln('  - Great for multi-threaded workloads');
        StringBuilder.writeln();
      }
    }

    if (isBudget || (budget != null && budget < 400)) {
      StringBuilder.writeln('### Money-Saving Tips\n');
      StringBuilder.writeln('- Consider a B-series motherboard instead of high-end chipsets');
      StringBuilder.writeln('- DDR4 RAM can save you money and performs similarly to DDR5 in gaming');
      StringBuilder.writeln('- Look for M.2 SSD deals - prices have dropped significantly');
      StringBuilder.writeln('- A quality 650W PSU is often enough for mid-range builds\n');
    }

    StringBuilder.writeln('---\n');
    StringBuilder.writeln('*Would you like me to refine this recommendation or generate a complete build?*');

    return StringBuilder.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
