---
name: naming-conventions
description: "优志愿 iOS 命名规范。包含代码命名规则、资源文件命名规则、模块命名空间、协议命名、类命名、常量命名、图片资源命名。USE FOR: 命名检查、新建文件命名、资源命名、类名审查、变量命名、协议命名、图片资源命名。DO NOT USE FOR: 路由命名、功能实现、架构设计、代码风格、UI布局、SwiftLint规则。"
license: MIT
metadata:
  author: youzy
  version: "1.0.0"
---

# 优志愿 iOS 命名规范

基于项目 Wiki 开发手册和 [raywenderlich/swift-style-guide](https://github.com/raywenderlich/swift-style-guide)，定义优志愿 iOS 项目的完整命名规范。

> SwiftLint 规则见 [coding-standards skill](../coding-standards/SKILL.md) §2.1

## 1. 基本原则

| 规则 | 说明 | 级别 |
|------|------|------|
| 类型/协议使用 `UpperCamelCase` | 大驼峰，仅含字母数字字符 | 强制 |
| 其他一切使用 `lowerCamelCase` | 小驼峰，仅含字母数字字符 | 强制 |
| 禁止拼音与英文混合命名 | 特殊词汇可用拼音全拼，不可缩写 | 强制 |
| 杜绝不规范缩写 | 公认缩写可用，如 `ucode`/`youzy`/`tzy` | 强制 |
| 类名/属性名/方法名用最少单词表达准确意思 | 避免冗余前缀 | 强制 |

```swift
class CollegeDetailViewController {
    // 不推荐：冗余前缀
    let collegeName: String
    // 推荐：上下文已明确，省略冗余
    let name: String
}
```

## 2. 协议命名

| 协议角色 | 命名方式 | 示例 |
|----------|----------|------|
| delegate | 结尾加 `Delegate` | `CollegeListDelegate` |
| 描述协议做的事 | 用名词描述 | `CollectionRepresentable` |
| 描述行为 | 用 `able` 或 `ing` 后缀 | `Cacheable` / `Loading` |
| 以上都不满足 | 结尾加 `Protocol` | `DataServiceProtocol` |

## 3. 类命名

| 类别 | 命名规则 | 示例 |
|------|----------|------|
| 抽象类 | `Base` 开头 | `BaseTableViewController` |
| 异常类 | `Error` 结尾 | `NetworkError` |
| 测试类 | 类名 + `Test` | `CollegeListViewModelTest` |
| 使用设计模式 | 命名体现模式 | `OrderFactory` / `UserSingleton` |
| ViewController | 功能 + `ViewController` | `CollegeDetailViewController` |

## 4. 常量命名

| 规则 | 说明 | 示例 |
|------|------|------|
| 使用类型属性 | `lowerCamelCase` 风格 | `App.user` / `App.isLogin` |
| 避免全局常量 | 通过类型命名空间管理 | `Host.api` / `Screen.width` |

## 5. 访问控制命名

| 规则 | 说明 | 级别 |
|------|------|------|
| 非暴露属性/方法加 `private` 或 `fileprivate` | 需要暴露的才用默认及以上级别 | 强制 |
| 基类属性/方法使用 `open` | 供子类重写 | 强制 |

## 6. 命名空间

多模块共用类型需加命名空间，使用嵌套 enum 实现：

```swift
// 冲突示例
enum Type {
    case `private`
    case `public`
}

// 解决方案：嵌套 enum 做命名空间
enum College {
    enum Type {
        case `private`
        case `public`
    }
}

enum Major {
    enum Type {
        case ben
        case zhuan
    }
}
```

## 7. 初始化方法命名

| 规则 | 说明 | 级别 |
|------|------|------|
| 不调用 `.init` | 使用 `Foo(value: 1)` 而非 `Foo.init(value: 1)` | 强制 |
| 第一个参数不加 `_` | `init(value: Int)` 非 `init(_ value: Int)` | 强制 |

```swift
// 错误
let foo = Foo.init(value: 1)
init(_ value: Int) { ... }

// 正确
let foo = Foo(value: 1)
init(value: Int) { ... }
```

## 8. 资源文件命名

### 8.1 图片资源

图片资源存放在 `Assets.xcassets`（按模块划分文件夹）或 `Resource`（大图片、启动图）。

| 场景 | 格式 | 示例 |
|------|------|------|
| 全项目通用 | `控件_图片名/作用_颜色` | `nav_back` |
| 模块内使用（可交互） | `模块名_业务描述_图片名_控件描述_控件状态` | `login_login_card_btn` |
| 模块内使用（不可交互） | `模块名_业务描述_图片名_控件描述` | `login_login_logo_icon` |

> 控件状态可忽略

### 8.2 模块目录命名

模块目录使用英文单词，首字母大写，与路由模块名对应：

| 模块目录 | 路由名称 |
|----------|----------|
| Colleges | colleges |
| Major | majors |
| TZY | tzy |
| Video | live |
| Login | - |
| Home | - |
| News | - |
