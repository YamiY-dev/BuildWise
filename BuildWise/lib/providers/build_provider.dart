import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/component.dart';
import '../models/build.dart';

class BuildProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Map<String, Component?> _selectedComponents = {};
  Map<String, List<CompatibilityIssue>> _compatibilityIssues = {};
  double _totalPrice = 0;
  String _buildName = '';
  String _buildDescription = '';
  String _buildType = BuildType.custom;
  bool _isPublic = false;

  List<Component> _availableComponents = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  Map<String, Component?> get selectedComponents => Map.unmodifiable(_selectedComponents);
  Map<String, List<CompatibilityIssue>> get compatibilityIssues => Map.unmodifiable(_compatibilityIssues);
  double get totalPrice => _totalPrice;
  String get buildName => _buildName;
  String get buildDescription => _buildDescription;
  String get buildType => _buildType;
  bool get isPublic => _isPublic;
  List<Component> get availableComponents => _availableComponents;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasIssues => _compatibilityIssues.values.any((list) => list.isNotEmpty);

  BuildProvider() {
    _initializeCategories();
  }

  void _initializeCategories() {
    _selectedComponents = {
      'CPU': null,
      'GPU': null,
      'RAM': null,
      'Motherboard': null,
      'SSD': null,
      'PSU': null,
      'Case': null,
      'Cooler': null,
    };
  }

  Future<void> loadCategories() async {
    try {
      final response = await _supabase
          .from('component_categories')
          .select()
          .order('display_order');
      _categories = response.map<Category>((c) => Category.fromJson(c)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadComponents(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('components')
          .select()
          .eq('category_id', categoryId)
          .order('price');
      _availableComponents = response.map<Component>((c) => Component.fromJson(c)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectComponent(String category, Component component) {
    _selectedComponents[category] = component;
    _checkCompatibility();
    _calculateTotalPrice();
    notifyListeners();
  }

  void removeComponent(String category) {
    _selectedComponents[category] = null;
    _checkCompatibility();
    _calculateTotalPrice();
    notifyListeners();
  }

  void _calculateTotalPrice() {
    _totalPrice = _selectedComponents.values
        .where((c) => c != null)
        .fold(0.0, (sum, c) => sum! + c!.price);
  }

  void _checkCompatibility() {
    _compatibilityIssues.clear();

    final cpu = _selectedComponents['CPU'];
    final motherboard = _selectedComponents['Motherboard'];
    final ram = _selectedComponents['RAM'];
    final gpu = _selectedComponents['GPU'];
    final psu = _selectedComponents['PSU'];
    final case_ = _selectedComponents['Case'];
    final cooler = _selectedComponents['Cooler'];

    if (cpu != null && motherboard != null) {
      final cpuSocket = cpu.specs['socket'] as String?;
      final moboSocket = motherboard.specs['socket'] as String?;
      if (cpuSocket != null && moboSocket != null && cpuSocket != moboSocket) {
        _compatibilityIssues.putIfAbsent('CPU', () => []).add(
          CompatibilityIssue(
            type: IssueType.error,
            message: 'CPU socket ($cpuSocket) is incompatible with motherboard socket ($moboSocket)',
          ),
        );
        _compatibilityIssues.putIfAbsent('Motherboard', () => []).add(
          CompatibilityIssue(
            type: IssueType.error,
            message: 'Motherboard socket ($moboSocket) is incompatible with CPU socket ($cpuSocket)',
          ),
        );
      }
    }

    if (ram != null && motherboard != null) {
      final ramType = ram.specs['type'] as String?;
      final moboMemoryType = motherboard.specs['memory_type'] as String?;
      if (ramType != null && moboMemoryType != null) {
        if (!moboMemoryType.contains(ramType)) {
          _compatibilityIssues.putIfAbsent('RAM', () => []).add(
            CompatibilityIssue(
              type: IssueType.error,
              message: 'RAM type ($ramType) is not supported by motherboard ($moboMemoryType)',
            ),
          );
        }
      }
    }

    if ((cpu != null || gpu != null) && psu != null) {
      int totalTdp = 0;
      if (cpu != null) {
        totalTdp += (cpu.specs['tdp'] as int?) ?? 0;
      }
      if (gpu != null) {
        totalTdp += (gpu.specs['tdp'] as int?) ?? 0;
      }
      final psuWattage = psu.specs['wattage'] as int? ?? 0;
      final recommendedPsu = totalTdp * 1.5;

      if (psuWattage < recommendedPsu) {
        _compatibilityIssues.putIfAbsent('PSU', () => []).add(
          CompatibilityIssue(
            type: IssueType.warning,
            message: 'PSU may be underpowered. Recommended: ${recommendedPsu.toInt()}W, Selected: ${psuWattage}W',
          ),
        );
      }
    }

    if (gpu != null && case_ != null) {
      final gpuLength = gpu.specs['length'] as int?;
      final caseClearance = case_.specs['gpu_clearance'] as int?;
      if (gpuLength != null && caseClearance != null && gpuLength > caseClearance) {
        _compatibilityIssues.putIfAbsent('GPU', () => []).add(
          CompatibilityIssue(
            type: IssueType.error,
            message: 'GPU length ($gpuLength mm) exceeds case clearance ($caseClearance mm)',
          ),
        );
      }
    }

    if (motherboard != null && case_ != null) {
      final moboFormFactor = motherboard.specs['form_factor'] as String?;
      final caseSupport = case_.specs['form_factor_support'] as List?;
      if (moboFormFactor != null && caseSupport != null) {
        if (!caseSupport.contains(moboFormFactor)) {
          _compatibilityIssues.putIfAbsent('Motherboard', () => []).add(
            CompatibilityIssue(
              type: IssueType.error,
              message: 'Motherboard form factor ($moboFormFactor) is not supported by case',
            ),
          );
        }
      }
    }

    if (cooler != null && case_ != null) {
      final coolerHeight = cooler.specs['height'] as int?;
      final caseCoolerHeight = case_.specs['cpu_cooler_height'] as int?;
      if (coolerHeight != null && caseCoolerHeight != null && coolerHeight > caseCoolerHeight) {
        _compatibilityIssues.putIfAbsent('Cooler', () => []).add(
          CompatibilityIssue(
            type: IssueType.error,
            message: 'CPU cooler height ($coolerHeight mm) exceeds case clearance ($caseCoolerHeight mm)',
          ),
        );
      }
    }
  }

  PerformanceEstimate estimatePerformance() {
    final cpu = _selectedComponents['CPU'];
    final gpu = _selectedComponents['GPU'];
    final ram = _selectedComponents['RAM'];

    int cpuScore = cpu?.performanceScore ?? 0;
    int gpuScore = gpu?.performanceScore ?? 0;
    int ramScore = ram?.performanceScore ?? 0;

    int gamingScore = ((gpuScore * 0.6 + cpuScore * 0.3 + ramScore * 0.1)).round();
    int productivityScore = ((cpuScore * 0.6 + gpuScore * 0.2 + ramScore * 0.2)).round();

    double bottleneckPercentage = 0;
    if (cpuScore > 0 && gpuScore > 0) {
      final ratio = cpuScore / gpuScore;
      if (ratio < 0.7) {
        bottleneckPercentage = (0.7 - ratio) * 100;
      } else if (ratio > 1.3) {
        bottleneckPercentage = (ratio - 1.3) * 100;
      }
    }

    int totalTdp = (cpu?.specs['tdp'] as int? ?? 0) +
        (gpu?.specs['tdp'] as int? ?? 0);
    int recommendedPsu = (totalTdp * 1.5).round();

    return PerformanceEstimate(
      gamingScore: gamingScore,
      productivityScore: productivityScore,
      bottleneckPercentage: bottleneckPercentage,
      recommendedPsuWattage: recommendedPsu,
      estimatedPowerConsumption: totalTdp + 50,
    );
  }

  Map<String, double> estimateFps(String game, String resolution) {
    final gpu = _selectedComponents['GPU'];
    final cpu = _selectedComponents['CPU'];

    if (gpu == null) return {};

    final gpuPerformance = gpu.performanceScore ?? 0;
    final cpuPerformance = cpu?.performanceScore ?? 0;

    double baseMultiplier = resolution == '1080p' ? 1.0 :
                          resolution == '1440p' ? 0.65 : 0.4;

    Map<String, double> gameMultipliers = {
      'Fortnite': 1.2,
      'Valorant': 1.5,
      'CS2': 1.3,
      'GTA V': 0.8,
      'Cyberpunk 2077': 0.5,
      'Minecraft': 2.0,
    };

    double multiplier = gameMultipliers[game] ?? 1.0;
    double fps = (gpuPerformance * multiplier * baseMultiplier +
                 cpuPerformance * 0.1) * 15;

    return {
      'fps': fps.clamp(30, 360).toDouble(),
      'cpu_usage': ((cpuPerformance / 10) * 100).clamp(20, 100).toDouble(),
      'gpu_usage': ((gpuPerformance / 10) * 100).clamp(40, 100).toDouble(),
    };
  }

  ThermalEstimate estimateThermal() {
    final cpu = _selectedComponents['CPU'];
    final gpu = _selectedComponents['GPU'];
    final case_ = _selectedComponents['Case'];
    final cooler = _selectedComponents['Cooler'];

    int cpuTdp = cpu?.specs['tdp'] as int? ?? 0;
    int gpuTdp = gpu?.specs['tdp'] as int? ?? 0;

    double cpuTemp = 45 + (cpuTdp / 10) * 2;
    double gpuTemp = 40 + (gpuTdp / 10) * 1.5;

    if (cooler != null) {
      int coolerTdp = cooler.specs['tdp_rating'] as int? ?? 150;
      if (coolerTdp >= cpuTdp * 1.2) {
        cpuTemp -= 15;
      } else if (coolerTdp >= cpuTdp) {
        cpuTemp -= 10;
      }
    }

    int fansIncluded = case_?.specs['fans_included'] as int? ?? 0;
    int recommendedFans = 3;
    if (gpuTdp > 250) recommendedFans = 4;
    if (gpuTdp > 350) recommendedFans = 5;

    if (fansIncluded < recommendedFans) {
      cpuTemp += (recommendedFans - fansIncluded) * 2;
      gpuTemp += (recommendedFans - fansIncluded) * 3;
    }

    String airflowQuality = 'Good';
    if (cpuTemp > 75 || gpuTemp > 80) {
      airflowQuality = 'Needs Improvement';
    } else if (cpuTemp < 60 && gpuTemp < 65 && fansIncluded >= recommendedFans) {
      airflowQuality = 'Excellent';
    }

    return ThermalEstimate(
      estimatedCpuTemp: cpuTemp.clamp(35, 95),
      estimatedGpuTemp: gpuTemp.clamp(35, 90),
      recommendedFans: recommendedFans,
      airflowQuality: airflowQuality,
    );
  }

  void setBuildName(String name) {
    _buildName = name;
    notifyListeners();
  }

  void setBuildDescription(String description) {
    _buildDescription = description;
    notifyListeners();
  }

  void setBuildType(String type) {
    _buildType = type;
    notifyListeners();
  }

  void setIsPublic(bool isPublic) {
    _isPublic = isPublic;
    notifyListeners();
  }

  Future<void> saveBuild() async {
    if (_buildName.isEmpty) {
      _error = 'Please enter a build name';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      final componentsMap = <String, dynamic>{};

      _selectedComponents.forEach((key, value) {
        if (value != null) {
          componentsMap[key] = value.toJson();
        }
      });

      await _supabase.from('builds').insert({
        'user_id': userId,
        'name': _buildName,
        'description': _buildDescription,
        'build_type': _buildType,
        'components': componentsMap,
        'total_price': _totalPrice,
        'is_public': _isPublic,
      });

      clearBuild();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadBuild(Build build) {
    _buildName = build.name;
    _buildDescription = build.description ?? '';
    _buildType = build.buildType;
    _totalPrice = build.totalPrice;
    _isPublic = build.isPublic;

    _selectedComponents.clear();
    _initializeCategories();

    build.components.forEach((key, value) {
      _selectedComponents[key] = Component.fromJson(value);
    });

    _checkCompatibility();
    notifyListeners();
  }

  void clearBuild() {
    _buildName = '';
    _buildDescription = '';
    _buildType = BuildType.custom;
    _totalPrice = 0;
    _isPublic = false;
    _compatibilityIssues.clear();
    _initializeCategories();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class CompatibilityIssue {
  final IssueType type;
  final String message;

  CompatibilityIssue({
    required this.type,
    required this.message,
  });
}

enum IssueType { error, warning }

class PerformanceEstimate {
  final int gamingScore;
  final int productivityScore;
  final double bottleneckPercentage;
  final int recommendedPsuWattage;
  final int estimatedPowerConsumption;

  PerformanceEstimate({
    required this.gamingScore,
    required this.productivityScore,
    required this.bottleneckPercentage,
    required this.recommendedPsuWattage,
    required this.estimatedPowerConsumption,
  });
}

class ThermalEstimate {
  final double estimatedCpuTemp;
  final double estimatedGpuTemp;
  final int recommendedFans;
  final String airflowQuality;

  ThermalEstimate({
    required this.estimatedCpuTemp,
    required this.estimatedGpuTemp,
    required this.recommendedFans,
    required this.airflowQuality,
  });
}
