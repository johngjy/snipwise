# 请求：为跨平台截图编辑软件设计 Riverpod v2 状态管理结构 (v4 - 最终版)

## 目标

为一款使用 Flutter 开发的、面向 macOS 和 Windows 的桌面截图编辑软件，设计一个清晰、可扩展且遵循 **Riverpod v2 最佳实践**（优先使用 Notifier/AsyncNotifier/StateNotifier 与不可变状态）的状态管理结构。该结构需要管理编辑器的核心状态，包括画布尺寸、截图数据、缩放、背景（Wallpaper）及其动态调整，并满足以下更新后的详细功能需求。

## 核心功能与状态管理需求

请基于 Riverpod 设计状态管理方案，覆盖以下功能点，并细化所需的状态变量和 Notifier 逻辑：

1.  **编辑器窗口与画布尺寸管理:**
    *   **状态类型:** 所有表示尺寸的状态变量（如 `minCanvasSize`, `originalImageSize`, `availableScreenSize`, `editorWindowSize`, `currentCanvasViewSize` 等）应使用 **`Size` 类型**。逻辑中可以通过 `.width` 和 `.height` 属性独立访问和计算。
    *   **全局最小画布尺寸 (`minCanvasSize`):** 定义 `Provider<Size>`，记录画布内容的最小逻辑尺寸（例如 `const Size(900, 500)`）。
    *   **工具栏高度 (`toolbarHeights`):** 状态或配置，包含顶部和底部工具栏的高度 (`top`, `bottom`, `total`)。
    *   **全局最小窗口基础尺寸 (`minWindowBaseSize`):** 派生值或常量，`height` = `minCanvasSize.height` + `toolbarHeights.total`, `width` = `minCanvasSize.width`。
    *   **可用屏幕尺寸 (`availableScreenSize`):** `AsyncNotifierProvider` 或 `FutureProvider` 提供 `Size?`，表示可用工作区大小。
    *   **可用最大画布尺寸 (`maxCanvasSize`):** 派生值。`height` = `availableScreenSize.height` - 20 - `toolbarHeights.total`，`width` = `availableScreenSize.width` - 20 (这里的 20 是窗口距离屏幕边缘的固定视觉边距)。
    *   **新截图加载时的布局逻辑 (`calculateInitialLayout`):**
        *   **获取截图数据:**
            *   **原始截图尺寸 (`originalImageSize: Size?`):** 存储截图原始像素尺寸。
            *   **截图数据 (`currentImageData: dynamic`):** 存储图像数据。
            *   **裁剪更新 (`cropImage`):** 操作更新 `originalImageSize` 和 `currentImageData`。
        *   **定义视觉边距:** `visualPadding = 40.0`。内容所需空间计算时通常在宽高上各加 `visualPadding * 2`。
        *   **计算画布和缩放 (独立判断宽高):**
            *   **宽度判断 (`targetCanvasWidth`):**
                *   If `originalImageSize.width + visualPadding * 2 < minCanvasSize.width`: `targetCanvasWidth = minCanvasSize.width`.
                *   If `originalImageSize.width + visualPadding * 2 >= minCanvasSize.width` AND `<= maxCanvasSize.width`: `targetCanvasWidth = originalImageSize.width + visualPadding * 2`.
                *   If `originalImageSize.width + visualPadding * 2 > maxCanvasSize.width`: `targetCanvasWidth = maxCanvasSize.width-visualPadding * 2`. 计算 X 方向所需的 `scaleFactorX = （maxCanvasSize.width-visualPadding * 2） / originalImageSize.width `.
            *   **高度判断 (`targetCanvasHeight`):**
                *   If `originalImageSize.height + visualPadding * 2 < minCanvasSize.height`: `targetCanvasHeight = minCanvasSize.height`.
                *   If `originalImageSize.height + visualPadding * 2 >= minCanvasSize.height` AND `<= maxCanvasSize.height`: `targetCanvasHeight = originalImageSize.height + visualPadding * 2`.
                *   If `originalImageSize.height + visualPadding * 2 > maxCanvasSize.height`: `targetCanvasHeight = maxCanvasSize.height-visualPadding * 2`. 计算 Y 方向所需的 `scaleFactorY = （maxCanvasSize.height-visualPadding * 2） / originalImageSize.height`.
            *   **最终初始缩放 (`initialScaleFactor`):** 取 `scaleFactorX` 和 `scaleFactorY` 中的**较小者** (如果两者都计算了的话，默认为 1.0)。
            *   **当前画布视觉尺寸 (`currentCanvasViewSize`):** 使用计算出的 `targetCanvasWidth` 和 `targetCanvasHeight` 设置 `Size(targetCanvasWidth, targetCanvasHeight)`。
        *   **设置初始状态:** 更新 `currentCanvasViewSize` 和 `scaleFactor` (设置为 `initialScaleFactor`)。
    *   **编辑器窗口尺寸 (`editorWindowSize`):**
        *   **自动计算:** 窗口尺寸根据当前的 `currentCanvasViewSize`, `toolbarHeights`, 以及侧边栏状态 (`isHistoryPanelOpen` 等) 计算得出。仅在加载新图片、Wallpaper 边距变化导致 `currentCanvasViewSize` 变化时，或侧边栏/工具栏显隐变化时，**程序自动**触发窗口尺寸调整。
        *   **手动调整:** 用户可以通过拖拽窗口边框**手动调整 `editorWindowSize`**。
            *   **状态更新:** 手动调整后，需要有一个机制（例如通过 `window_manager` 监听事件）将新的窗口尺寸通知给 `LayoutNotifier`。
            *   **内部响应 (`handleManualResize`):** `LayoutNotifier` 接收到手动调整的尺寸后：1) 更新 `editorWindowSize` 状态；2) **立即根据新窗口尺寸和已知工具栏/侧边栏尺寸重新计算并更新 `currentCanvasViewSize` 状态**；3) 设置 `userHasManuallyResized = true` 标记。
            *   **内容不变:** **截图内容（及其当前的 `scaleFactor` 和 `canvasOffset`）保持不变，并始终在 `currentCanvasViewSize` 内居中显示。** 如果手动缩小窗口导致内容（按当前缩放）超出 `currentCanvasViewSize`，则应**自动启用滚动条**。手动调整窗口大小**不会**触发内容的自动缩放。
    *   **后续缩放:** 用户后续通过 UI **手动缩放** (`scaleFactor` 变化) **不影响**当前的 `editorWindowSize`。

