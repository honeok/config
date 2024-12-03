package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
	"log"
	"strings"
)

// 获取当前日期，格式化为 YYYY-MM-DD
func getCurrentDate() string {
	return time.Now().Format("2006-01-02")
}

// 执行系统命令并检查返回值
func executeCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to execute command: %v", err)
	}
	return nil
}

// 删除超过7天的日志文件
func deleteOldLogs(logDir string) error {
	now := time.Now()

	err := filepath.Walk(logDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		// 只处理 .log.gz 文件
		if strings.HasSuffix(info.Name(), ".log.gz") {
			// 计算文件的修改时间与当前时间的差距
			if now.Sub(info.ModTime()).Hours() > 7*24*60*60 { // 超过7天
				err := os.Remove(path)
				if err != nil {
					return fmt.Errorf("failed to delete file %s: %v", path, err)
				}
				fmt.Printf("Deleted old log: %s\n", path)
			}
		}
		return nil
	})

	return err
}

func main() {
	logDir := "/data/docker_data/web/nginx/log"
	logDate := getCurrentDate()

	// 重命名日志文件
	accessLogOld := filepath.Join(logDir, "access.log")
	errorLogOld := filepath.Join(logDir, "error.log")
	accessLogNew := filepath.Join(logDir, fmt.Sprintf("access_%s.log", logDate))
	errorLogNew := filepath.Join(logDir, fmt.Sprintf("error_%s.log", logDate))

	err := os.Rename(accessLogOld, accessLogNew)
	if err != nil {
		log.Fatalf("Failed to rename access log: %v\n", err)
	}

	err = os.Rename(errorLogOld, errorLogNew)
	if err != nil {
		log.Fatalf("Failed to rename error log: %v\n", err)
	}

	// 检查 Nginx 容器是否存在
	_, err = exec.Command("docker", "inspect", "nginx").Output()
	if err == nil {
		// 向Nginx发送信号，重新打开日志文件
		err := executeCommand("docker", "exec", "nginx", "nginx", "-s", "reopen")
		if err != nil {
			log.Fatalf("Failed to reopen Nginx logs: %v\n", err)
		}
	} else {
		fmt.Println("Nginx container not found. Skipping nginx -s reopen.")
	}

	// 压缩旧日志
	err = executeCommand("gzip", accessLogNew)
	if err != nil {
		log.Fatalf("Failed to gzip access log: %v\n", err)
	}

	err = executeCommand("gzip", errorLogNew)
	if err != nil {
		log.Fatalf("Failed to gzip error log: %v\n", err)
	}

	// 删除7天前的日志文件
	err = deleteOldLogs(logDir)
	if err != nil {
		log.Fatalf("Failed to delete old logs: %v\n", err)
	}

	fmt.Println("Log rotation and cleanup completed successfully.")
}