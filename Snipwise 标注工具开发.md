
Snipwise 标注工具开发 Prompts通用属性弹出框设计理念 (基于 image_46bc6c.png):所有工具的“属性选择弹出框”将显示在顶部工具栏下方，设计力求简洁直观。基本布局将包含：颜色选择器 (Color Picker): 一个小的方形颜色预览，点击后弹出完整的颜色选择器。滑块 (Slider): 用于调整数值型属性，如线条粗细、字体大小、圆角大小或透明度。旁边可能伴有数值显示。分段按钮/切换器 (Segmented Buttons/Toggles): 用于在几种预设样式、类型或模式之间切换（例如，箭头类型、线条样式、形状是填充还是描边）。专用图标按钮 (Icon Buttons): 用于特定操作或切换布尔属性（例如，是否显示边框/填充的开关）。重要提示：每个工具的属性选择弹出框都应实现为一个独立的、可复用的 Flutter Widget。 例如，SpeechBubblePropertiesPanel(drawable: selectedDrawable, onPropertyChanged: (updatedDrawable) => {...})。通用开发工作流程 (适用于每个标注工具):定义 Drawable 类:创建工具对应的 XxxDrawable 类 (例如 SpeechBubbleDrawable)，继承自 flutter_painter 合适的基类 (通常是 ObjectDrawable)。定义其所有必要的属性 (位置、大小、颜色、文本内容、样式等)。实现 copyWith 方法以支持不可变更新。实现基础绘制逻辑:在 XxxDrawable 的 draw 方法中实现基础的绘制逻辑，使其能在画布上正确显示。确保绘制时考虑到所有定义的属性 (颜色、粗细、填充等)。实现核心交互:选择: 确保 Drawable 可以被选中。移动: 实现拖拽移动 Drawable 的功能。缩放/变形: 根据工具特性实现缩放或变形的控制点和逻辑 (例如，CleanShotX 样式的边线中点拖拽)。在 interactionTest (或相关方法) 中实现对控制点的命中检测。实现工具特定交互:根据工具的独特需求实现特定交互 (例如，箭头的弧线切换、Callout 的指示线连接点拖拽等)。开发属性选择面板 Widget:创建独立的 XxxPropertiesPanel.dart Widget。设计 UI 以匹配通用设计理念，并包含该工具所有可配置属性的控件。该 Widget 接收当前的 Drawable 属性，并通过回调函数将用户的更改通知给父组件。状态管理与集成:将新的 Drawable 和 PropertiesPanel 集成到应用的整体状态管理中 (例如，通过 AnnotationProvider / PainterProvider)。确保 PainterController 能正确添加、更新和删除新的 Drawable。连接属性面板的更改到 Drawable 的更新逻辑。详细测试:对工具的绘制、所有交互、属性修改、边缘情况进行全面测试。1. 对话框/语音气泡工具 (SpeechBubble Tool) - CleanShotX 样式目标: 创建一个可以添加对话框或语音气泡的标注工具，其边框可以通过拖拽边线中点进行调整，内部可以编辑文字。SpeechBubbleDrawable.dart Prompt:// Feature: Implement SpeechBubbleDrawable for Snipwise
//
// Description:
// Create a Flutter Painter Drawable class named `SpeechBubbleDrawable` that extends `ObjectDrawable`.
// It represents a speech bubble or a rectangular dialog box with editable text and an optional tail.
// Resizing is a key feature: it must be done by dragging handles located at the *midpoints of the four edges*
// of the bubble's main rectangle, similar to CleanShotX.

// Properties:
// - rect: The `Rect` defining the main body of the bubble.
// - textDrawable: A `TextDrawable` instance, nested within the bubble for editable text content.
//   It should be initialized with default text properties (e.g., from AnnotationProvider).
//   Its offset should be relative to the SpeechBubbleDrawable's position, and it should resize/reflow
//   within the bubble's bounds (considering internal padding).
// - backgroundColor: `Color` for the bubble's fill. (Defaults to transparent).
// - borderColor: `Color` for the bubble's border.
// - strokeWidth: `double` for the thickness of the border.
// - borderRadius: `BorderRadius` for rounded corners of the bubble's body.
// - tailPosition: An `Offset` relative to the bubble's `rect` (e.g., a point on its perimeter)
//   indicating where the tail originates. Nullable or use a sentinel value if no tail.
// - tailTarget: An `Offset` on the canvas indicating where the tail points to. Nullable.
// - showTail: `bool` to control tail visibility.
// - padding: `EdgeInsets` for internal padding between the bubble's border and the text content.
// - hasStroke: `bool` indicating if the border is visible. Defaults to false initially for new objects, true if stroke properties are set.
// - hasFill: `bool` indicating if the background is filled. Defaults to false initially for new objects, true if background color is set.
// - textStyle: `TextStyle` for the textDrawable (fontFamily, fontSize, color).

