package main

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

var (
	webhookURL    = os.Getenv("FEISHU_WEBHOOK")
	dataFile      = getEnv("DATA_FILE", "homework.json")
	port          = getEnv("PORT", "8080")
	authUsername  = getEnv("AUTH_USER", "admin")
	authPassword  = getEnv("AUTH_PASS", "admin")
)

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

type Homework struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Deadline  string `json:"deadline"`
	CreatedAt string `json:"created_at"`
}

type Store struct {
	items map[string]*Homework
	mu    sync.RWMutex
}

var store *Store

func main() {
	if webhookURL == "" {
		log.Fatal("FEISHU_WEBHOOK 环境变量未设置")
	}

	store = &Store{items: make(map[string]*Homework)}
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()
	r.LoadHTMLGlob("templates/*")

	// 认证中间件（仅用于管理面板）
	auth := gin.BasicAuth(gin.Accounts{
		authUsername: authPassword,
	})

	r.GET("/", auth, func(c *gin.Context) {
		c.HTML(200, "index.html", nil)
	})

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API 公开访问
	r.GET("/api/homework", listHomework)

	// 修改和删除需要认证
	authorized := r.Group("/api", auth)
	{
		authorized.POST("/homework", createHomework)
		authorized.DELETE("/homework/:id", deleteHomework)
	}
		authorized.GET("/homework", listHomework)
		authorized.POST("/homework", createHomework)
		authorized.DELETE("/homework/:id", deleteHomework)
	}

	go startScheduler()

	log.Printf("服务启动，端口 %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("启动失败: %v", err)
	}
}

func startScheduler() {
	// 计算距离下一个 22:00 的时间
	now := time.Now()
	next22 := time.Date(now.Year(), now.Month(), now.Day(), 22, 0, 0, 0, now.Location())
	if now.After(next22) {
		next22 = next22.Add(24 * time.Hour)
	}
	initialDelay := time.Until(next22)
	log.Printf("距离下次发送还有: %v", initialDelay)

	// 等待直到 22:00
	time.Sleep(initialDelay)
	checkAndNotify()

	// 然后每 24 小时执行一次
	ticker := time.NewTicker(24 * time.Hour)
	for range ticker.C {
		checkAndNotify()
	}
}

func checkAndNotify() {
	store.mu.RLock()
	today := time.Now().Format("2006-01-02")
	var toNotify []*Homework
	for _, hw := range store.items {
		if hw.Deadline == today {
			toNotify = append(toNotify, hw)
		}
	}
	store.mu.RUnlock()

	if len(toNotify) == 0 {
		log.Println("今天没有需要提交的作业")
		return
	}

	names := make([]string, 0, len(toNotify))
	for _, hw := range toNotify {
		names = append(names, hw.Name)
	}

	msg := "提醒：" + joinStrings(names, "、")
	log.Printf("发送提醒: %s", msg)
	if err := sendMessage(msg); err != nil {
		log.Printf("发送失败: %v", err)
	}
}

func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return ""
	}
	result := strs[0]
	for i := 1; i < len(strs); i++ {
		result += sep + strs[i]
	}
	return result
}

func sendMessage(text string) error {
	payload := map[string]interface{}{
		"msg_type": "text",
		"content":  map[string]string{"text": text},
	}
	data, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", webhookURL, bytes.NewBuffer(data))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return nil
}

// ---- Store ----

func (s *Store) load() {
	data, err := os.ReadFile(dataFile)
	if err != nil {
		return
	}
	var items []*Homework
	if json.Unmarshal(data, &items) == nil {
		for _, hw := range items {
			s.items[hw.ID] = hw
		}
	}
}

func (s *Store) save() error {
	items := make([]*Homework, 0, len(s.items))
	s.mu.RLock()
	for _, hw := range s.items {
		items = append(items, hw)
	}
	s.mu.RUnlock()

	data, err := json.Marshal(items)
	if err != nil {
		return err
	}
	return os.WriteFile(dataFile, data, 0644)
}

// ---- Handlers ----

func listHomework(c *gin.Context) {
	store.mu.RLock()
	list := make([]*Homework, 0, len(store.items))
	for _, hw := range store.items {
		list = append(list, hw)
	}
	store.mu.RUnlock()
	c.JSON(200, gin.H{"code": 0, "data": list})
}

func createHomework(c *gin.Context) {
	var req struct {
		Name     string `json:"name" binding:"required"`
		Deadline string `json:"deadline" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"code": 1, "msg": "参数错误"})
		return
	}

	hw := &Homework{
		ID:        uuid.New().String(),
		Name:      req.Name,
		Deadline:  req.Deadline,
		CreatedAt: time.Now().Format(time.RFC3339),
	}

	store.mu.Lock()
	store.items[hw.ID] = hw
	store.mu.Unlock()

	if err := store.save(); err != nil {
		c.JSON(500, gin.H{"code": 1, "msg": "保存失败"})
		return
	}

	c.JSON(200, gin.H{"code": 0, "data": hw})
}

func deleteHomework(c *gin.Context) {
	id := c.Param("id")

	store.mu.Lock()
	defer store.mu.Unlock()

	if _, ok := store.items[id]; !ok {
		c.JSON(404, gin.H{"code": 1, "msg": "作业不存在"})
		return
	}

	delete(store.items, id)
	if err := store.save(); err != nil {
		c.JSON(500, gin.H{"code": 1, "msg": "删除失败"})
		return
	}

	c.JSON(200, gin.H{"code": 0, "msg": "删除成功"})
}
