#!/bin/bash

# ==========================================
# 0. 修复底层状态与 apt 结构性报错
# ==========================================
echo -e "\n---> 正在修复可能受损的包管理器状态..."
mkdir -p /var/lib/apt/lists/partial
dpkg --configure -a >/dev/null 2>&1
apt-get --fix-broken install -y >/dev/null 2>&1
apt-get clean >/dev/null 2>&1

# ==========================================
# 1. 更新系统与核心依赖
# ==========================================
echo -e "\n---> 正在同步软件源并更新系统..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get install -y curl iproute2 dnsutils

# ==========================================
# 2. 跨版本极致瘦身 (400M+ 破壁极限版)
# ==========================================
echo -e "\n---> 正在执行极致空间瘦身 (剥皮抽筋式清理)..."

# 第一层：强力卸载无用开发库、多语言包、旧版微码、基础编译链、庞大的内核头文件及冗余组件
apt-get purge -y gcc-12 g++-12 cpp-12 libllvm16 libclang-cpp16 libclang-rt-16-dev libclang1-16 libicu-dev libstdc++-12-dev mdadm lvm2 multipath-tools firmware-linux-free intel-microcode iucode-tool libx265-* libz3-4 util-linux-locales git git-man libc6-dev linux-libc-dev dpkg-dev make build-essential linux-headers-* >/dev/null 2>&1

# 第二层：彻底铲除二进制工具链与物理键盘映射
apt-get purge -y binutils binutils-common binutils-x86-64-linux-gnu xkb-data >/dev/null 2>&1

# 第三层：终极通配符绝杀，移除 Python3 环境 (放弃防火墙等安全插件)
apt-get purge -y python3* libpython3* >/dev/null 2>&1

# 终极清扫：深度清理所有连带的孤立依赖项
apt-get autoremove -y --purge >/dev/null 2>&1

# ==========================================
# 3. 终极无痕垃圾清理与后台静默化
# ==========================================
echo -e "\n---> 正在执行深层垃圾文件销毁与后台静默化..."

# 彻底关闭并禁用 Debian 的后台自动下载更新定时器 (防止空间反弹)
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1

# 销毁包管理器缓存 (现在删掉后不会再被后台自动下回来了)
apt-get clean
apt-get autoclean >/dev/null 2>&1
rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# 清理 /boot 目录下升级产生的多余备份镜像
rm -f /boot/*.bak /boot/*.old /boot/initrd.img-*.bak >/dev/null 2>&1

# 暴力抹除所有本地化说明文档、帮助手册
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/*

# 销毁系统中所有历史打包的旧日志文件
rm -f /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????

# 强制截断当前系统日志（最大保留 5MB，最近1天）
journalctl --vacuum-size=5M >/dev/null 2>&1
journalctl --vacuum-time=1d >/dev/null 2>&1

# 清理临时目录
rm -rf /tmp/* /var/tmp/*

# ==========================================
# 4. 网络环境探测 (纯探测逻辑，不更改配置)
# ==========================================
echo -e "\n---> 正在探测 IPv6 连通性..."
if ping6 -c 2 -W 2 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo -e "[√] 当前网络状态：IPv6 正常可用"
else
    echo -e "[!] 当前网络状态：IPv6 不可用"
fi

# ==========================================
# 5. 网络吞吐与 BBR 拥塞控制优化
# ==========================================
echo -e "\n---> 正在配置 TCP 吞吐优化与 BBR..."
cat > /etc/sysctl.d/99-vps-network.conf << 'SYSCTL_EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
SYSCTL_EOF

sysctl --system >/dev/null 2>&1

# ==========================================
# 6. 生成系统与网络信息面板
# ==========================================
echo -e "\n---> 系统基础环境初始化与瘦身完成！"
echo -e "正在收集系统信息生成面板，请稍候...\n"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PINK='\033[1;35m'
NC='\033[0m'
SEP="${PINK}------------------------------------------------------------${NC}"

os_name=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)
kernel_version=$(uname -r)
bbr_status=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
qdisc_status=$(sysctl -n net.core.default_qdisc 2>/dev/null)
if [[ "$bbr_status" == "bbr" && "$qdisc_status" == "fq" ]]; then
    kernel_info="${kernel_version} [BBR+FQ]"
else
    kernel_info="${kernel_version}"
fi

cpu_cores=$(nproc)
cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | awk -F: '{print $2}' | sed 's/^[ \t]*//')

mem_total=$(free -m | awk '/Mem:/ {printf "%.1f", $2/1024}')
mem_used=$(free -m | awk '/Mem:/ {printf "%.1f", $3/1024}')
swap_total=$(free -m | awk '/Swap:/ {printf "%.1f", $2/1024}')
mem_info="${mem_used} GB / ${mem_total} GB (Swap: ${swap_total} GB)"

disk_info=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

private_ipv4=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{print $7}')
if [ -z "$private_ipv4" ]; then private_ipv4=$(hostname -I | awk '{print $1}'); fi

public_ipv4=$(curl -s4 --connect-timeout 3 ip.sb 2>/dev/null)
public_ipv6=$(curl -s6 --connect-timeout 3 ip.sb 2>/dev/null)

if [ -z "$public_ipv6" ]; then
    ipv6_info="无 IPv6"
else
    ipv6_info="$public_ipv6"
fi

asn=$(curl -s --connect-timeout 3 ipinfo.io/org 2>/dev/null)
city=$(curl -s --connect-timeout 3 ipinfo.io/city 2>/dev/null)
country=$(curl -s --connect-timeout 3 ipinfo.io/country 2>/dev/null)
location="${city} / ${country}"

echo -e "$SEP"
echo -e "${CYAN}系统环境 : ${WHITE}${os_name}${NC}"
echo -e "${CYAN}当前内核 : ${WHITE}${kernel_info}${NC}"
echo -e "${CYAN}CPU 信息 : ${WHITE}${cpu_cores} Core(s) | ${cpu_model}${NC}"
echo -e "${CYAN}内存状态 : ${WHITE}${mem_info}${NC}"
echo -e "${CYAN}硬盘占用 : ${WHITE}${disk_info}${NC}"
echo -e "$SEP"
echo -e "${CYAN}内网 IPv4: ${RED}${private_ipv4}${NC}"
echo -e "${CYAN}公网 IPv4: ${RED}${public_ipv4}${NC}"
echo -e "${CYAN}公网 IPv6: ${GREEN}${ipv6_info}${NC}"
echo -e "${CYAN}网络 ASN : ${WHITE}${asn}${NC}"
echo -e "${CYAN}地理位置 : ${WHITE}${location}${NC}"
echo -e "$SEP"