2.  **背景 (Wallpaper) 管理:**
    *   **Wallpaper 启用状态 (`isWallpaperEnabled: bool`)**: 是否启用。
    *   **Wallpaper 颜色 (`wallpaperColor: Color`)**: 用户可配置，默认为白色。
    *   **Wallpaper 边距 (`wallpaperPadding: EdgeInsets`)**: 用户可配置，默认为 `EdgeInsets.zero`。**重要:** 此边距定义在**未缩放**的 `originalImageSize` 周围，指定内容的逻辑边界。在画布上显示时，**整个内容区域（图像 + Padding）会一起根据 `scaleFactor` 进行缩放**。
    *   **Wallpaper 编辑工具:** (UI 需求，状态管理需支持其值的修改)。
    *   **Wallpaper 自动扩展:** **核心逻辑**: 当添加或修改**标注**导致其边界超出当前 `wallpaperPadding` 区域时，**自动计算并增加**相应的 `wallpaperPadding` 值。
        *   **触发布局重算:** Padding 值的变化会通知 `LayoutNotifier` 重新评估内容所需空间 (`recalculateLayoutForNewContent` 或类似方法，传入新的 `originalImageSize` 和**新的 `wallpaperPadding`**)。
        *   **处理溢出 (健壮性):** 在 `LayoutNotifier` 的布局重算逻辑中，如果因为 Padding 增加导致计算出的新内容所需尺寸（在当前 `scaleFactor` 下）大于 `maxCanvasSize`，则不仅要将 `currentCanvasViewSize` 限制为 `maxCanvasSize`，还要**重新计算并应用一个新的、更小的 `scaleFactor`** 到 `CanvasTransformNotifier`，以确保扩展后的内容完整可见。