// Constructor:
// - Primary constructor accepting all properties.
// - Factory constructor `fromTarget({Offset target, String initialText, ...defaultStyles})`
//   to create a new bubble at a target point, perhaps from a user click.

// Methods:
// - `copyWith({...})`: Essential for immutable updates. Ensure it handles all properties,
//   including deep copying or updating the nested `textDrawable` and its `textStyle`.
// - `draw(Canvas canvas, Size size, PaintingContext context)`:
//   - If `hasFill` is true, render the rounded rectangle body with `backgroundColor`.
//   - If `hasStroke` is true, draw the border with `borderColor` and `strokeWidth`.
//   - If `showTail` is true and `tailPosition` & `tailTarget` are valid, draw the tail
//     (e.g., as a triangle or a smoothly connected shape from `tailPosition` on the rect's
//     edge to `tailTarget`). Tail color should match `borderColor` if `hasStroke`, else a default or text color.
//   - Update `textDrawable.style` with `this.textStyle` before drawing `textDrawable`.
//   - Draw the `textDrawable` within the `rect` minus `padding`. Ensure text wraps correctly.
//   - When selected, draw the four edge midpoint resize handles. These handles should be
//     visually distinct.
// - `interactionTest(Offset globalPosition)`:
//   - Override or implement custom logic for hit-testing.
//   - Must correctly identify if a tap is on one of the four edge midpoint resize handles,
//     the main body (for dragging), or the tail handles (if implemented).
// - Helper methods for:
//   - Calculating the positions of the four edge midpoint handles based on `rect`.
//   - Updating the `rect` when an edge handle is dragged.
//   - Managing the `textDrawable`'s position and constraints as the bubble resizes.

// Properties Popout Panel (UI below top toolbar, shown when tool is active or this drawable is selected):
//   **Implemented as a separate widget: `SpeechBubblePropertiesPanel.dart`**
//   Layout: Horizontal arrangement of controls.
//   - Text Properties Section:
//     - Font Family: Dropdown/Icon button leading to font list (default 'Roboto'). Updates `textStyle.fontFamily`.
//     - Font Size: Compact slider with current value display (default 14). Updates `textStyle.fontSize`.
//     - Text Color: Small color square (default Colors.black), click to open full color picker. Updates `textStyle.color`.
//   - Frame & Fill Section:
//     - Stroke Toggle & Properties:
//       - Icon Button (e.g., border_style icon) to toggle `hasStroke`.
//       - If `hasStroke` is true:
//         - Stroke Color: Small color square (default Colors.black), click for picker. Updates `borderColor`.
//         - Stroke Thickness: Compact slider. Updates `strokeWidth`.
//     - Fill Toggle & Properties:
//       - Icon Button (e.g., format_color_fill icon) to toggle `hasFill`.
//       - If `hasFill` is true:
//         - Fill Color: Small color square (default Colors.transparent), click for picker. Updates `backgroundColor`.
//         - Opacity (if fill is active): Compact slider (0-100%) for `backgroundColor`'s alpha.

// State Management Integration (within EditorPage/AnnotationProvider):
// - When an edge handle is dragged (`onPanUpdate`):
//   - Update the `SpeechBubbleDrawable`'s `rect` property.
//   - The `textDrawable`'s bounds might need to be recalculated.
//   - Replace the old drawable with the new one in `PainterController`.
// - Text editing: Double-tapping the `SpeechBubbleDrawable` should activate text editing mode
//   for the nested `textDrawable`.
// - Property changes from the `SpeechBubblePropertiesPanel` widget update the corresponding properties of the selected
//   `SpeechBubbleDrawable` and then replace it in the `PainterController`.

