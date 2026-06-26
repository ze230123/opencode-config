---
name: urouter
description: "优志愿 iOS URouter 路由框架使用及命名规范。包含 Routable 协议实现、路由注册、路由跳转、拦截器链、Port 权限、Path 命名、参数传递、Transition 配置等完整规范。USE FOR: 新增路由、实现 Routable、路由跳转、拦截器开发、路由命名检查、参数传递、权限配置。DO NOT USE FOR: 功能实现、UI布局、非路由相关代码。"
license: MIT
metadata:
  author: youzy
  version: "1.0.0"
---

# URouter 路由框架使用及命名规范

URouter 是优志愿 iOS 项目的核心路由框架，基于 `Routable` 协议 + ObjC Runtime 自动注册实现页面解耦与权限拦截。

## 1. 路由 URL 格式

> **`{scheme}://eagersoft.com:{port}/{模块名称}/{页面属性}?{参数}`**

示例：`youzy://eagersoft.com:300/college/detail?collegeId=123&code=P001`

### 1.1 scheme

| App | scheme |
|-----|--------|
| 优志愿 | youzy |
| 优艺考 | youyk |
| 优生涯 | yousy |

> 初始化在 `Launch.swift`：`Router.initialize(className: AppDelegate.self, scheme: "youzy", interceptors: interceptors)`

### 1.2 port（权限控制）

| port 常量 | 值 | 含义 |
|-----------|------|------|
| `.none` | 200 | 无限制 |
| `.login` | 300 | 需要登录 |
| `.gaosan` | 310 | 需要高三用户 + 高考版开启 |
| `.gkScoreAlert` | 320 | 高三 + 高考版 + 成绩弹窗 |
| `.score` | 400 | 需要成绩数据 |
| `.gkArtScoreAlert` | 401 | 艺术高考成绩弹窗 |
| `.vip` | 403 | 需要 VIP（框架内置） |
| `.artScore` | 410 | 需要艺考分数 |
| `.udzScore` | 500 | 需要单招分数 |
| `.puVip` | 2403 | 需要家长学园 VIP |

> Port 扩展定义在 `Launch.swift:153-166`

### 1.3 Path 命名规范

| 规则 | 格式 | 示例 |
|------|------|------|
| 模块首页 | `/{模块名}/index` | `/college/index` |
| 模块列表 | `/{模块名}/list` | `/college/list` |
| 模块详情 | `/{模块名}/detail` | `/college/detail` |
| 模块功能页 | `/{模块名}/{功能}` | `/smartFill/engine` |
| 兼容别名 | 同一 VC 可注册多个 Path | `/article/detail` + `/news/detail` |

**Path 命名要点**：
- 全小写，使用驼峰分隔多词：`/admissionProbability/index`
- 与路由规范中的模块名称保持一致
- 一个 VC 可注册多个 Path（`Set<Router.Path>`），用于兼容旧 URL

### 1.4 页面属性

| 属性 | 名称 | 说明 |
|------|------|------|
| 首页 | `index` | 模块入口页 |
| 列表页 | `list` | 列表浏览页 |
| 详情页 | `detail` | 详情展示页 |

## 2. Routable 协议实现

所有需要路由跳转的 ViewController 必须实现 `Routable` 协议。使用 `extension` 在文件末尾实现。

### 2.1 协议定义（框架内置）

```swift
public protocol Routable: UIViewController {
    static var path: Set<Router.Path> { get }
    static var port: Router.Port { get }
    static var transition: Router.Transition { get }
    static func creat(with parameters: [String: String]?) -> UIViewController?
}
```

### 2.2 实现模板

```swift
// MARK: - Routable
extension FooViewController: Routable {
    static var path: Set<Router.Path> {
        return [
            Router.Path(rawValue: "/foo/detail")
        ]
    }

    static var port: Router.Port {
        return .none
    }

    static var transition: Router.Transition {
        return .push(animated: true)
    }

    static func creat(with parameters: [String: String]?) -> UIViewController? {
        guard let id = parameters?["id"] else { return nil }
        let vc = FooViewController(id: id)
        vc.fromSource = parameters?["fromSource"]
        return vc
    }
}
```

