---
name: os-logger
description: "Apple os.Logger 日志 API 使用指南。涵盖 Logger 创建与配置、隐私控制、Subsystem/Category 设计、日志查看与过滤、OSLogStore 编程访问、测试中日志捕获、print/os_log 迁移。USE FOR: 添加系统日志、配置 subsystem/category、编写隐私标注日志、日志测试、print 替换、os_log 迁移。DO NOT USE FOR: 路由规范、命名检查、UI布局、功能实现。"
license: MIT
metadata:
  author: youzy
  version: "2.0.0"
---

# os.Logger 使用指南

`os.Logger` 是 Apple 系统框架 `os` 模块提供的原生日志 API（iOS 14+ / macOS 11+），无需第三方依赖，底层走 `os_log`，自动获得性能优化和系统级日志管理。

> 项目编码规范禁止使用 `print`（Release 环境也打印），应使用 `os.Logger` 替代。详见 [coding-standards skill](../coding-standards/SKILL.md) §4
> 命名规范见 [naming-conventions skill](../naming-conventions/SKILL.md)

## 何时写日志

- 在函数和重要任务的开始与结束时记录
- 在有趣的事件发生时记录
- 在重大错误发生时记录
- 在重要或罕见的代码路径上记录（例如 rarely taken paths）
- 在多步骤任务的每一步之前记录

## 导入与创建

```swift
import os
```

```swift
let logger = Logger(subsystem: "com.eagersoft.youzy", category: "Network")
```

### 默认 Logger

无需指定 subsystem/category 时，使用默认 Logger，适合不需要按模块过滤的日志：

```swift
let logger = Logger()
logger.info("这是一条默认日志")
```

> 默认 Logger 使用系统默认的 subsystem 和 category，无法按模块过滤。推荐在正式项目中始终指定 subsystem/category。

### 静态属性存储（推荐）

每个模块/类声明静态 Logger，避免重复创建：

```swift
private static let logger = Logger(subsystem: "com.eagersoft.youzy", category: "Network")

func fetchData() {
    Self.logger.debug("开始请求")
}
```

全局 Logger 常量：

```swift
enum AppLog {
    static let network = Logger(subsystem: "com.eagersoft.youzy", category: "Network")
    static let database = Logger(subsystem: "com.eagersoft.youzy", category: "Database")
    static let ui = Logger(subsystem: "com.eagersoft.youzy", category: "UI")
}
```

## 日志级别（5 级）

| 级别 | 方法 | 用途 | 持久化行为 |
|------|------|------|-----------|
| `.debug` | `logger.debug()` | 开发调试信息 | 仅存于内存，不写入磁盘 |
| `.info` | `logger.info()` | 有用的运行时信息 | 仅在使用 `log` 命令行工具收集时写入磁盘 |
| `.default`（Notice） | `logger.log(level:.default)` | 默认级别，排障必需信息 | 持久化到磁盘（有存储上限） |
| `.error` | `logger.error()` | 错误条件 | 持久化到磁盘（有存储上限） |
| `.fault` | `logger.fault()` | 严重故障 | 持久化到磁盘（有存储上限） |

级别由低到高：debug < info < default（notice） < error < fault

