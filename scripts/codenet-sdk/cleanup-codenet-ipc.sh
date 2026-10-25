#!/usr/bin/env bash
#
# cleanup-codenet-ipc.sh
#
# 清理 CoreCLR 泄漏的 SysV 信号量集。
#
# 背景（2026-10-25 实测）：CoreCLR 的 PAL 为需要“挂起信息”的线程 semget(IPC_PRIVATE) 一个
# 信号量集，正常线程退出时会 semctl(IPC_RMID) 回收，但进程被 abort / 信号杀死时不会回收
# （SEM_UNDO 只回滚 semop 操作，不删除集合）。CodeNet 在 macOS 27 上曾因并发 GC 崩溃被反复
# 重启，累计泄漏 7 万多个集合，把 kern.sysv.semmni（本机 87381）吃到 83%，之后**所有** .NET
# 进程（含官方运行时）都报 “Failed to create CoreCLR”，表现为整机 .NET 全线不可用。
#
# 即使构建不崩溃也会缓慢泄漏：实测 20 轮 `codenet build` 泄漏 ~600 个集合（约 30 个/次）。
# 所以占用率超过 50% 时应当清理一次。
#
# 只删除：owner = 当前用户、key = 0x00000000（IPC_PRIVATE）的集合。
# 其他 key（通常是正在运行的程序用 ftok 创建的共享信号量）一律不动。
#
# 用法：
#   ./cleanup-codenet-ipc.sh              # 只统计，不删除（默认 dry-run）
#   ./cleanup-codenet-ipc.sh --apply      # 真正删除（要求没有存活的 .NET 进程）
#
set -uo pipefail

APPLY=0
usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[cleanup-ipc] %s\n' "$*"; }
die() { printf '[cleanup-ipc] ::error::%s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --apply)  APPLY=1; shift ;;
        -h|--help) usage 0 ;;
        *) die "未知参数：${1}（--help 查看用法）" ;;
    esac
done

ME="$(id -un)"
MAX="$(sysctl -n kern.sysv.semmni 2>/dev/null || echo 0)"

usage_pct() { # 输出当前用户的 semset 占用与百分比
    local used pct
    used="$(ipcs -s 2>/dev/null | awk -v u="$ME" '$1=="s" && $5==u' | wc -l | tr -d ' ')"
    if [ "${MAX:-0}" -gt 0 ] 2>/dev/null; then
        pct=$(( used * 100 / MAX ))
    else
        pct=0
    fi
    echo "当前 sysv 信号量：${used}/${MAX}（${pct}%）"
}

# 泄漏的候选：当前用户 + IPC_PRIVATE。ipcs 的列是 T ID KEY MODE OWNER GROUP。
candidates() {
    ipcs -s 2>/dev/null | awk -v u="$ME" '$1=="s" && $3=="0x00000000" && $5==u {print $2}'
}

usage_pct

if [ "$APPLY" = 0 ]; then
    n="$(candidates | wc -l | tr -d ' ')"
    log "dry-run：将删除 ${n} 个 IPC_PRIVATE 信号量集（加 --apply 才会真删）"
    [ "$n" -gt 0 ] && candidates | head -5 | sed 's/^/  semid /'
    exit 0
fi

# 有存活的 .NET 进程时拒绝：删掉它们正在用的信号量会让这些进程直接崩掉。
live="$(ps -Ao pid=,comm= | awk '{n=split($2,a,"/"); b=a[n];
    if (b ~ /^(dotnet|codenet|MChub\.Desktop|VBCSCompiler|MSBuild)$/) print "  " $1 "  " $2}')"
if [ -n "$live" ]; then
    printf '%s\n' "$live" >&2
    die "仍有存活的 .NET 进程，先退出它们（或等构建结束）再加 --apply"
fi

ids="$(candidates)"
n="$(printf '%s\n' "$ids" | wc -l | tr -d ' ')"
[ -n "$(printf '%s' "$ids" | tr -d ' \n')" ] || n=0
log "准备删除 ${n} 个信号量集"
deleted=0
failed=0
while IFS= read -r id; do
    [ -n "$id" ] || continue
    if ipcrm -s "$id" 2>/dev/null; then
        deleted=$((deleted + 1))
    else
        failed=$((failed + 1))
    fi
done <<EOF
$ids
EOF

log "已删除 ${deleted} 个，失败 ${failed} 个"
# 失败的通常是「已标记删除、但仍有引用」的残留，重启后自然清空，不用管。
[ "$failed" -gt 0 ] && log "提示：失败的集合多为已标记删除但内核尚未回收的残留；若占用率仍 > 50%，重启一次即可彻底清干净"
usage_pct
exit 0
