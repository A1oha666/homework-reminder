# 作业提醒服务 API 文档

## 基础信息

- **Base URL**: `https://hbiwuhfgarke.ap-southeast-1.clawcloudrun.com`
- **认证**: 除特别说明外，GET 接口公开，POST/DELETE 接口需要 Basic Auth

## 接口列表

### 1. 获取作业列表

```
GET /api/homework
```

**说明**: 获取所有作业列表

**认证**: 无需认证

**响应示例**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "xxx-xxx",
      "name": "高数第二章作业",
      "deadline": "2026-04-15",
      "created_at": "2026-04-14T10:00:00+08:00"
    }
  ]
}
```

---

### 2. 添加作业

```
POST /api/homework
```

**说明**: 添加新作业

**认证**: Basic Auth（如果 `AUTH_ENABLED=true`）

**请求体**:
```json
{
  "name": "作业名称",
  "deadline": "2026-04-15"
}
```

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "id": "xxx-xxx",
    "name": "高数第二章作业",
    "deadline": "2026-04-15",
    "created_at": "2026-04-14T10:00:00+08:00"
  }
}
```

---

### 3. 删除作业

```
DELETE /api/homework/:id
```

**说明**: 删除指定作业

**认证**: Basic Auth（如果 `AUTH_ENABLED=true`）

**响应示例**:
```json
{
  "code": 0,
  "msg": "删除成功"
}
```

---

### 4. 发送提醒

```
POST /api/remind
```

**说明**: 手动发送飞书提醒

**认证**: 无需认证

**响应示例**:
```json
{
  "code": 0,
  "msg": "发送成功"
}
```

**消息格式**:
- 今天有截止作业 → `提醒：作业1、作业2`
- 今天没截止但有其他作业 → `提醒（暂无今日截止）：作业1(日期)\n作业2(日期)`
- 没有任何作业 → `提醒：暂无作业`

---

### 5. 健康检查

```
GET /health
```

**说明**: 服务健康检查

**响应示例**:
```json
{
  "status": "ok"
}
```

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `FEISHU_WEBHOOK` | - | 飞书 Webhook URL（必填） |
| `AUTH_ENABLED` | `true` | 是否开启认证（true/false） |
| `AUTH_USER` | `admin` | 认证用户名 |
| `AUTH_PASS` | `admin` | 认证密码 |
| `DATA_FILE` | `homework.json` | 数据文件路径 |
| `PORT` | `8080` | 服务端口 |

---

## 认证方式

使用 HTTP Basic Auth：

```bash
curl -u admin:password -X POST https://hbiwuhfgarke.ap-southeast-1.clawcloudrun.com/api/homework \
  -H "Content-Type: application/json" \
  -d '{"name":"测试","deadline":"2026-04-15"}'
```

---

## 自动提醒

- 每天 **12:00**（北京时间）自动发送当天截止作业提醒
- 提醒消息自动发送到飞书群
