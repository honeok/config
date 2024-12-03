#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

#define LOG_DIR "/data/docker_data/web/nginx/log"
#define MAX_PATH_LENGTH 256

// 获取当前日期（格式：YYYY-MM-DD）
void get_current_date(char *date_str) {
    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    strftime(date_str, 11, "%Y-%m-%d", tm_info);
}

// 执行系统命令并检查返回值
int execute_command(const char *command) {
    int status = system(command);
    if (status == -1) {
        perror("system");
        return -1;
    }
    return WEXITSTATUS(status);
}

// 删除超过7天的日志文件
void delete_old_logs(const char *dir) {
    DIR *d = opendir(dir);
    if (!d) {
        perror("opendir");
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(d)) != NULL) {
        // 只处理 .log.gz 文件
        if (strstr(entry->d_name, ".log.gz")) {
            char file_path[MAX_PATH_LENGTH];
            snprintf(file_path, MAX_PATH_LENGTH, "%s/%s", dir, entry->d_name);

            struct stat st;
            if (stat(file_path, &st) == -1) {
                perror("stat");
                continue;
            }

            // 获取文件的修改时间并计算文件年龄
            time_t current_time = time(NULL);
            double age_in_days = difftime(current_time, st.st_mtime) / (60 * 60 * 24);

            if (age_in_days > 7) {
                // 删除超过7天的日志文件
                if (remove(file_path) == 0) {
                    printf("Deleted old log: %s\n", file_path);
                } else {
                    perror("remove");
                }
            }
        }
    }
    closedir(d);
}

int main() {
    char log_date[11];
    get_current_date(log_date);  // 获取当前日期

    char access_log_old[MAX_PATH_LENGTH];
    char error_log_old[MAX_PATH_LENGTH];

    // 重命名日志文件
    snprintf(access_log_old, MAX_PATH_LENGTH, "%s/access.log", LOG_DIR);
    snprintf(error_log_old, MAX_PATH_LENGTH, "%s/error.log", LOG_DIR);

    char new_access_log[MAX_PATH_LENGTH];
    char new_error_log[MAX_PATH_LENGTH];
    snprintf(new_access_log, MAX_PATH_LENGTH, "%s/access_%s.log", LOG_DIR, log_date);
    snprintf(new_error_log, MAX_PATH_LENGTH, "%s/error_%s.log", LOG_DIR, log_date);

    if (rename(access_log_old, new_access_log) != 0) {
        perror("Failed to rename access log");
        return 1;
    }

    if (rename(error_log_old, new_error_log) != 0) {
        perror("Failed to rename error log");
        return 1;
    }

    // 检查 Nginx 容器是否存在
    if (execute_command("docker inspect \"nginx\" > /dev/null 2>&1") == 0) {
        // 向Nginx发送信号，重新打开日志文件
        if (execute_command("docker exec nginx nginx -s reopen") != 0) {
            perror("Failed to reopen Nginx logs");
            return 1;
        }
    } else {
        printf("Nginx container not found. Skipping nginx -s reopen.\n");
    }

    // 压缩旧日志
    char gzip_command[MAX_PATH_LENGTH];
    snprintf(gzip_command, MAX_PATH_LENGTH, "gzip %s", new_access_log);
    if (execute_command(gzip_command) != 0) {
        perror("Failed to gzip access log");
        return 1;
    }

    snprintf(gzip_command, MAX_PATH_LENGTH, "gzip %s", new_error_log);
    if (execute_command(gzip_command) != 0) {
        perror("Failed to gzip error log");
        return 1;
    }

    // 删除7天前的日志文件
    delete_old_logs(LOG_DIR);

    printf("Log rotation and cleanup completed successfully.\n");

    return 0;
}