### 2.3 各属性填写规范

| 属性 | 规范 |
|------|------|
| `path` | 按 1.3 命名规范，必须包含至少一个 Path |
| `port` | 根据页面权限选择，无限制用 `.none`，需登录用 `.login`，需成绩用 `.score` 等 |
| `transition` | 标准页面用 `.push(animated: true)`，弹窗/模态用 `.present(animated: true)` |
| `creat(with:)` | 解析参数创建 VC，参数不足时返回 `nil` |

### 2.4 creat 方法规范

| 规则 | 说明 | 级别 |
|------|------|------|
| 必选参数缺失时返回 `nil` | 用 `guard` 检查必要参数 | 强制 |
| 可选参数用 `parameters?["key"]` 直接取值 | 可能为 nil，赋值时自然处理 | 强制 |
| `fromSource` 参数统一传递 | 用于埋点追踪来源 | 推荐 |
| 参数从 `[String: String]?` 解析 | 所有值都是 String，需自行转换类型 | 强制 |
| 复杂参数使用 `Parameter` 结构体 + Codable | 见 2.5 节 | 推荐 |

### 2.5 复杂参数模式（Parameter 结构体）

当 VC 需要多个关联参数时，推荐定义 `Parameter` 结构体：

```swift
extension VipViewController: Routable {
    struct Parameter: Codable {
        var tab: Tab?
        var subTab: SubTab?

        static let zyVip = Parameter(tab: .zy, subTab: .intro)
        static let artVip = Parameter(tab: .art, subTab: .intro)

        func toParameters() -> [String: String] {
            guard let data = try? JSONEncoder().encode(self),
                  let item = try? JSONSerialization.jsonObject(with: data) as? [String: String]
            else { return [:] }
            return item
        }
    }

    static func creat(with parameters: [String: String]?) -> UIViewController? {
        guard let parameters else {
            return VipViewController(action: .view)
        }
        if let data = try? JSONSerialization.data(withJSONObject: parameters),
           let item = try? JSONDecoder().decode(Parameter.self, from: data) {
            return VipViewController(action: item.tab?.action ?? .view, subTab: item.subTab ?? .intro)
        }
        return nil
    }
}
```

> 调用时：`Router.open(action: .class(VipViewController.self), parameters: VipViewController.Parameter.artVip.toParameters())`

## 3. 路由跳转方式

### 3.1 按类名跳转（推荐，最常用）

```swift
// 无参数
Router.open(action: .class(LoginViewController.self))

// 带参数
Router.open(action: .class(NewsDetailViewController.self), parameters: ["numId": id])

// 指定来源 VC
Router.open(action: .class(CollegeDetailController.self), parameters: ["code": code], form: self)
```

> **推荐优先使用 `.class` 方式**，编译期类型安全，重构时 Xcode 可追踪。

### 3.2 按 URL 跳转

```swift
Router.open(action: .url("youzy://eagersoft.com:200/college/detail?collegeId=123"))
```

> 适用于 H5 页面跳转原生、推送跳转、后台配置跳转等动态场景。

### 3.3 系统 Scheme

```swift
// 拨打电话
Router.open(action: .scheme(.tel("10086")))

// 打开系统设置
Router.open(action: .scheme(.setting))

// 打开 App Store 或其他 App
Router.open(action: .scheme(.app("https://apps.apple.com/app/id123")))
```

### 3.4 构造路由 URL（拦截器中使用）

```swift
// 无参数
let url = try Router.url(for: GaokaoTipsAlert.self)

// 带参数
let url = try Router.url(for: LoginViewController.self, parameters: [Router.Key.routerUrl: originalURL])
```

