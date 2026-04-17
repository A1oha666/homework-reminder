package main

import (
	"bytes"
	"encoding/json"
	"fmt"
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
	authEnabled   = os.Getenv("AUTH_ENABLED") != "false"
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
	store.load()

	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()
	r.LoadHTMLGlob("templates/*")

	// CORS 中间件
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	if authEnabled {
		auth := gin.BasicAuth(gin.Accounts{
			authUsername: authPassword,
		})
		r.GET("/", auth, func(c *gin.Context) {
			c.HTML(200, "index.html", nil)
		})
		authorized := r.Group("/api", auth)
		{
			authorized.POST("/homework", createHomework)
			authorized.DELETE("/homework/:id", deleteHomework)
		}
	} else {
		r.GET("/", func(c *gin.Context) {
			c.HTML(200, "index.html", nil)
		})
		r.POST("/api/homework", createHomework)
		r.DELETE("/api/homework/:id", deleteHomework)
	}

	// 提醒接口公开
	r.POST("/api/remind", sendRemind)

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	r.GET("/api/homework", listHomework)

	go startScheduler()

	log.Printf("服务启动，端口 %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("启动失败: %v", err)
	}
}

func startScheduler() {
	// 使用北京时间
	loc, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		log.Printf("无法加载北京时区，使用本地时区: %v", err)
		loc = time.Local
	}

	now := time.Now()
	next22 := time.Date(now.Year(), now.Month(), now.Day(), 22, 0, 0, 0, loc)
	if now.After(next22) {
		next22 = next22.Add(24 * time.Hour)
	}
	initialDelay := time.Until(next22)
	log.Printf("下次发送时间: %s，距现在 %v", next22.Format("2006-01-02 15:04:05"), initialDelay)

	time.Sleep(initialDelay)
	checkAndNotify()

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

	// 检查飞书响应
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return err
	}

	if code, ok := result["code"].(float64); ok && code != 0 {
		return fmt.Errorf("飞书返回错误: %v", result["msg"])
	}

	return nil
}

func sendRemind(c *gin.Context) {
	store.mu.RLock()
	today := time.Now().Format("2006-01-02")
	var todayList []*Homework
	var allList []*Homework
	for _, hw := range store.items {
		allList = append(allList, hw)
		if hw.Deadline == today {
			todayList = append(todayList, hw)
		}
	}
	store.mu.RUnlock()

	var names []string
	var msg string

	if len(todayList) > 0 {
		for _, hw := range todayList {
			names = append(names, hw.Name)
		}
		msg = "提醒：" + joinStrings(names, "、")
	} else if len(allList) > 0 {
		for _, hw := range allList {
			names = append(names, hw.Name+"("+hw.Deadline+")")
		}
		msg = "提醒（暂无今日截止）：\n" + joinStrings(names, "\n")
	} else {
		msg = "提醒：暂无作业"
	}

	if err := sendMessage(msg); err != nil {
		c.JSON(500, gin.H{"code": 1, "msg": "发送失败: " + err.Error()})
		return
	}
	c.JSON(200, gin.H{"code": 0, "msg": "发送成功"})
}

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
	for _, hw := range s.items {
		items = append(items, hw)
	}

	data, err := json.Marshal(items)
	if err != nil {
		return err
	}
	return os.WriteFile(dataFile, data, 0644)
}

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
		log.Printf("添加作业失败: 参数错误 - %v", err)
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
		log.Printf("添加作业失败: %s - %v", hw.Name, err)
		c.JSON(500, gin.H{"code": 1, "msg": "保存失败"})
		return
	}

	log.Printf("添加作业成功: %s (截止 %s)", hw.Name, hw.Deadline)
	c.JSON(200, gin.H{"code": 0, "data": hw})

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
