import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/build_provider.dart';
import '../../models/build.dart';
import '../../theme/app_theme.dart';

class SaveBuildDialog extends StatefulWidget {
  final BuildProvider provider;

  const SaveBuildDialog({super.key, required this.provider});

  @override
  State<SaveBuildDialog> createState() => _SaveBuildDialogState();
}

class _SaveBuildDialogState extends State<SaveBuildDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _buildType = BuildType.custom;
  bool _isPublic = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Save Build',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Build Name',
                hintText: 'My Gaming PC',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Describe your build...',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Build Type',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BuildType.getAll().map((type) {
                return ChoiceChip(
                  label: Text(BuildType.getDisplayName(type)),
                  selected: _buildType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _buildType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Make Public'),
              subtitle: Text(
                'Share your build with the community',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _nameController,
                    builder: (context, value, _) {
                      return ElevatedButton(
                        onPressed: value.text.isNotEmpty
                            ? () => _saveBuild(context)
                            : null,
                        child: const Text('Save'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveBuild(BuildContext context) {
    widget.provider.setBuildName(_nameController.text);
    widget.provider.setBuildDescription(_descriptionController.text);
    widget.provider.setBuildType(_buildType);
    widget.provider.setIsPublic(_isPublic);

    widget.provider.saveBuild().then((_) {
      if (widget.provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.provider.error!),
            backgroundColor: AppTheme.error,
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Build saved successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }
}
