---
name: swift-log
description: 在 Swift 项目中使用 swift-log 日志框架时使用。涵盖 Logger 创建与配置、LogHandler 后端实现、LoggingSystem bootstrap、Metadata/MetadataProvider/Attributes 结构化日志、编译期 Traits 日志级别过滤。适用于添加 swift-log 依赖、实现自定义 LogHandler、配置日志系统、编写日志相关测试等场景。当用户提到 swift-log、Logger、LogHandler、LoggingSystem、MetadataProvider、LogEvent、InMemoryLogHandler 时触发。
---

# SwiftLog 使用指南

swift-log 是 Apple 官方的 Swift 日志 API 包，提供统一的日志接口。它是 **API 包**，只定义接口，具体输出由可插拔的 LogHandler 后端决定。

## 添加依赖

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/apple/swift-log", from: "1.6.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "Logging", package: "swift-log")
    ])
]
```

测试中使用内存日志还需添加：
```swift
.product(name: "InMemoryLogging", package: "swift-log")
```

## 核心架构

```
应用/库代码 → Logger（检查 logLevel，构造 LogEvent）→ LoggingSystem（bootstrap 工厂）→ LogHandler（输出日志）
```

## 核心类型速查

| 类型 | 角色 | 关键点 |
|------|------|--------|
| `Logger` | 面向用户的日志入口 | 值类型，修改不影响其他实例 |
| `LogHandler` | 日志后端协议 | 必须是 struct，必须具有值语义 |
| `LoggingSystem` | 全局配置 | bootstrap 只能调用一次 |
| `LogEvent` | 一次日志事件的完整数据 | 传给 `handler.log(event:)` |
| `Logger.MetadataProvider` | 运行时自动注入元数据 | 闭包包装，每次日志发出时调用 |
| `Logger.MetadataValue` | 元数据值 | 支持 string/array/dictionary/attributed |
| `Logger.MetadataValueAttributes` | 属性标注 | 轻量级 Int64 存储，零开销按需检查 |
| `Logger.Message` | 日志消息 | 支持字符串插值 |

## 日志级别（低→高）

| 级别 | 值 | 用途 |
|------|-----|------|
| `.trace` | 0 | 详细诊断信息，可能影响性能 |
| `.debug` | 1 | 高层操作概览 |
| `.info` | 2 | 无法通过其他方式传达的问题（如重试、回退） |
| `.notice` | 3 | 需要特殊处理但非错误的条件 |
| `.warning` | 4 | 比notice更严重但非错误 |
| `.error` | 5 | 错误条件 |
| `.critical` | 6 | 需要立即关注的严重错误，后端可捕获堆栈 |

## Logger 使用

### 创建

```swift
// 默认 Handler（StreamLogHandler → stderr）
let logger = Logger(label: "com.example.App")

// 自定义 Handler 工厂
let logger = Logger(label: "com.example.App") { label in
    MyCustomLogHandler(label: label)
}

// 附带 MetadataProvider
let provider = Logger.MetadataProvider { ["trace-id": "\(traceID)"] }
let logger = Logger(label: "com.example.App", metadataProvider: provider)
```

### 记录日志

```swift
// 推荐使用级别专用方法（编译期可优化）
logger.trace("详细诊断")
logger.debug("调试信息")
logger.info("信息性消息")
logger.notice("注意条件")
logger.warning("警告")
logger.error("错误")
logger.critical("严重错误")

// 通用方法（有额外 switch 开销，不推荐热路径使用）
logger.log(level: .info, "信息性消息")
```

### 完整参数

```swift
logger.info(
    "用户登录",                      // message: 支持字符串插值
    error: someError,                // error: 关联的错误（可选）
    metadata: ["user-id": "\(id)"],  // metadata: 一次性元数据（可选）
    source: "AuthModule"             // source: 来源模块（可选，默认从 #fileID 推导）
)
```

### 级别过滤

```swift
var logger = Logger(label: "com.example.App")
logger.logLevel = .warning  // 只有 warning/error/critical 会输出
```

> 修改 `logLevel` 只影响当前实例，不影响其他实例。

### 值语义

```swift
var reqLogger = logger
reqLogger[metadataKey: "request-id"] = "\(UUID())"
// logger 不受影响，reqLogger 独立持有 request-id
```

## LoggingSystem Bootstrap

**整个进程只能调用一次**，重复调用会崩溃：

```swift
// 输出到 stdout
LoggingSystem.bootstrap(StreamLogHandler.standardOutput)

// 自定义 Handler
LoggingSystem.bootstrap { label in
    var handler = MyHandler(label: label)
    handler.logLevel = .debug
    return handler
}

