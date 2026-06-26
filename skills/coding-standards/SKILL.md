---
name: coding-standards
description: "优志愿 iOS 编码规范。包含注释规约、代码可读性、SwiftLint 配置、UI布局规范、MARK 分段、屏幕适配、常用控件与工具、Review 检查标准。USE FOR: 代码审查、代码风格校验、SwiftLint 规则、MARK 分段、注释规范、UI布局检查。DO NOT USE FOR: 命名检查、资源命名、路由规范、功能实现、架构设计、依赖管理。"
license: MIT
metadata:
  author: youzy
  version: "2.0.0"
---

# 优志愿 iOS 编码规范

基于项目 Wiki 开发手册和 SwiftLint 配置，定义优志愿 iOS 项目的编码、注释、布局等规范。

> 命名规范见 [naming-conventions skill](../naming-conventions/SKILL.md)
> 项目结构见 [MEMORY.md](../../../../MEMORY.md) 目录结构章节

## 1. 注释规约

> **重要：计划实施阶段，所有新增/修改代码必须添加注释，Review 时作为 P0 检查项**

### 1.1 实施阶段注释检查清单

| 检查项 | 说明 | Review 级别 |
|--------|------|-------------|
| 新增类/结构体/枚举 | 必须添加 `///` 文档注释 | P0 |
| 新增公开方法 | 必须添加完整文档注释（参数+返回值） | P0 |
| 新增私有方法 | 必须添加 `///` 简述注释 | P1 |
| 新增属性 | 必须添加 `///` 简述注释 | P1 |
| 新增 enum case | 必须添加 `///` 说明 | P1 |
| 复杂业务逻辑 | 方法内部添加 `//` 分段注释 | P1 |
| 修改已有逻辑 | 同步更新对应注释 | P0 |

### 1.2 基本规则

| 规则 | 说明 | 级别 |
|------|------|------|
| `//` 或 `///` 后保留一个空格 | `// 注释`、`/// 注释` | 强制 |
| 文档注释使用 `///` 格式 | 每行三个斜杠，用于类/属性/方法声明 | 强制 |
| 方法内部用 `//` 注释 | 多行用 `//` 另起一行 | 强制 |
| 新增代码必须添加注释 | 新增的类/结构体/枚举/属性/方法均须添加 `///` 文档注释；重写方法及 delegate/DataSource 方法除外 | 强制 |
| 所有枚举必须注释 | 说明每个枚举用途 | 强制 |
| 中文注释优先 | 专有名词与关键字保持英文 | 强制 |
| 代码修改时注释同步修改 | — | 强制 |
| 禁止注释代码 | 无用代码直接删除，git 保留历史 | 强制 |
| 注释力求精简准确 | 避免过多过滥 | 强制 |
| 原有注释不得删除或篡改 | 他人编写的注释包含业务上下文与决策记录，严禁删除、改写或"优化措辞"；如原注释有误，在下方追加纠正注释而非覆盖 | 强制 |
| 核心类/方法/属性无注释则补充 | 核心类（ViewController、ViewModel、Manager）、公开方法、关键属性缺少文档注释时必须补齐 | 强制 |

### 1.3 注释格式

| 场景 | 格式 | 示例 |
|------|------|------|
| 类/结构体 | `///` 一句话描述作用 | `/// 院校详情页控制器` |
| 属性 | `///` 简述含义 | `/// 院校代码` |
| 方法 | `///` 描述作用 + 参数/返回值 | 见下方模板 |
| 枚举 case | `///` 说明该值含义 | `/// 本科院校` |
| 方法内部逻辑 | `//` 行内或段注释 | `// 过滤已关闭的选项` |
| MARK 分段 | `// MARK: - 名称` | `// MARK: - LifeCycle` |
| TODO/FIXME | `// TODO: 说明` / `// FIXME: 说明` | `// TODO: 待优化缓存策略` |

### 1.4 方法文档注释模板

```swift
/// 描述方法的作用
///
/// 复杂方法可在此补充逻辑说明
///
/// - Parameter id: 院校 ID
/// - Parameter code: 院校代码
/// - Returns: 是否查询成功
func queryCollege(id: String, code: String) -> Bool {
    // 实现逻辑
}
```

### 1.5 注释示例

