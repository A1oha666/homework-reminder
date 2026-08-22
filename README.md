# homework-reminder

一个基于 OpenClaw 的作业提醒自动化服务，能自动在每天 18:00 推送七天内截止作业到飞书群，支持通过自然语言管理作业列表。

## 项目背景

线上作业平台多，截止时间各不相同，经常忘记交作业。通过飞书机器人实现自动化提醒，接入 OpenClaw 后可直接用自然语言管理作业。

## 技术栈

### 服务端
- **语言**: Go 1.21
- **框架**: Gin
- **部署**: Docker → ClawCloud
- **数据存储**: JSON 文件
- **自动化部署**: GitHub Actions

### 客户端
- **OpenClaw Skill**: 自然语言管理作业
- **iOS**: Swift + UIKit
- **管理面板**: HTML + CSS + JavaScript

## 目录结构

```
server/
├── main.go              # 服务端代码
├── go.mod / go.sum     # Go 依赖
├── Dockerfile           # Docker 构建
├── homework.json        # 数据文件
├── templates/
│   └── index.html      # 管理面板
└── API.md              # 接口文档

.github/workflows/
└── deploy.yml          # GitHub Actions 自动部署
```

## 核心功能

1. **自动提醒**：每天 18:00（北京时间）检查七天内截止的作业，推送飞书通知
2. **手动提醒**：`POST /api/remind` 接口支持手动触发
3. **作业管理**：增删查作业，支持 Basic Auth
4. **自然语言控制**：接入 OpenClaw Skill，可通过自然语言管理作业

## OpenClaw Skill

### 触发场景

用户发送涉及作业管理的消息时激活，如：
- "添加一个作业：明天交的高数"
- "帮我看看有哪些作业"
- "删除今天的高数作业"
- "把高数作业截止日期改成周五"

### 支持操作

| 操作 | 说明 |
|------|------|
| 查询作业 | 获取所有作业列表 |
| 添加作业 | 添加新作业（名称 + 截止日期） |
| 删除作业 | 按名称匹配删除 |
| 修改作业 | 按名称匹配修改截止日期 |

### 后端配置

```json
{
  "baseUrl": "https://hbiwuhfgarke.ap-southeast-1.clawcloudrun.com"
}
```

## 接口列表

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | /api/homework | 获取作业列表 | 否 |
| POST | /api/homework | 添加作业 | 是 |
| DELETE | /api/homework/:id | 删除作业 | 是 |
| PATCH | /api/homework/:id | 修改作业 | 是 |
| POST | /api/remind | 发送提醒 | 否 |
| GET | /health | 健康检查 | 否 |

详见 [API.md](server/API.md)

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `FEISHU_WEBHOOK` | - | 飞书 Webhook URL（必填） |
| `AUTH_ENABLED` | `true` | 是否开启认证 |
| `AUTH_USER` | `admin` | 认证用户名 |
| `AUTH_PASS` | `admin` | 认证密码 |
| `DATA_FILE` | `homework.json` | 数据文件路径 |
| `PORT` | `8080` | 服务端口 |

## 开发流程

1. 本地开发代码
2. 推送到 GitHub
3. GitHub Actions 自动构建 Docker 镜像
4. 部署到 ClawCloud
