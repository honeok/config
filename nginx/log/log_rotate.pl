#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use POSIX qw(strftime);

# 设置日志目录和日期
my $log_dir = "/data/docker_data/web/nginx/log";
my $log_date = strftime("%Y-%m-%d", localtime);

# 切割日志
rename("$log_dir/access.log", "$log_dir/access_$log_date.log") or die "无法移动 access.log: $!\n";
rename("$log_dir/error.log", "$log_dir/error_$log_date.log") or die "无法移动 error.log: $!\n";

# 检查Nginx是否存在
my $nginx_running = `docker inspect "nginx" > /dev/null 2>&1; echo $?`;
chomp($nginx_running);

if ($nginx_running == 0) {
    # 向Nginx发送信号，重新打开日志文件
    system("docker exec nginx nginx -s reopen") == 0 or die "发送信号失败: $!\n";
} else {
    exit 0;
}

# 压缩旧日志
system("gzip", "$log_dir/access_$log_date.log") == 0 or die "压缩access.log失败: $!\n";
system("gzip", "$log_dir/error_$log_date.log") == 0 or die "压缩error.log失败: $!\n";

# 删除7天前的日志
opendir(my $dh, $log_dir) or die "无法打开目录 $log_dir: $!\n";
while (my $file = readdir($dh)) {
    if ($file =~ /\.log\.gz$/) {
        my $file_path = "$log_dir/$file";
        my $mtime = (stat($file_path))[9];  # 获取文件修改时间
        my $current_time = time;
        my $age_in_days = ($current_time - $mtime) / (60 * 60 * 24);

        if ($age_in_days > 7) {
            unlink($file_path) or warn "删除文件失败 $file_path: $!\n";
        }
    }
}
closedir($dh);