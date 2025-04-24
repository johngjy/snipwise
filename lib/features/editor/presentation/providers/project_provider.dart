import 'package:flutter/material.dart';
import '../../data/models/project_model.dart';

/// 项目状态管理
class ProjectProvider extends ChangeNotifier {
  // 当前项目
  ProjectModel? _currentProject;

  // 最近项目列表
  final List<ProjectModel> _recentProjects = [];

  // 是否正在加载
  bool _isLoading = false;

  // 错误信息
  String? _error;

  // Getters
  ProjectModel? get currentProject => _currentProject;
  List<ProjectModel> get recentProjects => _recentProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// 创建新项目
  Future<void> createProject(String name) async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: 实现项目创建逻辑

      notifyListeners();
    } catch (e) {
      _setError('创建项目失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载项目
  Future<void> loadProject(String projectId) async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: 实现项目加载逻辑

      notifyListeners();
    } catch (e) {
      _setError('加载项目失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 保存当前项目
  Future<void> saveCurrentProject() async {
    if (_currentProject == null) {
      _setError('没有活动项目可保存');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // TODO: 实现项目保存逻辑

      notifyListeners();
    } catch (e) {
      _setError('保存项目失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 关闭当前项目
  void closeCurrentProject() {
    _currentProject = null;
    notifyListeners();
  }

  // 私有辅助方法
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