// **Development Steps & Checkpoint:**
// 1. Implement `SpeechBubbleDrawable` with basic properties and `draw` method for the rectangle and text.
// 2. Implement CleanShotX-style edge midpoint handles and resizing logic.
// 3. Implement tail drawing and manipulation (if applicable).
// 4. Develop `SpeechBubblePropertiesPanel.dart` for all specified text, stroke, and fill properties.
// 5. Integrate with `PainterController` and state management for adding, selecting, modifying, and deleting bubbles.
// 6. **Checkpoint:** Thoroughly test all aspects of the SpeechBubble tool: drawing, resizing (all edges), text editing, tail manipulation, property changes via the panel, selection, and deletion. Ensure it behaves as expected before proceeding.
2. 箭头工具 (Arrow Tool) - CleanShotX 样式目标: 创建一个箭头工具，可以通过拖拽起点和终点来调整。关键功能是：点击箭头中间的一个控制点，会弹出一个对话框，允许用户将直线箭头转换为可编辑的弧形箭头。ArrowDrawable.dart Prompt:// Feature: Implement ArrowDrawable for Snipwise
//
// Description:
// Create a Flutter Painter Drawable class named `ArrowDrawable` that extends `ObjectDrawable`.
// It represents an arrow defined by a start and end point.
// It can be a straight line or a quadratic Bezier curve (arc).
// A key interaction is a midpoint handle that, when clicked, triggers a dialog
// to switch between straight and arc modes.

// Properties:
// - startPoint: `Offset` of the arrow's tail.
// - endPoint: `Offset` of the arrow's head.
// - color: `Color` of the arrow line and head. (Default Colors.black)
// - strokeWidth: `double` for the thickness of the arrow line. (Default 2.0)
// - headStyle: Enum (e.g., `singleFilledTriangle`, `doubleFilledTriangle`, `singleOpenV`, `doubleOpenV`, `lineOnly`)
//   for arrowhead style(s). 'double' implies arrowheads at both start and end.
// - isArc: `bool`, true if the arrow is an arc, false if it's a straight line. Defaults to false.
// - arcControlPoint: `Offset`, the control point for the quadratic Bezier curve if `isArc` is true.
//   When `isArc` is true, this point is draggable to change the arc's curvature.
//   When switching from straight to arc, it's initialized to the midpoint of `startPoint` and `endPoint`.
// - arrowheadLengthFactor: `double`, factor to multiply by strokeWidth to get arrowhead length (e.g., 5.0).
// - arrowheadAngle: `double`, angle of the arrowhead wings (e.g., pi / 6).

// Constructor:
// - Primary constructor for all properties.
// - Factory `fromPoints({Offset start, Offset end, ...defaultStyles})`.

// Methods:
// - `copyWith({...})`: For immutable updates.
// - `draw(Canvas canvas, Size size, PaintingContext context)`:
//   - Calculate actual `arrowheadLength = strokeWidth * arrowheadLengthFactor`.
//   - If `isArc` is false, draw a straight line from `startPoint` to `endPoint`.
//   - If `isArc` is true, draw a quadratic Bezier curve from `startPoint` to `endPoint`
//     using `arcControlPoint`. (Use `Path.quadraticBezierTo()`).
//   - Draw the arrowhead(s) at `endPoint` (and `startPoint` if `headStyle` indicates double-ended),
//     oriented correctly along the line or curve tangent. Arrowhead size uses calculated `arrowheadLength`.
//   - When selected, draw draggable handles for `startPoint` and `endPoint`.
//   - Draw a distinct, clickable handle at the visual midpoint of the line/arc ("arc toggle" handle).
//   - If `isArc` is true, also draw a draggable handle for `arcControlPoint`.
// - `interactionTest(Offset globalPosition)`:
//   - Hit-test for `startPoint`, `endPoint`, "arc toggle" midpoint, and `arcControlPoint` handles.
// - Helper methods for:
//   - Calculating arrowhead geometry.
//   - Calculating tangents for arc arrowhead orientation.
//   - Calculating the "arc toggle" midpoint handle position.