## 4. Transition 配置

| 场景 | 配置 | 说明 |
|------|------|------|
| 标准页面跳转 | `.push(animated: true)` | 大多数页面 |
| 模态弹窗 | `.present(animated: true)` | VIP页、支付、活动弹窗 |
| 静默模态 | `.present(animated: false)` | 微信跳转、小程序提示 |
| 带 NavigationController 的 present | 在 `creat` 中包装 `PresentNavigationController` | VIP 页等需导航的模态页 |

```swift
// present 且需要导航栏的场景
static func creat(with parameters: [String: String]?) -> UIViewController? {
    let vc = VipViewController(action: .view)
    return PresentNavigationController(root: vc)
}
```

## 5. 拦截器链

拦截器在路由跳转前按顺序执行，可拦截请求并重定向到其他页面。

### 5.1 注册顺序（Launch.swift）

```swift
let interceptors: [UInterceptor] = [
    LoginInterceptor(),           // 1. 登录拦截
    GaoSanInterceptor(),          // 2. 高三权限拦截
    GKScoreAlertInterceptor(),    // 3. 高考成绩弹窗拦截
    ArtGKScoreAlertInterceptor(), // 4. 艺术高考成绩弹窗拦截
    ScoreInterceptor(),           // 5. 成绩拦截
    ArtScoreInterceptor(),        // 6. 艺考分数拦截
    UDZScoreInterceptor(),        // 7. 单招分数拦截
    PUVipInterceptor()            // 8. 家长学园VIP拦截
]
Router.initialize(className: AppDelegate.self, scheme: "youzy", interceptors: interceptors)
```

### 5.2 拦截器协议

```swift
public protocol UInterceptor {
    func intercept(url: URL, scheme: String) throws -> URL
}
```

- 返回原 URL：放行，继续下一个拦截器
- 返回新 URL：重定向，后续拦截器基于新 URL 继续执行
- 抛出错误：终止路由

### 5.3 自定义拦截器模板

```swift
struct FooInterceptor: UInterceptor {
    func intercept(url: URL, scheme: String) throws -> URL {
        guard let value = url.port else { return url }
        let port = Router.Port(rawValue: value)
        // 仅拦截特定 Port
        guard port == .foo else { return url }
        // 判断条件
        guard App.foo.isRequired else { return url }
        // 重定向
        return try Router.url(for: FooTipsViewController.self)
    }
}
```

### 5.4 拦截器开发规范

| 规则 | 说明 | 级别 |
|------|------|------|
| 拦截器必须是 `struct` | 轻量无状态 | 强制 |
| 先判断 port 是否匹配 | 不匹配直接返回原 URL，避免不必要的处理 | 强制 |
| 使用 `guard` 尽早返回 | 保持逻辑清晰 | 强制 |
| 重定向时用 `Router.url(for:)` | 保持 URL 格式统一 | 强制 |
| 新增拦截器需注册到 `Launch.swift` | 按优先级顺序添加 | 强制 |

## 6. 参数传递规范

### 6.1 常用参数 Key

| Key | 用途 | 示例 |
|-----|------|------|
| `id` / `numId` | 内容 ID | 新闻、院校、专业 ID |
| `collegeId` | 院校 ID | 院校详情页 |
| `code` | 院校代码 | 院校详情页（按代码查询） |
| `url` | Web 页面 URL | WebView 跳转 |
| `fromSource` | 来源追踪 | 埋点统计 |
| `type` | 类型区分 | Tab 页切换 |
| `channelId` | 直播频道 ID | 直播页 |
| `subPage` | 子页面索引 | 详情页内 Tab |
| `Router.Key.routerUrl` | 拦截后回跳 URL | 登录后继续原跳转 |

### 6.2 参数辅助方法

**`asURL()`**（定义在 `Router+Extension.swift`）：
将包含 `url` key 的字典转为 URL，剩余 key 作为 query 参数拼接。

