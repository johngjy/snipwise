import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/magnifier_model.dart';

/// 放大镜状态管理
class MagnifierProvider extends ChangeNotifier {
  // 所有放大镜实例
  final List<MagnifierModel> _magnifiers = [];

  // 当前选中的放大镜ID
  String? _selectedMagnifierId;

  // 是否处于放大镜编辑模式
  bool _isInMagnifierMode = false;

  // Getters
  List<MagnifierModel> get magnifiers => List.unmodifiable(_magnifiers);
  String? get selectedMagnifierId => _selectedMagnifierId;
  bool get isInMagnifierMode => _isInMagnifierMode;
  bool get hasMagnifiers => _magnifiers.isNotEmpty;

  // 获取当前选中的放大镜
  MagnifierModel? get selectedMagnifier {
    if (_selectedMagnifierId == null) return null;
    return _magnifiers.firstWhere(
      (m) => m.id == _selectedMagnifierId,
      orElse: () => throw StateError('Selected magnifier not found'),
    );
  }

  /// 添加新放大镜
  void addMagnifier(Offset position) {
    final magnifier = MagnifierModel(
      id: const Uuid().v4(),
      center: position,
      radius: 100,
      zoom: 2.0,
      isActive: true,
    );

    _magnifiers.add(magnifier);
    _selectedMagnifierId = magnifier.id;
    notifyListeners();
  }

  /// 选择放大镜
  void selectMagnifier(String id) {
    _selectedMagnifierId = id;
    notifyListeners();
  }

  /// 更新放大镜位置
  void updateMagnifierPosition(String id, Offset newPosition) {
    final index = _getIndexById(id);
    if (index != -1) {
      final updated = _magnifiers[index].copyWith(center: newPosition);
      _magnifiers[index] = updated;
      notifyListeners();
    }
  }

  /// 更新放大镜半径
  void updateMagnifierRadius(String id, double newRadius) {
    final index = _getIndexById(id);
    if (index != -1) {
      final updated = _magnifiers[index].copyWith(radius: newRadius);
      _magnifiers[index] = updated;
      notifyListeners();
    }
  }

  /// 更新放大倍率
  void updateMagnifierZoom(String id, double newZoom) {
    final index = _getIndexById(id);
    if (index != -1) {
      final updated = _magnifiers[index].copyWith(zoom: newZoom);
      _magnifiers[index] = updated;
      notifyListeners();
    }
  }

  /// 切换放大镜激活状态
  void toggleMagnifierActive(String id) {
    final index = _getIndexById(id);
    if (index != -1) {
      final currentActive = _magnifiers[index].isActive;
      final updated = _magnifiers[index].copyWith(isActive: !currentActive);
      _magnifiers[index] = updated;
      notifyListeners();
    }
  }

  /// 删除放大镜
  void removeMagnifier(String id) {
    _magnifiers.removeWhere((m) => m.id == id);
    if (_selectedMagnifierId == id) {
      _selectedMagnifierId =
          _magnifiers.isNotEmpty ? _magnifiers.last.id : null;
    }
    notifyListeners();
  }

  /// 切换放大镜模式
  void toggleMagnifierMode() {
    _isInMagnifierMode = !_isInMagnifierMode;
    notifyListeners();
  }

  /// 清除所有放大镜
  void clearAllMagnifiers() {
    _magnifiers.clear();
    _selectedMagnifierId = null;
    notifyListeners();
  }

  // 辅助方法
  int _getIndexById(String id) {
    return _magnifiers.indexWhere((m) => m.id == id);
  }
}
