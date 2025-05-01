import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../domain/models/tool_type.dart';
import '../../domain/models/tool_settings.dart';

/// 样式工具栏 - 根据当前工具显示不同的样式选项
class StyleToolbar extends StatefulWidget {
  /// 当前工具类型
  final ToolType toolType;

  /// 当前工具设置
  final ToolSettings settings;

  /// 设置变更回调
  final void Function(ToolSettings) onSettingsChanged;

  /// 构造函数
  const StyleToolbar({
    Key? key,
    required this.toolType,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  StyleToolbarState createState() => StyleToolbarState();
}

class StyleToolbarState extends State<StyleToolbar> {
  /// 当前选中的颜色
  late Color _selectedColor;

  /// 当前线宽
  late double _strokeWidth;

  /// 填充颜色
  late Color? _fillColor;

  /// 文本大小
  late double _fontSize;

  /// 当前字体
  late String _fontFamily;

  @override
  void initState() {
    super.initState();
    _updateFromSettings();
  }

  @override
  void didUpdateWidget(StyleToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings ||
        oldWidget.toolType != widget.toolType) {
      _updateFromSettings();
    }
  }

  /// 从设置中更新当前状态
  void _updateFromSettings() {
    _selectedColor = widget.settings.strokeColor;
    _strokeWidth = widget.settings.strokeWidth;
    _fillColor = widget.settings.fillColor;
    _fontSize = widget.settings.fontSize;
    _fontFamily = widget.settings.fontFamily;
  }

  /// 更新设置并通知父组件
  void _updateSettings() {
    final updatedSettings = widget.settings.copyWith(
      strokeColor: _selectedColor,
      strokeWidth: _strokeWidth,
      fillColor: _fillColor,
      fontSize: _fontSize,
      fontFamily: _fontFamily,
    );

    widget.onSettingsChanged(updatedSettings);
  }

  @override
  Widget build(BuildContext context) {
    // 根据工具类型显示不同的设置选项
    return Container(
      height: 48,
      color: CupertinoTheme.of(context).barBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 工具名称
          Text(
            _getToolName(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(width: 16),

          // 根据工具类型显示不同的设置组件
          ..._getToolSettingsWidgets(),
        ],
      ),
    );
  }

  /// 获取工具名称
  String _getToolName() {
    switch (widget.toolType) {
      case ToolType.select:
        return '选择工具';
      case ToolType.rectangle:
        return '矩形工具';
      case ToolType.arrow:
        return '箭头工具';
      case ToolType.freedraw:
        return '自由绘图工具';
      case ToolType.text:
        return '文本工具';
    }
  }

  /// 获取工具设置组件
  List<Widget> _getToolSettingsWidgets() {
    final List<Widget> widgets = [];

    switch (widget.toolType) {
      case ToolType.select:
        // 选择工具没有特定设置
        widgets.add(
          const Text('选择或移动对象',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        );
        break;

      case ToolType.rectangle:
        // 矩形工具设置：线宽、线条颜色、填充颜色
        widgets.addAll([
          _buildStrokeWidthSelector(),
          const SizedBox(width: 16),
          _buildColorSelector(
            label: '线条颜色',
            color: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _updateSettings();
              });
            },
          ),
          const SizedBox(width: 16),
          _buildColorSelector(
            label: '填充颜色',
            color: _fillColor ?? Colors.transparent,
            onColorChanged: (color) {
              setState(() {
                _fillColor = color.opacity == 0 ? null : color;
                _updateSettings();
              });
            },
            allowTransparent: true,
          ),
        ]);
        break;

      case ToolType.arrow:
        // 箭头工具设置：线宽、线条颜色
        widgets.addAll([
          _buildStrokeWidthSelector(),
          const SizedBox(width: 16),
          _buildColorSelector(
            label: '线条颜色',
            color: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _updateSettings();
              });
            },
          ),
        ]);
        break;

      case ToolType.freedraw:
        // 自由绘图工具设置：线宽、线条颜色
        widgets.addAll([
          _buildStrokeWidthSelector(),
          const SizedBox(width: 16),
          _buildColorSelector(
            label: '线条颜色',
            color: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _updateSettings();
              });
            },
          ),
        ]);
        break;

      case ToolType.text:
        // 文本工具设置：字体大小、字体、文本颜色
        widgets.addAll([
          _buildFontSizeSelector(),
          const SizedBox(width: 16),
          _buildFontFamilySelector(),
          const SizedBox(width: 16),
          _buildColorSelector(
            label: '文本颜色',
            color: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _updateSettings();
              });
            },
          ),
        ]);
        break;
    }

    return widgets;
  }

  /// 构建线宽选择器
  Widget _buildStrokeWidthSelector() {
    return Row(
      children: [
        const Text('线宽:', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: CupertinoSlider(
            value: _strokeWidth,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _strokeWidth = value;
                _updateSettings();
              });
            },
          ),
        ),
        Text('${_strokeWidth.round()}', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  /// 构建字体大小选择器
  Widget _buildFontSizeSelector() {
    return Row(
      children: [
        const Text('字号:', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: CupertinoSlider(
            value: _fontSize,
            min: 10,
            max: 30,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
                _updateSettings();
              });
            },
          ),
        ),
        Text('${_fontSize.round()}', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  /// 构建字体选择器
  Widget _buildFontFamilySelector() {
    const List<String> fontFamilies = [
      'Roboto',
      'Arial',
      'Helvetica',
      'Times New Roman',
    ];

    return Row(
      children: [
        const Text('字体:', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _fontFamily,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _fontFamily = newValue;
                _updateSettings();
              });
            }
          },
          items: fontFamilies.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: TextStyle(fontFamily: value, fontSize: 14)),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建颜色选择器
  Widget _buildColorSelector({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorChanged,
    bool allowTransparent = false,
  }) {
    return Row(
      children: [
        Text('$label:', style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _showColorPicker(
              context, color, onColorChanged, allowTransparent),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: color.opacity == 0
                ? const Icon(CupertinoIcons.xmark, size: 16, color: Colors.grey)
                : null,
          ),
        ),
      ],
    );
  }

  /// 显示颜色选择器对话框
  Future<void> _showColorPicker(
    BuildContext context,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
    bool allowTransparent,
  ) async {
    Color resultColor = currentColor;

    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 300,
            height: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('选择颜色',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ColorPicker(
                    color: currentColor,
                    onColorChanged: (Color color) {
                      resultColor = color;
                    },
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    spacing: 10,
                    runSpacing: 10,
                    wheelDiameter: 200,
                    heading: const Text('选择颜色'),
                    subheading: const Text('选择颜色的色调'),
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: false,
                      ColorPickerType.wheel: true,
                    },
                  ),
                ),
                if (allowTransparent)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      resultColor = Colors.transparent;
                      Navigator.pop(context);
                    },
                    child: const Text('透明'),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('取消'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        onColorChanged(resultColor);
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