// Properties Popout Panel (UI below top toolbar):
//   **Implemented as a separate widget: `ArrowPropertiesPanel.dart`**
//   Layout: Horizontal arrangement.
//   - Arrow Color: Small color square (default Colors.black), click for picker. Updates `color`.
//   - Arrow Thickness: Compact slider with value display (default 2.0). Updates `strokeWidth`.
//     (Arrowhead size automatically scales with thickness).
//   - Arrow Style: Segmented button/icon toggles for `headStyle` (e.g., [图片：单向箭头图标], [图片：双向箭头图标], [图片：直线图标]).
//   - (Optional) Arc Toggle Button: An icon button (e.g., [图片：曲线图标]) to directly toggle `isArc` or open `ArcOptionsDialog`. This could be an alternative/addition to the on-drawable midpoint click.

// State Management Integration:
// - Dragging handles updates `startPoint`, `endPoint`, or `arcControlPoint`.
// - Clicking "arc toggle" midpoint handle on drawable (or dedicated button in `ArrowPropertiesPanel`) triggers `ArcOptionsDialog`.
//   Based on dialog, update `isArc`, `arcControlPoint`, and replace drawable.
// - Property changes from the `ArrowPropertiesPanel` widget update the `ArrowDrawable` and replace it.

// **Development Steps & Checkpoint:**
// 1. Implement `ArrowDrawable` with properties for start/end points, color, strokeWidth, and `draw` for a straight line and arrowhead.
// 2. Implement draggable handles for `startPoint` and `endPoint`.
// 3. Add `isArc` and `arcControlPoint` properties. Implement drawing for the arc (Bezier curve).
// 4. Implement the "arc toggle" midpoint handle on the drawable:
//    - Clicking it should trigger `ArcOptionsDialog.dart` (develop this common dialog).
//    - Based on dialog result, update `isArc` and `arcControlPoint`.
//    - Implement dragging for `arcControlPoint` when `isArc` is true.
// 5. Develop `ArrowPropertiesPanel.dart` for color, thickness, and arrow style.
// 6. Integrate with `PainterController` and state management.
// 7. **Checkpoint:** Test straight arrow drawing, manipulation, arc conversion, arc manipulation, property changes via panel, and arrowhead styles. Ensure the `ArcOptionsDialog` works correctly.
common/arc_options_dialog.dart Prompt (Helper Dialog):// Feature: Implement ArcOptionsDialog
//
// Description:
// A simple dialog that is shown when the user clicks the midpoint handle of an ArrowDrawable
// or CalloutDrawable's leader line. It allows the user to switch between a straight line and an arc.

// Parameters:
// - currentIsArc: `bool` indicating the current state.

// UI:
// - Title: "Line Options" or "切换线条样式"
// - Options (e.g., Radio buttons or simple buttons):
//   - "Straight Line" / "直线"
//   - "Curved Line (Arc)" / "弧线"
// - (Optional) Further arc options if needed in the future (e.g., arc direction).
// - Action buttons: "OK" / "确定", "Cancel" / "取消".

// Return Value:
// - Should return a value indicating the user's choice (e.g., a new `bool` for `isArc`, or null if cancelled).
//   Example: `Future<bool?> showArcOptionsDialog(BuildContext context, bool currentIsArc)`
3. Callout 注释框 (Callout Tool) - 如图所示，指示线可变弧线目标: 创建一个 Callout 工具，它包含一个可编辑文本的矩形框，以及一条指向特定位置的指示线（箭头）。这条指示线的行为应与独立的箭头工具类似。文本框部分应复用对话框/语音气泡工具的组件和逻辑。CalloutDrawable.dart Prompt:// Feature: Implement CalloutDrawable for Snipwise
//
// Description:
// Create a Flutter Painter Drawable class named `CalloutDrawable` that extends `ObjectDrawable`.
// It represents a text box annotation with a leader line (arrow).
// Text box part behaves like SpeechBubbleDrawable (resizing, properties).
// Leader line part behaves like ArrowDrawable (arc toggle, properties).

// Properties:
// - textBoxRect: The `Rect` defining the main text box.
// - textDrawable: A `TextDrawable` instance, nested.
// - leaderLineAnchorPoint: `Offset`, relative to `textBoxRect`, where leader line originates. Draggable along box border.
// - leaderLineTargetPoint: `Offset`, canvas coordinate where leader line points. Draggable.
// - leaderLineColor: `Color`. (Syncs with textBoxBorderColor if textBoxHasStroke, else independent).
// - leaderLineStrokeWidth: `double`. (Syncs with textBoxStrokeWidth if textBoxHasStroke, else independent).
// - leaderLineHeadStyle: Enum for arrowhead style.
// - isLeaderLineArc: `bool`.
// - leaderLineArcControlPoint: `Offset`.
// - textBoxBackgroundColor: `Color`.
// - textBoxBorderColor: `Color`.
// - textBoxStrokeWidth: `double`.
// - textBoxBorderRadius: `BorderRadius`.
// - padding: `EdgeInsets`.
// - textBoxHasStroke: `bool`.
// - textBoxHasFill: `bool`.
// - textStyle: `TextStyle` for the textDrawable.
// - leaderLineArrowheadLengthFactor: `double`.
// - leaderLineArrowheadAngle: `double`.