// 带 MetadataProvider
LoggingSystem.bootstrap(
    { label, mp in
        var handler = StreamLogHandler.standardError(label: label)
        handler.metadataProvider = mp
        return handler
    },
    metadataProvider: Logger.MetadataProvider {
        guard let traceID = Baggage.current?.traceID else { return [:] }
        return ["trace-id": "\(traceID)"]
    }
)
```

## Metadata（元数据）

类型：`[String: Logger.MetadataValue]`

### MetadataValue 类型

```swift
// .string（推荐用字符串插值）
["user-id": "\(userId)"]

// .array
["colors": ["\(color1)", "\(color2)"]]

// .dictionary（嵌套）
["request": ["method": "GET", "path": "/api/users"]]

// .stringConvertible
["data": .stringConvertible(myObj)]
```

### 三种设置方式

```swift
// 1. Logger 实例级（持久，所有后续日志携带）
var logger = Logger(label: "App")
logger[metadataKey: "request-id"] = "\(UUID())"

// 2. 单条日志级（一次性）
logger.info("查询失败", metadata: ["query": "\(sql)", "duration": "\(t)s"])

// 3. MetadataProvider（运行时自动注入，见 Bootstrap 章节）
```

### 合并优先级（后者覆盖前者）

1. Handler 基础 metadata
2. MetadataProvider 提供的 metadata
3. 单条日志 metadata

传入 `error` 时，StreamLogHandler 自动添加 `error.message` 和 `error.type`。

### Key 命名约定

使用点分层次命名：`db.operation`、`http.status`、`request.id`

## Attributes 属性系统

轻量级属性标注，不影响字符串表示，Handler 按需检查零开销。

### 定义自定义属性

```swift
public enum Sensitivity: Int64, Sendable, Logger.MetadataValueAttributes.Attribute {
    case `public` = 1
    case sensitive = 2
}
```

### 使用

```swift
// 字符串插值中
["user-id": "\(userId, attributes: [Sensitivity.sensitive])"]

// 闭包方式
["user-id": "\(userId, attributes: { $0[Sensitivity.self] = .sensitive })"]

// 工厂方法
let value: Logger.MetadataValue = .attributed(userId, attributes: [Sensitivity.sensitive])
```

### Handler 中读取

```swift
public func log(event: LogEvent) {
    for (_, value) in mergedMetadata {
        if value.attributes[Sensitivity.self] == .sensitive {
            // 脱敏处理
        }
    }
}
```

关键特性：按需检查（不调用零开销）、无需协议变更、自然流动通过 metadata 合并和 MultiplexLogHandler。

## LogHandler 协议

### 必须满足

1. **必须是 struct**（值语义）
2. **metadata 和 logLevel 必须具有值语义**（修改一个实例不影响其他实例）

### 必需成员

```swift
public protocol LogHandler: Sendable {
    var metadataProvider: Logger.MetadataProvider? { get set }
    func log(event: LogEvent)
    subscript(metadataKey: String) -> Logger.Metadata.Value? { get set }
    var metadata: Logger.Metadata { get set }
    var logLevel: Logger.Level { get set }
}
```

### 值语义验证

```swift
var logger1 = Logger(label: "first")
logger1.logLevel = .debug
logger1[metadataKey: "key"] = "first"

var logger2 = logger1
logger2.logLevel = .error
logger2[metadataKey: "key"] = "second"

// logger1.logLevel 必须仍是 .debug
// logger1[metadataKey: "key"] 必须仍是 "first"
```

### 最简实现

```swift
public struct PrintLogHandler: LogHandler {
    private let label: String
    public var logLevel: Logger.Level = .info
    public var metadata: Logger.Metadata = [:]
    public var metadataProvider: Logger.MetadataProvider?

    public init(label: String) { self.label = label }

    public func log(event: LogEvent) {
        var merged = self.metadata
        if let provided = self.metadataProvider?.get(), !provided.isEmpty {
            merged.merge(provided, uniquingKeysWith: { _, rhs in rhs })
        }
        if let explicit = event.metadata, !explicit.isEmpty {
            merged.merge(explicit, uniquingKeysWith: { _, rhs in rhs })
        }
        let meta = merged.isEmpty ? "" : merged.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        print("\(label) \(event.level) [\(meta)]: \(event.message)")
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }
}
```

### 全局日志级别覆盖（特殊场景）

收到信号时切换所有 Logger 到 debug 级别：

```swift
public struct GlobalOverrideHandler: LogHandler {
    private static let lock = NSLock()
    private static var override: Logger.Level?
    private var _logLevel: Logger.Level = .info
    public var metadata: Logger.Metadata = [:]

    public var logLevel: Logger.Level {
        get { Self.lock.withLock { Self.override ?? self._logLevel } }
        set { self._logLevel = newValue }
    }