```swift
/// 院校详情页控制器
class CollegeDetailController: UIViewController {
    // MARK: - private 属性
    /// 院校代码
    private let code: String
    /// 当前选中的 Tab 页
    private var tabView: College.TabView = .sumUp

    // MARK: - LifeCycle
    /// 初始化院校详情页
    /// - Parameter code: 院校代码
    /// - Parameter tabView: 默认显示的 Tab 页
    init(code: String, tabView: College.TabView = .sumUp) {
        self.code = code
        self.tabView = tabView
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 配置导航栏样式
        setupNavigationBar()
        // 加载院校数据
        loadData()
    }
}

/// 院校类型
enum College {
    /// 院校 Tab 页
    enum TabView: String {
        /// 概况
        case sumUp
        /// 录取
        case admission
        /// 专业
        case major
    }
}
```

### 1.6 注释禁忌

| 禁止 | 正确做法 |
|------|----------|
| `// let a = 0` 注释掉无用代码 | 直接删除，用 git 恢复 |
| `///` 和 `//` 后不加空格 | `/// 注释` 而非 `///注释` |
| 半吊子英文注释 | 用中文注释说清楚，专有名词保持英文 |
| 注释与代码不一致 | 修改代码时同步修改注释 |
| 冗余注释 `// 设置标题为空` → `title = ""` | 好的命名是自解释的，避免废话注释 |

## 2. 代码可读性

### 2.1 SwiftLint 规则

> 基于 `.swiftlint.yml` 配置

| 规则 | 配置值 |
|------|--------|
| 行长度 | 900 |
| 类型体长度 | 警告 300 / 错误 400 |
| 文件长度 | 警告 500 / 错误 1200 |
| 函数体长度 | 警告 100 / 错误 200 |
| 圈复杂度 | 20 |
| 函数参数数量 | 9 |
| 变量名最小长度 | 1 |
| 排除变量名 | id, URL, GlobalAPIKey |

**禁用规则**: force_cast, large_tuple, multiple_closures_with_trailing_closure, nesting, empty_parentheses_with_trailing_closure, type_name, force_try, inclusive_language

**排除目录**: Pods, Carthage, YouZhiYuanTests, YouZhiYuanUITests

> SwiftLint 警告必须处理，不可随意关闭规则

### 2.2 编码规范

| 规则 | 说明 | 级别 |
|------|------|------|
| 空大括号写成 `{}` | 不换行 | 强制 |
| 使用类型推断 | 简单值由编译器推断；复杂值必须显式声明类型 | 强制 |
| 不使用复杂表达式 | 拆分为清晰逻辑 | 强制 |
| 数据模型属性指明类型 | — | 强制 |
| 判 nil 用 `!= nil` | 不用其他方式 | 强制 |
| 数组/字符串判空用 `isEmpty` / `!isEmpty` | 不得使用其他方法 | 强制 |
| 可选代理/闭包直接调用 | 判空后调用冗余，nil 时什么都不会发生 | 强制 |
| 避免使用 `self` | 仅编译器要求时使用（@escaping 闭包或初始化歧义） | 强制 |
| 用 `guard` 代替 `if` 提前返回/拆包 | — | 强制 |
| 类实例传参通过 init | 不使用点语法设置外部参数 | 强制 |
| 正确使用 `var`/`let`/可选值 | 不变用 let，变用 var，可能 nil 用可选 | 强制 |
| 移除空重写函数 | 除仅调用 `super` 外无任何逻辑的 `override` 函数应删除；需要后续补充逻辑时用 `// TODO:` 标注 | 强制 |
| 移除空 `deinit` | 无任何清理逻辑的 `deinit {}` 应删除 | 强制 |

### 2.3 MARK 分段

> 初始化方法命名、命名空间相关规范见 [naming-conventions skill](../naming-conventions/SKILL.md) §7、§6

类文件按以下顺序使用 `// MARK:` 分段：

| 顺序 | MARK | 说明 |
|------|------|------|
| 1 | `// MARK: - subviews` | @IBOutlet、自定义 view |
| 2 | `// MARK: - public 属性` | 外部可访问属性 |
| 3 | `// MARK: - private 属性` | 仅内部使用属性 |
| 4 | `// MARK: - LifeCycle` | 生命周期方法，`deinit` 在最上方 |
| 5 | `// MARK: - Events` | 按钮点击、手势响应、通知回调等事件 |
| 6 | `// MARK: - Public Func` | 外部调用方法 |
| 7 | `// MARK: - Private Func` | 内部方法 |
| 8 | `// MARK: - DataSource` | DataSource 方法（用 extension 实现） |
| 9 | `// MARK: - Delegate` | Delegate 方法（用 extension 实现） |
| 10 | `// MARK: - other configure` | 其他配置、声明 |