// Constructor:
// - Primary constructor.
// - Factory `fromTargetPoint({Offset target, Offset initialBoxPosition, String text, ...})`.

// Methods:
// - `copyWith({...})`: Essential.
// - `draw(Canvas canvas, Size size, PaintingContext context)`:
//   - Draw text box (fill if `textBoxHasFill`, border if `textBoxHasStroke`).
//   - Update `textDrawable.style` with `this.textStyle` before drawing `textDrawable`.
//   - Draw `textDrawable` within `textBoxRect` minus `padding`.
//   - Calculate absolute leader line start from `textBoxRect.topLeft + leaderLineAnchorPoint`.
//   - Draw leader line (straight or arc) with arrowhead at `leaderLineTargetPoint`.
//   - When selected, draw handles: 4 edge midpoints for text box, anchor point, target point,
//     leader line arc toggle midpoint, and leader line arc control point (if arc).
// - `interactionTest(Offset globalPosition)`: Hit-test all handles and body.
// - Helper methods: Constrain anchor to border, arrowhead geometry, arc tangents, etc.

// Properties Popout Panel (UI below top toolbar):
//   **Implemented as a separate widget: `CalloutPropertiesPanel.dart`**
//   This panel will internally use or compose reusable panel sections for text box and leader line.
//   - Text Box Properties Section:
//     - Text: (Font Family, Font Size, Text Color) - **Reuse `SpeechBubblePropertiesPanel`'s text section or a dedicated `TextPropertiesPanelWidget`.** Updates `textStyle`.
//     - Frame Stroke: (Toggle, Color, Thickness) - **Reuse `SpeechBubblePropertiesPanel`'s frame/stroke section or a dedicated `FramePropertiesPanelWidget`.** Controls `textBoxHasStroke`, `textBoxStrokeWidth`, `textBoxBorderColor`.
//     - Background Fill: (Toggle, Color, Opacity) - **Reuse `SpeechBubblePropertiesPanel`'s fill section or a dedicated `FillPropertiesPanelWidget`.** Controls `textBoxHasFill`, `textBoxBackgroundColor`.
//   - Leader Line Properties Section (Similar to `ArrowPropertiesPanel` but might be a distinct `LeaderLinePropertiesPanelWidget`):
//     - Leader Line Color: Small color square, click for picker. Updates `leaderLineColor`.
//       *Rule: If `textBoxHasStroke` is true, `leaderLineColor` auto-syncs with `textBoxBorderColor` (picker might be disabled/reflect link). Else, independent.*
//     - Leader Line Thickness: Compact slider. Updates `leaderLineStrokeWidth`.
//       *Rule: If `textBoxHasStroke` is true, `leaderLineStrokeWidth` auto-syncs with `textBoxStrokeWidth`. Else, independent.*
//     - Leader Line Style: Segmented button for `leaderLineHeadStyle` (e.g., arrow, line).
//     - (Optional) Arc Toggle Button for leader line.

// State Management Integration:
// - Handle updates from dragging, text editing, dialogs, and the `CalloutPropertiesPanel` widget.
// - Ensure sync rules for leader line color/thickness are applied when text box stroke properties change.