> Debug 级别仅存于内存，开销极低。Fault 等高级别因需写入磁盘并捕获额外上下文，开销较高。
> 可通过工具或自定义配置文件覆盖默认持久化行为，详见 [Customizing Logging Behavior While Debugging](https://developer.apple.com/documentation/os/customizing-logging-behavior-while-debugging)。

```swift
logger.debug("详细调试信息")
logger.info("请求完成")
logger.error("请求失败")
logger.fault("数据损坏，无法恢复")
```

### 级别过滤

不在代码中控制级别过滤。通过系统工具配置：

- **Console.app**：按 subsystem/category/级别过滤
- **命令行**：`log stream --predicate 'subsystem == "com.eagersoft.youzy"' --level debug`
- **Xcode**：Console 中选择日志级别

Debug 级别在 Release 构建中默认不输出，无需代码级过滤。

## 字符串插值

`os.Logger` 原生支持字符串插值，编译器自动优化为惰性求值（日志未输出时不会求值）：

```swift
logger.info("用户 \(userId) 登录成功，耗时 \(duration)s")
logger.debug("响应数据：\(response)")
```

> 与 `os_log` 的 `%{public}s` 格式不同，`os.Logger` 直接用字符串插值，编译器自动处理。

## 插值格式化

`os.Logger` 支持对插值变量应用自定义格式化，使日志更可读。

### 对齐

指定列宽和对齐方式：

```swift
logger.debug("Shape: \(shapeType, align: .right(columns: 15)) Color: \(selectedColor, align: .left(columns: 10))")
```

### 整数格式化

```swift
// 十进制（默认）、十六进制、八进制
logger.debug("值: \(value, format: .hex)")
logger.debug("值: \(value, format: .octal)")
```

| 格式 | 类型 | 说明 |
|------|------|------|
| `.decimal` | `OSLogIntegerFormatting` | 十进制（默认） |
| `.hex` | `OSLogIntegerFormatting` | 十六进制 |
| `.octal` | `OSLogIntegerFormatting` | 八进制 |

### 浮点数格式化

```swift
// 科学计数法，精度 10 位，正数显示 + 号
logger.info("大数: \(bigNumber, format: .exponential(precision: 10, explicitPositiveSign: true, uppercase: false))")
```

| 格式 | 类型 | 说明 |
|------|------|------|
| `.fixed` | `OSLogFloatFormatting` | 定点表示 |
| `.hex` | `OSLogFloatFormatting` | 十六进制 |
| `.exponential` | `OSLogFloatFormatting` | 科学计数法 |
| `.hybrid` | `OSLogFloatFormatting` | 混合表示 |

可指定 `precision`（小数位数）、`explicitPositiveSign`（正数显式加 `+`）、`uppercase`（大写 E）。

### 布尔格式化

```swift
logger.debug("答案是 \(theAnswer, format: .answer)")
// 输出: 答案是 yes / no（而非 true / false）
```

| 格式 | 类型 | 说明 |
|------|------|------|
| 默认 | - | true / false |
| `.answer` | `OSLogBoolFormat` | yes / no |

### Objective-C 内置格式说明符

在 Objective-C 中，统一日志系统提供以下自定义格式说明符（Swift 中通过 `format:` 参数使用对应类型）：

| 值类型 | 说明符 | 示例输出 |
|--------|--------|---------|
| `time_t` | `%{time_t}d` | `2016-01-12 19:41:37` |
| `timeval` | `%{timeval}.*P` | `2016-01-12 19:41:37.774236` |
| `timespec` | `%{timespec}.*P` | `2016-01-12 19:41:37.2382382823` |
| `errno` | `%{errno}d` | `Broken pipe` |
| `iec-bytes` | `%{iec-bytes}d` | `2.64 MiB` |
| `bitrate` | `%{bitrate}d` | `123 kbps` |
| `iec-bitrate` | `%{iec-bitrate}d` | `118 Kibps` |
| `uuid_t` | `%{uuid_t}.*16P` 或 `%{uuid_t}.*P` | `10742E39-0657-41F8-AB99-878C5EC2DCAA` |

> 详细格式化选项见 [OSLogStringAlignment](https://developer.apple.com/documentation/os/OSLogStringAlignment)、[OSLogIntegerFormatting](https://developer.apple.com/documentation/os/OSLogIntegerFormatting)、[OSLogFloatFormatting](https://developer.apple.com/documentation/os/OSLogFloatFormatting)、[OSLogBoolFormat](https://developer.apple.com/documentation/os/OSLogBoolFormat)。

## 隐私控制

默认情况下，**整数、浮点数、布尔值不脱敏**（明文显示），**动态字符串和复杂对象被视为私有**（显示为 `<private>`）。通过 `privacy:` 参数显式标注：

### 隐私级别

| 级别 | 说明 | 日志输出 |
|------|------|---------|
| `.auto` | 默认，等同于 `.private` | `<private>` |
| `.private` | 私有数据，不在日志中明文显示 | `<private>` |
| `.public` | 公开数据，始终明文显示 | 原始值 |
| `.private(mask: .hash)` | 显示哈希值，同一进程内相同值产生相同哈希，可关联但不可逆 | 哈希值 |
| `.private(mask: .none)` | 私有但调试时可见（仅 Debug 构建） | Debug 明文 / Release `<private>` |

### 使用示例

```swift
logger.info("用户 \(userId, privacy: .public) 登录")

logger.info("密码 \(password, privacy: .private)")

logger.info("邮箱 \(email, privacy: .private(mask: .hash))")

logger.debug("Token \(token, privacy: .private(mask: .none))")
```

### 隐私标注原则

1. **默认安全**：不标注时自动 `.private`，不会意外泄露
2. **最小公开**：只将无敏感风险的字段标注为 `.public`
3. **可追踪**：需要关联但不可逆的字段用 `.private(mask: .hash)`
4. **调试友好**：开发期需要可见的数据用 `.private(mask: .none)`

## Subsystem 与 Category 设计

### Subsystem

使用反向域名格式，标识应用或模块：

```swift
"com.eagersoft.youzy"          // 主应用
"com.eagersoft.youzy.network"  // 网络模块
"com.eagersoft.youzy.storage"  // 存储模块
```

### Category

标识功能区域，便于过滤：

```swift
"Network"       // 网络请求
"Database"      // 数据库操作
"Authentication" // 认证
"Lifecycle"     // 生命周期
"Cache"         // 缓存
```

### 设计原则

1. **Subsystem 按应用/模块划分**，不是按类划分
2. **Category 按功能领域划分**，粒度适中
3. 同一 subsystem 下 category 不超过 10 个
4. 命名使用 PascalCase，简洁明确

## 日志查看

### Console.app

1. 打开 Console.app
2. 选择设备/模拟器
3. 搜索栏输入：`subsystem:com.eagersoft.youzy`
4. 按级别过滤：Action → Include Info / Debug 等

### 命令行工具

```bash
# 实时查看
log stream --predicate 'subsystem == "com.eagersoft.youzy"' --level debug

# 按类别过滤
log stream --predicate 'subsystem == "com.eagersoft.youzy" AND category == "Network"'

# 只看错误
log stream --predicate 'subsystem == "com.eagersoft.youzy"' --level error

# 导出日志
log show --predicate 'subsystem == "com.eagersoft.youzy"' --last 1h > app.log
```

### Xcode Console

运行时在 Xcode 底部 Console 中直接查看，可右键日志条目选择 Show Package/Category。

## OSLogStore 编程访问（iOS 15+）

在应用内读取已写入的系统日志：

```swift
import os

func fetchRecentLogs(seconds: TimeInterval = 60) async throws -> [OSLogEntryLog] {
    let store = try OSLogStore(scope: .currentProcessIdentifier)
    let position = store.position(date: Date().addingTimeInterval(-seconds))
    let entries = try store.getEntries(at: position)
    return entries
        .compactMap { $0 as? OSLogEntryLog }
        .filter { $0.subsystem == "com.eagersoft.youzy" }
}
```

### OSLogEntryLog 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `subsystem` | `String` | 子系统 |
| `category` | `String` | 分类 |
| `level` | `OSLogEntryLogLevel` | 级别 |
| `composedMessage` | `String` | 完整消息 |
| `date` | `Date` | 时间戳 |
| `process` | `String` | 进程名 |
| `thread` | `UInt64` | 线程 ID |

## 测试中的日志捕获

`os.Logger` 没有内置的内存日志捕获机制。推荐通过协议抽象实现测试友好：

### 定义日志协议

```swift
import os

protocol Loggable: Sendable {
    func debug(_ message: String)
    func info(_ message: String)
    func log(level: OSLogEntryLogLevel, _ message: String)
    func error(_ message: String)
    func fault(_ message: String)
}
```

### 生产实现

```swift
struct SystemLogger: Loggable {
    private let logger: os.Logger

    init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    func debug(_ message: String) { logger.debug("\(message, privacy: .public)") }
    func info(_ message: String) { logger.info("\(message, privacy: .public)") }
    func log(level: OSLogEntryLogLevel, _ message: String) {
        logger.log(level: level, "\(message, privacy: .public)")
    }
    func error(_ message: String) { logger.error("\(message, privacy: .public)") }
    func fault(_ message: String) { logger.fault("\(message, privacy: .public)") }
}
```

> `SystemLogger` 中默认使用 `privacy: .public`，因为调用方已在消息中明确处理了隐私标注。如需更细粒度的隐私控制，可扩展协议方法增加 `privacy` 参数。

### 测试实现

```swift
actor InMemoryLogger: Loggable {
    private(set) var entries: [(level: String, message: String)] = []

    func debug(_ message: String) { entries.append(("debug", message)) }
    func info(_ message: String) { entries.append(("info", message)) }
    func log(level: OSLogEntryLogLevel, _ message: String) { entries.append(("log(\(level.rawValue))", message)) }
    func error(_ message: String) { entries.append(("error", message)) }
    func fault(_ message: String) { entries.append(("fault", message)) }
}
```

> 使用 `actor` 保证线程安全，避免并发测试中数据竞争。

### 使用方式

```swift
class NetworkService {
    let logger: Loggable

    init(logger: Loggable = SystemLogger(subsystem: "com.eagersoft.youzy", category: "Network")) {
        self.logger = logger
    }

    func fetch() async {
        logger.info("开始请求")
    }
}

// 生产
let service = NetworkService()

// 测试
let testLogger = InMemoryLogger()
let service = NetworkService(logger: testLogger)
await service.fetch()
let entries = await testLogger.entries
XCTAssertEqual(entries.first?.message, "开始请求")
```

> 对于不依赖注入的场景，可直接用 `OSLogStore`（iOS 15+）在集成测试中验证日志输出。

## 从 print / os_log 迁移

### print → os.Logger

| 维度 | `print` | `os.Logger` |
|------|---------|------------|
| Release 行为 | 仍然输出，泄露信息 | `.debug` 不输出，`.info` 及以上受系统管理 |
| 隐私 | 明文输出所有内容 | 默认 `<private>`，需显式标注 `.public` |
| 性能 | 同步 I/O，阻塞线程 | 异步写入，惰性求值 |
| 可过滤 | 无 | 按 subsystem/category/级别过滤 |

```swift
// Before: print
print("用户登录: \(userId)")

// After: os.Logger
logger.info("用户 \(userId, privacy: .public) 登录")
```

### os_log → os.Logger

```swift
// Before: os_log
os_log("请求失败: %{public}@", error.localizedDescription)
os_log(.error, "数据解析错误: %{public}@", errorMessage)

// After: os.Logger
logger.error("请求失败: \(error.localizedDescription)")
logger.error("数据解析错误: \(errorMessage)")
```

### 迁移检查清单

| 步骤 | 说明 | 级别 |
|------|------|------|
| 搜索所有 `print(` 调用 | 全部替换为对应级别的 Logger 方法 | 强制 |
| 搜索所有 `os_log(` 调用 | 替换为 Logger 字符串插值 | 强制 |
| 检查 `%{public}@` 标注 | 对应 Logger 中使用 `privacy: .public` | 强制 |
| 为迁移的日志点选择合适的级别 | debug/info/error/fault | 强制 |
| 补充隐私标注 | 默认私有，敏感字段显式标注 | 推荐 |

## Swift Concurrency 场景

`os.Logger` 本身是 `Sendable` 的，可在 `Task`、`Actor` 中安全使用：

```swift
actor DataStore {
    private static let logger = Logger(subsystem: "com.eagersoft.youzy", category: "Database")

    func save(_ item: Item) async throws {
        Self.logger.debug("开始保存数据")
        // ...
        Self.logger.info("数据保存成功")
    }
}
```

在 Task 中：

```swift
Task {
    logger.debug("后台任务开始")
    let result = await process()
    logger.info("后台任务完成: \(result, privacy: .public)")
}
```

## SwiftUI 场景

```swift
struct ProfileView: View {
    private static let logger = Logger(subsystem: "com.eagersoft.youzy", category: "UI")

    var body: some View {
        List {
            // ...
        }
        .onAppear {
            Self.logger.debug("ProfileView appeared")
        }
        .onDisappear {
            Self.logger.debug("ProfileView disappeared")
        }
    }
}
```

## 错误处理日志模式

```swift
do {
    try await fetchData()
} catch let error as NetworkError {
    logger.error("网络请求失败: \(error.localizedDescription)")
} catch {
    logger.error("未知错误: \(error)")
}
```

在 async 函数中：

```swift
func loadProfile() async {
    do {
        let profile = try await api.fetchProfile()
        logger.info("加载用户资料成功")
    } catch {
        logger.error("加载用户资料失败: \(error)")
    }
}
```

> `.fault` 用于不可恢复的严重故障，`.error` 用于可恢复的错误。`catch` 块中通常使用 `.error`。

## 性能区间追踪（OSSignposter）

`OSSignposter` 与 `os.Logger` 共享同一 subsystem/category，可在 Instruments 中可视化追踪代码执行区间：

```swift
import os

let signposter = OSSignposter(subsystem: "com.eagersoft.youzy", category: "Network")

func fetchUserData() async {
    let signpostID = signposter.makeSignpostID()
    let interval = signposter.beginInterval("FetchUser", id: signpostID)

    let userData = await api.fetchUser()

    signposter.endInterval("FetchUser", interval, "Fetched \(userData.count, privacy: .public) items")
}
```

在 Instruments 中选择 `os_signpost` 模板即可查看区间耗时和重叠情况。

| 场景 | 方法 | 说明 |
|------|------|------|
| 追踪一次性操作 | `beginInterval` + `endInterval` | 网络请求、数据库查询 |
| 追踪重复事件 | `emitEvent` | 缓存命中/未命中 |
| 自定义 ID | `makeSignpostID()` | 并发区间区分 |

## 与 os_log 的关系

| 维度 | `os.Logger` | `os_log`（C API） |
|------|------------|-------------------|
| 语言 | Swift 原生 | C/ObjC 桥接 |
| 插值 | 字符串插值 | `%@` / `%{public}@` 格式 |
| 隐私 | 参数级 `.private`/`.public` | `%{public}@` 显式公开，默认私有 |
| 类型安全 | 编译期检查 | 运行时 |
| 最低版本 | iOS 14+ | iOS 10+ |
| 推荐 | 新项目首选 | 需兼容 iOS 14 以下时使用 |

`os.Logger` 是 `os_log` 的 Swift 原生封装，底层共享同一日志基础设施。新项目应优先使用 `os.Logger`。

## 最佳实践

### Logger 声明

```swift
// ✅ 好：静态常量，整个类共享
class NetworkManager {
    private static let logger = Logger(subsystem: "com.eagersoft.youzy", category: "Network")
}

// ❌ 差：每次调用创建新实例
func fetch() {
    let logger = Logger(subsystem: "com.eagersoft.youzy", category: "Network")
}
```

### 隐私标注

```swift
// ✅ 好：敏感数据显式标注隐私
logger.info("用户 \(email, privacy: .private(mask: .hash)) 登录")

// ❌ 差：依赖默认行为，意图不明确
logger.info("用户 \(email) 登录")
```

### 日志级别选择

- **`.debug`**：开发期诊断信息，Release 不输出
- **`.info`**：重要业务事件（启动、登录、请求完成）
- **`.error`**：可恢复的错误（请求失败、解析错误）
- **`.fault`**：不可恢复的严重故障（数据损坏、逻辑不一致）
- 正常操作不要用 `.error` 或 `.fault`（如"请求收到"用 `.debug`）

### 库中接受 Logger

```swift
// ✅ 好：通过初始化参数传入
class MyLibrary {
    private let logger: Loggable
    init(logger: Loggable = SystemLogger(subsystem: "com.eagersoft.youzy.lib", category: "Core")) {
        self.logger = logger
    }
}

// ✅ 可接受：库自己创建 Logger（os.Logger 无上下文传播问题）
class MyLibrary {
    private static let logger = Logger(subsystem: "com.eagersoft.youzy.lib", category: "Core")
}
```

> 与 swift-log 不同，`os.Logger` 没有 metadata 传播链，库自建 Logger 不会丢失上下文。但如果需要测试友好，仍建议通过 `Loggable` 协议注入。

### 性能

1. Debug 级别在 Release 中**零开销**（编译器优化掉）
2. 字符串插值是惰性求值，日志未输出时不会求值
3. 无需自定义后端，系统统一管理 I/O
4. 不需要 `LoggingSystem.bootstrap` 等全局配置

### 日志消息命名

```swift
// ✅ 好：动词开头，描述动作
logger.info("开始请求用户数据")
logger.error("解析响应数据失败")

// ❌ 差：缺少动作，意图模糊
logger.info("用户数据")
logger.error("响应")
```

### 避免日志中的条件逻辑

```swift
// ✅ 好：分别记录，信息明确
if items.isEmpty {
    logger.debug("列表为空")
} else {
    logger.debug("加载 \(items.count, privacy: .public) 条数据")
}

// ❌ 差：三元表达式在日志中难以阅读
logger.debug(items.isEmpty ? "空" : "有数据")
```

### fault 与崩溃报告

`.fault` 级别日志会出现在系统崩溃报告中，应包含关键诊断信息：

```swift
// ✅ 好：包含关键上下文
logger.fault("数据完整性校验失败: 期望 \(expected, privacy: .public) 条，实际 \(actual, privacy: .public) 条")

// ❌ 差：信息不足，崩溃报告中无法诊断
logger.fault("数据错误")
```