3.  **缩放与视图管理:**
    *   **缩放比例 (`scaleFactor: double`)**: 当前缩放比例。初始值由加载逻辑确定。
    *   **画布偏移量 (`canvasOffset: Offset`)**: 画布内容的平移量。
    *   **滚动条启用 (`showScrollbarsProvider` - 推荐):** 创建一个独立的 `Provider<bool>` 来管理滚动条的可见性。
        *   **依赖:** `scaleFactor`, `canvasOffset`, `originalImageSize`, `wallpaperPadding`, `currentCanvasViewSize`.
        *   **逻辑:** 当 ( `originalImageSize` + `wallpaperPadding` 应用 `scaleFactor` 后得到的总内容尺寸 ) 的宽度或高度 **大于** `currentCanvasViewSize` 的宽度或高度时，或者当 `canvasOffset` 导致内容移出可视边界时，返回 `true`。

4.  **编辑器状态重置:**
    *   当触发**重新截图**时，重置以下状态：
        *   `currentImageData`, `originalImageSize` -> `null`
        *   `scaleFactor` -> `1.0`
        *   `canvasOffset` -> `Offset.zero`
        *   `wallpaperColor` -> `defaultColor`
        *   `wallpaperPadding` -> `EdgeInsets.zero`
        *   `annotations` -> `[]`
        *   触发 `LayoutNotifier.resetLayout()`。

5.  **标注数据管理:**
    *   管理 `annotations: List<EditorObject>` (不可变列表)。
    *   管理 `selectedAnnotationId: String?`。
    *   管理 `currentTool: EditorTool`。
    *   **方法:** `add/update/removeAnnotation` 方法内部需要计算标注总边界，并判断是否需要调用 `EditorStateNotifier` 来更新 `wallpaperPadding`。

6.  **侧边栏/面板状态:**
    *   管理 `isHistoryPanelOpen: bool` 等。其变化会通知 `LayoutNotifier` 重新计算布局。

## Riverpod v2 结构设计建议

使用 **NotifierProvider** (或 AsyncNotifierProvider) 配合 **不可变状态类**。

1.  **`LayoutNotifier` (管理窗口和画布布局):**
    *   **状态类 (`LayoutState`):**
        *   `availableScreenSize: Size?`
        *   `minCanvasSize: Size` (来自 Provider)
        *   `editorWindowSize: Size`
        *   `currentCanvasViewSize: Size`
        *   `isHistoryPanelOpen: bool`
        *   `topToolbarHeight: double`
        *   `bottomToolbarHeight: double`
        *   `userHasManuallyResized: bool` (标记是否被用户拖拽过)
    *   **方法:**
        *   `initialize(screenSize)`: 获取屏幕尺寸。
        *   `toggleHistoryPanel()`: 切换状态，调用 `_recalculateLayoutBasedOnCurrentContent()`。
        *   `updateToolbarHeights(...)`: 更新高度，调用 `_recalculateLayoutBasedOnCurrentContent()`。
        *   `handleManualResize(Size newWindowSize)`: 接收手动调整的窗口大小。更新 `editorWindowSize`；**立即重新计算并更新 `currentCanvasViewSize`**；设置 `userHasManuallyResized = true`。
        *   `recalculateLayoutForNewContent(Size originalImageSize, EdgeInsets currentPadding)`: **核心初始布局计算**。执行第 1 点中的详细宽高判断逻辑，计算出目标 `currentCanvasViewSize` 和 `initialScaleFactor`。根据计算结果更新状态 (包括 `editorWindowSize`)，并设置 `userHasManuallyResized = false`。返回 `initialScaleFactor`。
        *   `_recalculateLayoutBasedOnCurrentContent()`: (私有或内部调用) 当 Padding 改变或侧边栏开关时，使用当前的 `originalImageSize` 和 `wallpaperPadding` 重新执行类似 `recalculateLayoutForNewContent` 的逻辑，但可能需要考虑当前的 `scaleFactor` 并**决定是否需要调整 `scaleFactor`**（如 Wallpaper 扩展超出 `maxCanvasSize` 时）。
        *   `resetLayout()`: 重置为基于 `minWindowBaseSize` 的布局。