// **Development Steps & Checkpoint:**
// 1. Implement `CalloutDrawable` combining properties from `SpeechBubbleDrawable` (for text box) and `ArrowDrawable` (for leader line).
// 2. Implement drawing for the text box and the leader line (straight and arc).
// 3. Implement all interactive handles: text box edge midpoints, leader line anchor (constrained to box border), leader line target, and leader line arc toggle/control point.
// 4. Develop `CalloutPropertiesPanel.dart`. This panel should reuse or compose property editing widgets developed for `SpeechBubblePropertiesPanel` and `ArrowPropertiesPanel` to maintain consistency and reduce code.
// 5. Implement the logic for syncing leader line color/thickness with text box stroke when active.
// 6. Integrate with `PainterController` and state management.
// 7. **Checkpoint:** Test all aspects: text box resizing/editing, leader line manipulation (anchor, target, arc conversion/editing), property changes via panel (ensuring correct reuse and syncing), selection, and deletion.
4. 直线注释工具 (Line Tool)目标: 创建一个简单的直线标注工具。LineDrawable.dart Prompt:// Feature: Implement LineDrawable for Snipwise
//
// Description:
// Create a Flutter Painter Drawable class named `LineDrawable` that extends `ObjectDrawable` or `ShapeDrawable`.
// It represents a simple straight line defined by a start and end point.

// Properties:
// - startPoint: `Offset`.
// - endPoint: `Offset`.
// - color: `Color` of the line. (Default Colors.black).
// - strokeWidth: `double` for the line thickness. (Default 2.0).
// - lineStyle: Enum (e.g., `solid`, `dashed`, `dotted`). (Default `solid`).

// Constructor:
// - Primary constructor.
// - Factory `fromPoints({Offset start, Offset end, ...defaultStyles})`.

// Methods:
// - `copyWith({...})`.
// - `draw(Canvas canvas, Size size, PaintingContext context)`:
//   - Draw the line between `startPoint` and `endPoint` applying `color`, `strokeWidth`, and `lineStyle`.
//     (For dashed/dotted, you might need to use `Path.dashPath` if available or implement manually).
//   - When selected, draw draggable handles for `startPoint` and `endPoint`.
// - `interactionTest(Offset globalPosition)`: Hit-test for handles and line body.

// Properties Popout Panel (UI below top toolbar):
//   **Implemented as a separate widget: `LinePropertiesPanel.dart`**
//   Layout: Horizontal arrangement.
//   - Line Color: Small color square (default Colors.black), click for picker. Updates `color`.
//   - Line Thickness: Compact slider with value display (default 2.0). Updates `strokeWidth`.
//   - Line Style: Segmented button/icon toggles for `lineStyle` (e.g., [图片：实线图标], [图片：虚线图标], [图片：点线图标]).

// State Management Integration:
// - Dragging handles updates `startPoint` or `endPoint`.
// - Property changes from the `LinePropertiesPanel` widget update the `LineDrawable` and replace it.

// **Development Steps & Checkpoint:**
// 1. Implement `LineDrawable` with basic properties and `draw` method.
// 2. Implement draggable handles for `startPoint` and `endPoint`.
// 3. Develop `LinePropertiesPanel.dart` for color, thickness, and line style.
// 4. Integrate with `PainterController` and state management.
// 5. **Checkpoint:** Test line drawing, manipulation of start/end points, and property changes (color, thickness, style) via the panel.
5. 圆圈/椭圆注释工具 (Ellipse/Circle Tool)目标: 创建一个可以绘制椭圆或圆形的标注工具，支持描边和填充。EllipseDrawable.dart (or a generic ShapeDrawable) Prompt:// Feature: Implement EllipseDrawable for Snipwise
//
// Description:
// Create a Flutter Painter Drawable class named `EllipseDrawable` that extends `ObjectDrawable` or `ShapeDrawable`.
// It represents an ellipse (or circle if width/height are equal) defined by a bounding rectangle.
// Supports fill and stroke.

// Properties:
// - rect: The `Rect` defining the bounding box of the ellipse.
// - fillColor: `Color` for the ellipse's fill. (Default Colors.transparent).
// - borderColor: `Color` for the ellipse's border. (Default Colors.black).
// - strokeWidth: `double` for the border thickness. (Default 2.0).
// - hasStroke: `bool`, true if border is visible. (Default true for new shapes).
// - hasFill: `bool`, true if shape is filled. (Default false for new shapes).
// - isCircle: `bool`, if true, drawing interaction constrains rect to a square. (Consider if this is a tool mode or a property of the drawable).

// Constructor:
// - Primary constructor.
// - Factory `fromRect(Rect rect, bool isCircleModeActive, ...defaultStyles)`. During creation, if isCircleModeActive, rect might be adjusted to be a square.