    public static func overrideGlobalLogLevel(_ level: Logger.Level) {
        Self.lock.withLock { Self.override = level }
    }
    // ... 其余成员 ...
}
```

## 内置 Handler

### StreamLogHandler

输出到 stdout/stderr，格式：`TIMESTAMP LEVEL LABEL: METADATA [SOURCE] MESSAGE`

```swift
StreamLogHandler.standardError(label: "App")
StreamLogHandler.standardOutput(label: "App")
StreamLogHandler.standardError(label: "App", metadataProvider: provider)
```

特性：默认 `.info` 级别、线程安全写入、自动添加 `error.message`/`error.type`、metadata 按键名排序。

### MultiplexLogHandler

多路分发，初始化时取子 Handler 最低级别，设置 logLevel 应用到所有子 Handler，metadata 读取按初始化顺序优先。

```swift
MultiplexLogHandler([StreamLogHandler.standardError(label: label), FileHandler(label: label)])
```

### SwiftLogNoOpLogHandler

丢弃所有日志，`logLevel` 返回 `.critical`。

### InMemoryLogHandler（测试用）

```swift
import InMemoryLogging

let handler = InMemoryLogHandler()
let logger = Logger(label: "test", factory: { _ in handler })
logger.info("测试")

// 验证
handler.entries.count       // 日志条数
handler.entries[0].level    // 级别
handler.entries[0].message  // 消息
handler.entries[0].error    // 错误
handler.entries[0].metadata // 元数据
handler.clear()             // 清空
```

## MetadataProvider

### 创建与多路复用

```swift
let provider = Logger.MetadataProvider {
    var m: Logger.Metadata = [:]
    if let tid = Baggage.current?.traceID { m["trace-id"] = "\(tid)" }
    return m
}

// 多路复用（冲突 key 由后者覆盖）
let merged = Logger.MetadataProvider.multiplex([traceProvider, requestProvider])
```

### 传播层级

1. 全局：`LoggingSystem.bootstrap(..., metadataProvider:)`
2. Handler 级：`handler.metadataProvider = provider`
3. Logger 级：`Logger(label:, metadataProvider: provider)`

## 编译期 Traits（零运行时开销）

| Trait | 移除的级别 |
|-------|-----------|
| `MaxLogLevelDebug` | trace |
| `MaxLogLevelInfo` | trace, debug |
| `MaxLogLevelNotice` | trace, debug, info |
| `MaxLogLevelWarning` | trace, debug, info, notice |
| `MaxLogLevelError` | trace–warning |
| `MaxLogLevelCritical` | 除 critical 外全部 |
| `MaxLogLevelNone` | 全部移除 |

使用方式：

```swift
// Package.swift
.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0", traits: ["MaxLogLevelWarning"])

// 命令行
swift build -c release --traits MaxLogLevelWarning
```

**只有应用应设置 trait，库不应设置**（传递依赖中的 trait 会影响整个解析树）。

`MaxLogLevelNone` 时 `logger[metadataKey:]` setter 和 `logger.logLevel` setter 也被编译掉，读取仍正常。

## 最佳实践

### 日志级别选择

- **库**：只用 `trace`/`debug`/`info`，避免 `warning`/`error`/`critical`（除非一次性启动警告）
- **应用**：可使用任何级别，控制台显示考虑 `notice` 为最低可见级别
- 正常操作不要用 `info` 级别（如"请求收到"），用 `debug` 或 `trace`

### 结构化日志

```swift
// ✅ 好：消息提供上下文，metadata 提供结构化数据
logger.info("接受连接", metadata: ["connection.id": "\(id)", "connection.peer": "\(peer)"])

// ❌ 差：所有信息嵌入字符串
logger.info("Accepted connection \(id) from \(peer)")
```

### 库中接受 Logger

```swift
// ✅ 通过方法参数传入（确保元数据传播）
func process(_ request: Request, logger: Logger) async throws -> Response {
    var logger = logger
    logger[metadataKey: "request.id"] = "\(request.id)"
    logger.debug("处理请求")
    // ...
}

// ❌ 库自己创建 Logger（丢失调用者上下文）
class MyLibrary {
    private let logger = Logger(label: "MyLibrary")  // 丢失所有上下文
}
```

### 性能

1. Handler 不要阻塞调用线程做 I/O
2. 消息和 metadata 是 `@autoclosure`，只在日志确实发出时求值
3. 优先用级别专用方法 `logger.info(...)` 而非 `logger.log(level: .info, ...)`
4. 生产环境用 Traits 完全移除不需要的日志代码

## LogEvent 字段

| 属性 | 类型 | 说明 |
|------|------|------|
| `level` | `Logger.Level` | 日志级别 |
| `message` | `Logger.Message` | 日志消息 |
| `error` | `(any Error)?` | 关联错误 |
| `metadata` | `Logger.Metadata?` | 本次元数据 |
| `source` | `String` | 来源模块（未指定时从 `file` 惰性推导，不访问零开销） |
| `file` | `String` | 源文件 `#fileID` |
| `function` | `String` | 函数名 `#function` |
| `line` | `UInt` | 行号 `#line` |

所有属性可变，Handler 包装器可在转发前改写。
