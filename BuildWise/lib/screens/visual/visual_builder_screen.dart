import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class VisualBuilderScreen extends StatefulWidget {
  const VisualBuilderScreen({super.key});

  @override
  State<VisualBuilderScreen> createState() => _VisualBuilderScreenState();
}

class _VisualBuilderScreenState extends State<VisualBuilderScreen> {
  final List<_ComponentSlot> _slots = [
    _ComponentSlot(name: 'CPU', icon: Icons.memory, position: Offset(150, 120)),
    _ComponentSlot(name: 'CPU Cooler', icon: Icons.thermostat, position: Offset(150, 80)),
    _ComponentSlot(name: 'GPU', icon: Icons.videogame_asset, position: Offset(100, 250)),
    _ComponentSlot(name: 'RAM', icon: Icons.storage, position: Offset(200, 140)),
    _ComponentSlot(name: 'Motherboard', icon: Icons.developer_board, position: Offset(150, 180)),
    _ComponentSlot(name: 'SSD', icon: Icons.sd_storage, position: Offset(250, 180)),
    _ComponentSlot(name: 'PSU', icon: Icons.power, position: Offset(150, 350)),
    _ComponentSlot(name: 'Case', icon: Icons.computer, position: Offset(150, 280)),
  ];

  _ComponentSlot? _selectedSlot;
  String? _draggingComponent;

  final List<String> _availableComponents = [
    'CPU', 'GPU', 'RAM', 'Motherboard', 'SSD', 'PSU', 'Case', 'Cooler'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visual Builder')),
      body: Column(
        children: [
          Expanded(flex: 2, child: _buildCaseView()),
          _buildDraggableComponents(),
        ],
      ),
    );
  }

  Widget _buildCaseView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              color: AppTheme.darkCard,
              child: CustomPaint(
                size: const Size(double.infinity, 300),
                painter: _CasePainter(),
              ),
            ),
            ..._slots.map((slot) => _buildSlot(slot)),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildSlot(_ComponentSlot slot) {
    return Positioned(
      left: slot.position.dx - 30,
      top: slot.position.dy - 30,
      child: DragTarget<String>(
        onWillAccept: (data) => true,
        onAccept: (componentType) {
          setState(() {
            slot.component = componentType;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final isFilled = slot.component != null;

          return GestureDetector(
            onTap: () => _showSlotOptions(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isFilled
                    ? AppTheme.primary.withOpacity(0.2)
                    : isHovering
                        ? AppTheme.primary.withOpacity(0.3)
                        : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedSlot == slot
                      ? AppTheme.primary
                      : isHovering
                          ? AppTheme.primary
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    slot.icon,
                    color: isFilled ? AppTheme.primary : Colors.grey[400],
                    size: 24,
                  ),
                  if (isFilled) ...[
                    const SizedBox(height: 2),
                    Text(slot.component![0], style: const TextStyle(fontSize: 8)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraggableComponents() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.darkSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drag components to the case', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[400])),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableComponents.map((component) {
              return Draggable<String>(
                data: component,
                feedback: _buildDraggableComponent(component, isDragging: true),
                childWhenDragging: Opacity(opacity: 0.5, child: _buildDraggableComponent(component)),
                child: _buildDraggableComponent(component),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableComponent(String name, {bool isDragging = false}) {
    final icon = _getComponentIcon(name);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDragging ? AppTheme.primary.withOpacity(0.2) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDragging ? AppTheme.primary : Colors.transparent),
      ),
      transform: isDragging ? Matrix4.translationValues(50, -20, 0) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isDragging ? AppTheme.primary : Colors.grey[400]),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(color: isDragging ? AppTheme.primary : null)),
        ],
      ),
    );
  }

  void _showSlotOptions(_ComponentSlot slot) {
    setState(() => _selectedSlot = slot);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(slot.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            if (slot.component != null) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove Component'),
                textColor: AppTheme.error,
                iconColor: AppTheme.error,
                onTap: () {
                  setState(() => slot.component = null);
                  Navigator.pop(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Browse Components'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/components');
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getComponentIcon(String name) {
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
    return icons[name] ?? Icons.devices;
  }
}

class _ComponentSlot {
  final String name;
  final IconData icon;
  final Offset position;
  String? component;

  _ComponentSlot({required this.name, required this.icon, required this.position, this.component});
}

class _CasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.8, size.height * 0.8),
      paint,
    );

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.05)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