2.  **`EditorStateNotifier` (管理核心编辑状态):**
    *   **状态类 (`EditorState`):**
        *   `originalImageSize: Size?`
        *   `currentImageData: dynamic`
        *   `wallpaperColor: Color`
        *   `wallpaperPadding: EdgeInsets`
        *   `isLoading: bool`
    *   **方法:**
        *   `loadScreenshot(data, size)`: 设置 `currentImageData`, `originalImageSize`。调用 `ref.read(layoutProvider.notifier).recalculateLayoutForNewContent(size, state.wallpaperPadding)` 获取 `initialScaleFactor`。调用 `ref.read(canvasTransformProvider.notifier).setInitialScale(initialScaleFactor)`。
        *   `cropImage(rect)`: 更新 `originalImageSize`, `currentImageData`。**调用 `LayoutNotifier` 重新计算布局**。
        *   `updateWallpaperColor(color)`
        *   `updateWallpaperPadding(padding)`: 更新 `wallpaperPadding`。**调用 `LayoutNotifier` 重新计算布局**（使用新的 padding 和当前的 `originalImageSize`）。
        *   `resetEditorState()`: 重置状态，调用 `LayoutNotifier.resetLayout()`, `CanvasTransformNotifier.resetTransform()`, `AnnotationNotifier.clearAnnotations()`。

3.  **`CanvasTransformNotifier` (管理画布变换):**
    *   **状态类 (`CanvasTransformState`):**
        *   `scaleFactor: double`
        *   `canvasOffset: Offset`
    *   **方法:**
        *   `setInitialScale(scale)`
        *   `updateZoom(newScale, focalPoint)`
        *   `updateOffset(delta)`
        *   `resetTransform()`

4.  **`AnnotationNotifier` (管理标注):**
    *   **状态类 (`AnnotationState`):**
        *   `annotations: List<EditorObject>` (使用 `package:fast_immutable_collections` 的 `IList` 更佳)
        *   `selectedAnnotationId: String?`
        *   `currentTool: EditorTool`
    *   **方法:**
        *   `add/update/removeAnnotation`: 计算标注总边界，如果超出当前 `wallpaperPadding`，计算所需的新 padding，然后调用 `ref.read(editorStateProvider.notifier).updateWallpaperPadding(newPadding)`。
        *   `selectAnnotation(id)`
        *   `setCurrentTool(tool)`
        *   `clearAnnotations()`

5.  **Provider 组合与依赖:**
    *   Notifier 间通过 `ref.read` 调用方法。
    *   UI 监听状态。
    *   **滚动条Provider:** 推荐创建 `showScrollbarsProvider = Provider<bool>((ref) { ... });` 它 `watch` `ref.watch(canvasTransformProvider)`, `ref.watch(editorStateProvider.select((s) => s.originalImageSize))`, `ref.watch(editorStateProvider.select((s) => s.wallpaperPadding))`, 和 `ref.watch(layoutProvider.select((s) => s.currentCanvasViewSize))` 来动态计算是否显示滚动条。
    *   **窗口大小调整:** UI 层监听 `LayoutState.editorWindowSize` 的变化，并调用 `window_manager.setSize()`。同时，UI 层需要监听窗口的 `onResize` 事件，并将新尺寸通过 `ref.read(layoutProvider.notifier).handleManualResize()` 反馈给状态系统。

## 期望的输出

请提供一份 Markdown 格式的详细设计文档，包含：

*   推荐的 Riverpod Provider 列表 (NotifierProvider 等) 及其主要职责。
*   核心状态类 (`LayoutState`, `EditorState`, `CanvasTransformState`, `AnnotationState`) 的关键数据结构定义（强调不可变性和使用 `Size` 类型）。
*   关键 Notifier 的重要方法签名和核心逻辑描述（特别是窗口尺寸计算、初始自动缩放、手动窗口调整处理及其与 `currentCanvasViewSize` 的同步、Wallpaper 自动扩展逻辑及其可能触发的缩放调整）。
*   明确推荐独立的 `showScrollbarsProvider` 及其依赖和逻辑。
*   简要说明 UI 层如何响应状态变化（特别是窗口尺寸的双向同步和滚动条的条件性渲染）。
*   指出状态管理设计中的关键点或潜在挑战（如状态依赖关系、性能优化、手动与自动调整的协调、复杂布局计算的准确性）。

务必确保设计能够清晰地映射回上面更新后的功能需求。