```swift
let params: [String: String] = [
    "url": "youzy://eagersoft.com:200/college/detail",
    "collegeId": "123"
]
let url = params.asURL()
// youzy://eagersoft.com:200/college/detail?collegeId=123
```

**`asMiniParameters()`**：
将 `path` key 与其他参数合并，用于小程序跳转。

### 6.3 参数传递规范

| 规则 | 说明 | 级别 |
|------|------|------|
| 参数值统一为 `String` 类型 | 路由参数类型为 `[String: String]?` | 强制 |
| 数值参数需在 `creat` 中转换 | `parameters?["key"]?.intValue` | 强制 |
| 使用 `guard` 验证必选参数 | 缺失返回 `nil` | 强制 |
| 复杂参数用 `Parameter` 结构体 + Codable 序列化 | 保持类型安全 | 推荐 |
| `fromSource` 参数统一传递 | 便于来源追踪 | 推荐 |

## 7. 自动注册机制

URouter 使用 ObjC Runtime 自动发现并注册所有 `Routable` 实现类：

1. `Router.initialize(className:)` 传入 `AppDelegate.self`
2. 框架通过 `class_getImageName` 获取主程序二进制镜像
3. 遍历镜像中所有类，筛选符合 `Routable` 的类
4. 读取每个类的 `path` 集合，建立 `Path -> 类名` 映射表

> **无需手动注册路由**，只需实现 `Routable` 协议即可自动注册。

### 注册前提条件

| 条件 | 说明 |
|------|------|
| VC 必须继承 `UIViewController` | `Routable` 协议约束 |
| VC 类必须被编译到主程序中 | SPM 框架中的类不会被自动扫描 |
| `path` 不得重复 | 多个 VC 注册同一 Path 会导致冲突 |

## 8. 完整示例

### 8.1 新增一个需要登录的详情页路由

```swift
// MARK: - Routable
extension ScoreReportViewController: Routable {
    static var path: Set<Router.Path> {
        return [
            Router.Path(rawValue: "/score/report")
        ]
    }

    static var port: Router.Port {
        return .login
    }

    static var transition: Router.Transition {
        return .push(animated: true)
    }

    static func creat(with parameters: [String: String]?) -> UIViewController? {
        guard let id = parameters?["id"] else { return nil }
        let vc = ScoreReportViewController(id: id)
        vc.fromSource = parameters?["fromSource"]
        return vc
    }
}
```

### 8.2 调用路由

```swift
// 按类名跳转（推荐）
Router.open(action: .class(ScoreReportViewController.self), parameters: ["id": "123"])

// 按 URL 跳转（H5/推送场景）
Router.open(action: .url("youzy://eagersoft.com:300/score/report?id=123"))
```

### 8.3 新增一个模态弹窗路由

```swift
extension ActivityAlertViewController: Routable {
    static var path: Set<Router.Path> {
        return [
            Router.Path(rawValue: "/activity/alert")
        ]
    }

    static var port: Router.Port {
        return .none
    }

    static var transition: Router.Transition {
        return .present(animated: true)
    }

    static func creat(with parameters: [String: String]?) -> UIViewController? {
        let vc = ActivityAlertViewController()
        vc.urlString = parameters?["url"]
        return vc
    }
}
```

## 9. 注意事项

| 事项 | 说明 |
|------|------|
| Path 不可重复 | 两个 VC 注册同一 Path 会冲突，框架取后注册者 |
| `.class` 优先于 `.url` | 类名跳转编译期安全，URL 跳转仅用于动态场景 |
| 拦截器顺序敏感 | 登录拦截器必须在最前面，否则其他拦截器可能读取不到用户状态 |
| `creat` 拼写 | 框架使用 `creat`（非 `create`），实现时注意拼写 |
| present 页面需导航栏时 | 在 `creat` 中包装 `PresentNavigationController` |
| 框架版本 | URouter 0.3.4，位于内部 GitLab |