> - 1/2/3 分段如果内容不多可忽略
> - DataSource/Delegate 使用 `extension` 实现，集中到一起
> - 单个类最好不超过 600 行，超过时考虑拆分

### 2.4 MARK 分段模板

```swift
import UIKit

/// 视图控制器
class ViewController: UIViewController {
    // MARK: - subviews
    @IBOutlet private weak var imageView: UIImageView!
    private lazy var label = UILabel()
    private lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
        return btn
    }()

    // MARK: - public 属性
    /// 完成闭包
    var complete: (() -> Void)?

    // MARK: - private 属性
    private var id: Int

    // MARK: - LifeCycle
    deinit { 
    	// 释放资源、移除通知监听等
    }

    /// 返回一个新创建的视图控制器
    /// - Parameter id: xx id
    init(id: Int) {
        self.id = id
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - Events
private extension ViewController {
    /// 按钮点击
    @objc func tapAction() {
    }
}

// MARK: - Public Func
extension ViewController {
}

// MARK: - Private Func
private extension ViewController {
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
}

// MARK: - other configure
extension ViewController {
    struct Foo {
    }
}
```

## 3. UI 布局规范

| 规则 | 说明 | 级别 |
|------|------|------|
| 尽量使用 xib 创建 UI | 他人能直观看懂样式 | 强制 |
| 复杂布局必须使用 `UIStackView` | 减少约束数量，易于修改 | 强制 |
| 使用 `Autolayout` 布局 | 非必要不使用 frame 布局 | 强制 |

## 4. 其他规范

| 规则 | 说明 | 级别 |
|------|------|------|
| 不使用 `print` | Release 环境也打印，应使用日志框架 | 强制 |
| 禁止使用 `!` 强制解包 | 可选值不允许 `!` 解包 | 强制 |

## 5. 屏幕适配

| 适配方式 | 说明 |
|----------|------|
| 基准宽度 | 375pt |
| `FONT_RATIO(a:)` | 字号适配 |
| `kAdaptedWith(_:)` | 宽度适配 |
| `SCREEN_RATIO_CEIL(a:)` | 取整适配 |

## 6. 常用控件与工具

### Widget 控件
| 控件 | 用途 |
|------|------|
| Preview | 图片预览（Lantern 封装） |
| InputViewController | 输入框（present 转场，自带背景遮罩） |
| ZEMenuView | 菜单栏 |
| ReadMoreTextView | 展开收起文本 |
| PageController | UIPageViewController 封装，左右滑动切换 |
| DataSource | TableView/CollectionView DataSource 封装 |
| TagListView | 左对齐标签视图 |
| BannerCycleView | 轮播视图 |
| CountingLabel | 数字动画 |

### Utils 工具
| 工具 | 用途 |
|------|------|
| EGDate | 时间转换 |
| IAP | 内购封装（含丢单处理） |
| Payment | 支付宝/微信支付封装 |
| PresentationController | 转场动画 |
| UFile | 图片上传加密 |
| Updater | 版本更新 |
| UrlAnalyze | URL 解析（后台配置跳转规则） |

## 7. 项目扩展方法参考

| 扩展 | 用途 |
|------|------|
| String+Verify | 手机号等验证 |
| UIColor+Extension | 颜色 |
| UIButton+Extension | 按钮 |
| UIViewController+Alert | 便捷弹窗 alert |
| UIImage+Extension | 图片相关 |
| String+Extension | 字符串高度、转换 |
| UIViewController+Alpha | 导航栏透明 |
| UIViewController+Transitions | 转场 |
| UITableView+Extension | cell 快捷注册、占位图 |
| UICollectionView+Extension | cell 快捷注册 |
| Int+Extension | 数字转换 |
| Bundle+Version | 版本号相关 |
| CGSize+Extension | 坐标 |

## 8. Review 检查标准

### 8.1 注释检查

| 级别 | 问题 | 处理方式 |
|------|------|----------|
| P0 | 新增类/公开方法无注释 | 必须修复 |
| P0 | 修改代码后注释未同步更新 | 必须修复 |
| P0 | 存在空重写函数或空 deinit | 必须删除 |
| P1 | 新增私有方法/属性无注释 | 建议修复 |
| P1 | 复杂逻辑无分段注释 | 建议修复 |
| P2 | 注释格式不规范（无空格、英文半吊子） | 可遗留 |

### 8.2 Review 流程

1. **批注阶段**：发现缺少注释直接标注 P0 要求补充
2. **实施阶段**：写完代码先自查注释完整性
3. **Review 阶段**：首查注释，注释不全直接打回