// Methods:
// - `copyWith({...})`.
// - `draw(Canvas canvas, Size size, PaintingContext context)`:
//   - If `hasFill` is true, draw the ellipse within `rect` using `fillColor`. (Use `canvas.drawOval()`).
//   - If `hasStroke` is true, draw the ellipse border within `rect` using `borderColor` and `strokeWidth`.
//   - When selected, draw resize handles (e.g., 4 corner or 8 handles around the `rect`). If `isCircle` is true, resizing should maintain aspect ratio.
// - `interactionTest(Offset globalPosition)`: Hit-test for handles and shape body.
// - Helper methods for resizing, ensuring circle constraint if `isCircle` is true (if resizing a circle, ensure it remains a circle).

// Properties Popout Panel (UI below top toolbar):
//   **Implemented as a separate widget: `EllipsePropertiesPanel.dart`**
//   Layout: Horizontal arrangement.
//   - Stroke Toggle & Properties:
//     - Icon Button (e.g., border_style icon) to toggle `hasStroke`.
//     - If `hasStroke` is true:
//       - Stroke Color: Small color square (default Colors.black), click for picker. Updates `borderColor`.
//       - Stroke Thickness: Compact slider. Updates `strokeWidth`.
//   - Fill Toggle & Properties:
//     - Icon Button (e.g., format_color_fill icon) to toggle `hasFill`.
//     - If `hasFill` is true:
//       - Fill Color: Small color square (default Colors.transparent), click for picker. Updates `fillColor`.
//       - Opacity (if fill is active): Compact slider (0-100%) for `fillColor`'s alpha.
//   - Shape Mode (If the same tool/drawable handles both Ellipse & Circle):
//     - Segmented button/icon toggle: [图片：椭圆图标], [图片：圆形图标]. This would influence the `isCircle` property or drawing interaction.

// State Management Integration:
// - Drawing interaction: Drag to define `rect`. If drawing in "circle mode", constrain aspect ratio during creation.
// - Resizing handles update `rect`. If `isCircle` is true for the drawable, ensure resizing maintains the circular shape.
// - Property changes from the `EllipsePropertiesPanel` widget update the `EllipseDrawable` and replace it.

// **Development Steps & Checkpoint:**
// 1. Implement `EllipseDrawable` with properties for `rect`, fill/stroke colors, widths, and `hasFill`/`hasStroke` flags.
// 2. Implement `draw` method for both filled and stroked ellipses.
// 3. Implement resize handles and logic. Consider the `isCircle` constraint:
//    - If it's a tool mode, the initial drawing might be constrained.
//    - If it's a property of an existing drawable, resizing should respect it.
// 4. Develop `EllipsePropertiesPanel.dart` for stroke, fill, and optionally shape mode (ellipse/circle).
// 5. Integrate with `PainterController` and state management.
// 6. **Checkpoint:** Test drawing ellipses and circles, resizing (maintaining circle aspect ratio if applicable), property changes (fill, stroke, opacity, shape mode) via the panel.
通用开发说明:独立组件与复用:每个工具 (Drawable) 应在其各自的目录中实现。每个工具的属性选择弹出框应作为独立的 Flutter Widget 实现 (例如, SpeechBubblePropertiesPanel.dart, ArrowPropertiesPanel.dart, 等)。这些面板 widget 将接收当前 Drawable 的属性，并通过回调函数将更改通知回父级（通常是 EditorPage 或管理 PainterController 的地方）。对于 Callout 工具的文本框部分，其属性面板应尽可能复用 SpeechBubblePropertiesPanel 的相关部分（例如，通过组合更小的可复用属性编辑 widget，如 TextPropertiesEditor、StrokePropertiesEditor、FillPropertiesEditor）。AnnotationProvider / PainterProvider:这些 Provider 将管理当前选择的标注工具、默认样式、以及 PainterController 实例。Provider 也将负责管理属性选择弹出框的可见性和状态，将当前选定 Drawable 的数据传递给相应的属性面板 widget。手势处理: 利用 ObjectDrawable 的回调和 interactionTest 实现自定义交互。属性编辑弹出框 (Popout Panel):设计应符合 image_46bc6c.png 的紧凑、图形化风格。内容根据当前激活的工具或选定的 Drawable 动态变化，通过显示相应的属性面板 widget 实现。CleanShotX 行为的精确复制: 保持对对话框边线拖拽、箭头/指示线中点对话框等核心交互的关注。颜色和厚度同步 (Callout Tool): 确保规则得到执行。
