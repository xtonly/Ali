#!/bin/bash

# ==========================================
# 极速瘦身与系统优化脚本 (ali-slim.sh)
# 版本：v4.4 终极纯净版 (全逻辑静默防错)
# ==========================================
SCRIPT_VERSION="Ali瘦身 v4.4 终极纯净版"

# ==========================================
# 0. 修复底层状态与 apt 结构性报错
# ==========================================
echo -e "\n---> 正在修复可能受损的包管理器状态..."
mkdir -p /var/lib/apt/lists/partial
dpkg --configure -a >/dev/null 2>&1
apt-get --fix-broken install -y >/dev/null 2>&1
apt-get clean >/dev/null 2>&1

# ==========================================
# 1. 部署系统级 APT 黑名单 (防面板幽灵复活)
# ==========================================
echo -e "\n---> 正在写入 APT 底层黑名单，永久封印流氓依赖..."
mkdir -p /etc/apt/preferences.d/
cat > /etc/apt/preferences.d/99-block-ghosts << 'EOF'
Package: gcc* g++* cpp* llvm* libllvm* clang* mimic* mycroft*
Pin: release *
Pin-Priority: -1
EOF

# ==========================================
# 2. 更新系统与核心依赖
# ==========================================
echo -e "\n---> 正在同步软件源并更新系统..."
apt-get update -y >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y curl iproute2 dnsutils cron >/dev/null 2>&1

# ==========================================
# 3. 专项拦截与剿灭：面板流氓组件 (Mimic) 清理
# ==========================================
echo -e "\n---> 正在查杀自动拉取的 Mimic 组件及其专属账户..."

# 3.1 清除 Docker 层容器与镜像
if command -v docker &> /dev/null; then
    docker rm -f mimic >/dev/null 2>&1
    docker rmi mycroftai/mimic3 mycroftai/mimic >/dev/null 2>&1
fi

# 3.2 清除 Python 层模块
if command -v pip &> /dev/null; then
    pip uninstall -y mimic mycroft-mimic3-tts >/dev/null 2>&1
elif command -v pip3 &> /dev/null; then
    pip3 uninstall -y mimic mycroft-mimic3-tts >/dev/null 2>&1
fi

# 3.3 清除 APT 层软件包
apt-get purge -y mimic mimic3 >/dev/null 2>&1

# 3.4 清除 Mimic 专属用户与用户组 (静默探测防报错)
if id -u mimic &>/dev/null; then
    userdel -r mimic >/dev/null 2>&1
fi
if getent group mimic &>/dev/null; then
    groupdel mimic >/dev/null 2>&1
fi

# 3.5 清除底层二进制与头文件残留
rm -rf $(which mimic 2>/dev/null) /usr/local/bin/mimic /usr/bin/mimic /usr/local/include/mimic /usr/local/lib/libmimic* >/dev/null 2>&1

# ==========================================
# 4. 交换空间 (Swap) 纯净重置防冲突
# ==========================================
echo -e "\n---> 正在无痕清理并重置残留的 Swap 配置..."
swapoff -a >/dev/null 2>&1
sed -i '/swap/d' /etc/fstab
rm -f /swapfile /var/swap /swap.img >/dev/null 2>&1

# ==========================================
# 5. 跨版本极致瘦身 (强力压制反弹的编译链)
# ==========================================
echo -e "\n---> 正在执行极致空间瘦身 (剥皮抽筋式清理)..."

apt-get purge -y gcc-12 g++-12 cpp-12 llvm-16* libllvm16 libclang-cpp16 libclang-rt-16-dev libclang1-16 libicu-dev libstdc++-12-dev mdadm lvm2 multipath-tools firmware-linux-free intel-microcode iucode-tool libx265-* libz3-4 util-linux-locales git git-man libc6-dev linux-libc-dev dpkg-dev make build-essential linux-headers-* >/dev/null 2>&1
apt-get purge -y binutils binutils-common binutils-x86-64-linux-gnu xkb-data >/dev/null 2>&1
apt-get purge -y python3* libpython3* snapd >/dev/null 2>&1
apt-get autoremove -y --purge >/dev/null 2>&1

# ==========================================
# 6. 部署自动化防御系统 (APT拦截器 & 定时任务)
# ==========================================
echo -e "\n---> 正在注入 APT 缓存拦截器与 6:00/18:00 定时清道夫任务..."

# 拦截器设定
cat > /etc/apt/apt.conf.d/99-auto-clean-cache << 'EOF'
APT::Keep-Downloaded-Packages "false";
Dpkg::Post-Invoke { 
    "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin /var/lib/apt/lists/* || true"; 
};
EOF

# 清除旧版任务
rm -f /etc/cron.daily/daily-system-reaper

# 生成清道夫核心脚本
cat > /usr/local/bin/system-reaper.sh << 'EOF'
#!/bin/bash
apt-get autoremove -y --purge >/dev/null 2>&1
apt-get clean >/dev/null 2>&1
rm -f /var/cache/apt/*.bin /var/lib/apt/lists/* >/dev/null 2>&1
journalctl --vacuum-size=5M >/dev/null 2>&1
find /tmp -type f -atime +2 -delete >/dev/null 2>&1
find /var/tmp -type f -atime +2 -delete >/dev/null 2>&1
EOF
chmod +x /usr/local/bin/system-reaper.sh

# 注册 Cron 定时项
cat > /etc/cron.d/system-reaper << 'EOF'
0 6,18 * * * root /usr/local/bin/system-reaper.sh >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/system-reaper

systemctl restart cron >/dev/null 2>&1 || systemctl restart crond >/dev/null 2>&1

# ==========================================
# 7. 终极无痕垃圾清理与启动引导纠偏 (置底保障)
# ==========================================
echo -e "\n---> 正在执行深层垃圾文件销毁与内核优先级纠偏..."

systemctl disable --now apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1

# 内核引导重构
rm -f /boot/*.bak /boot/*.old /boot/initrd.img-*.bak >/dev/null 2>&1
if command -v update-grub &> /dev/null; then
    update-grub >/dev/null 2>&1
fi

# 系统软垃圾清除
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/* >/dev/null 2>&1
rm -f /var/log/*.gz /var/log/*.[0-9] /var/log/*-???????? >/dev/null 2>&1
rm -rf /root/.cache/* /tmp/* /var/tmp/* >/dev/null 2>&1
journalctl --vacuum-size=5M >/dev/null 2>&1
journalctl --vacuum-time=1d >/dev/null 2>&1

# 彻底销毁 APT 更新源与二进制缓存 (必须放在本模块最后一步)
apt-get clean >/dev/null 2>&1
apt-get autoclean >/dev/null 2>&1
rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/cache/apt/*.bin >/dev/null 2>&1

# ==========================================
# 8. 网络状态嗅探 (纯净检查模式，零侵入)
# ==========================================
echo -e "\n---> 正在纯净嗅探 IPv6 当前环境连通性..."
if ping6 -c 2 -W 2 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo -e "[√] 当前网络状态：IPv6 正常可用"
else
    echo -e "[!] 当前网络状态：IPv6 不可用"
fi

# ==========================================
# 9. 网络吞吐与 BBR 拥塞控制优化
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
# 10. 生成系统与网络信息面板
# ==========================================
echo -e "\n---> 系统基础环境初始化与瘦身闭环完成！"
echo -e "正在收集系统信息生成最终面板，请稍候...\n"

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
echo -e "${CYAN}脚本版本 : ${WHITE}${SCRIPT_VERSION}${NC}"
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
