#!/usr/bin/env bash
#
# verify-stability.sh
#
# 在本机验证 CodeNetSDK 的构建稳定性 —— 也就是回归检测「macOS 27 上 SDK CLI 并发 GC 崩溃」。
#
# 为什么需要单独一个脚本：这个崩溃只在 macOS 27 + SIP/AMFI 关闭的环境上出现，
# GitHub Actions 的 macos-latest 复现不了，所以 CI 里加断言没有意义，只能在本机验。
# 崩溃形态（详见 assemble-codenet-sdk.sh 第 9 节）：
#     mark_object_simple1 <- GcStackCrawlCallBack <- EnumerateLiveSlots <- mark_phase
# 规避手段是关闭 SDK CLI 的并发 GC（组装脚本会自动打这个补丁）。
#
# 用法：
#   ./verify-stability.sh                 # 临时建个 console 工程，构建 20 次
#   ./verify-stability.sh --runs 50       # 加大样本
#   ./verify-stability.sh --project ./app # 用指定工程
#   ./verify-stability.sh --concurrent on # 临时打开 SDK CLI 的并发 GC（做 A/B 对照）
#   CODENET=/path/to/dotnet11x64/dotnet ./verify-stability.sh   # 指定被测 SDK
#
set -uo pipefail

RUNS=20
PROJECT=""
CONCURRENT=""
CODENET="${CODENET:-codenet}"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
die() { printf '::error::%s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --runs)       RUNS="${2:-20}"; shift 2 ;;
        --project)    PROJECT="${2:-}"; shift 2 ;;
        --concurrent) CONCURRENT="${2:-}"; shift 2 ;;
        -h|--help)    usage 0 ;;
        *) die "未知参数：${1}（--help 查看用法）" ;;
    esac
done

case "$CONCURRENT" in
    ""|on|off) ;;
    *) die "--concurrent 只接受 on / off（收到 $CONCURRENT）" ;;
esac

command -v "$CODENET" >/dev/null 2>&1 || die "找不到 ${CODENET} 命令（用 CODENET 指定路径）"

# 用绝对路径指向一套 CodeNetSDK 时必须自己补 DOTNET_ROOT：宿主 muxer 靠它定位
# shared/ 与 sdk/。不设的话 `new` 还可能成功，但 `build` 会整片失败（不是崩溃，是 rc=1），
# 会让统计里全是 E 而没有 X。
case "$CODENET" in
    */*) CODENET="$(cd "$(dirname "$CODENET")" && pwd)/$(basename "$CODENET")" ;;
esac
if [ -z "${DOTNET_ROOT:-}" ] && [ -f "$(dirname "$CODENET")/dotnet" ]; then
    export DOTNET_ROOT="$(dirname "$CODENET")"
fi

WORK=""
RC_BAK=""
RC_TARGET=""
cleanup() {
    if [ -n "$RC_BAK" ] && [ -n "$RC_TARGET" ] && [ -f "$RC_BAK" ]; then
        mv -f "$RC_BAK" "$RC_TARGET"
    fi
    [ -n "$WORK" ] && rm -rf "$WORK"
    return 0
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 0. 资源预检：SysV 信号量
# ---------------------------------------------------------------------------
# CoreCLR 的 PAL 为线程 semget 一个 IPC_PRIVATE 信号量集，进程被信号杀死时不会回收；
# 实测正常构建也会缓慢泄漏（~30 个/次）。池子吃干后**所有** .NET 进程（含官方运行时）都会
# 报 “Failed to create CoreCLR”，非常容易被误判成代码不稳定，所以先拦一道。
# 详见 cleanup-codenet-ipc.sh 的说明。
sem_usage() { # 输出 "已用 上限 百分比"
    local used max pct
    used="$(ipcs -s 2>/dev/null | awk -v u="$(id -un)" '$1=="s" && $5==u' | wc -l | tr -d ' ')"
    max="$(sysctl -n kern.sysv.semmni 2>/dev/null || echo 0)"
    if [ "${max:-0}" -gt 0 ] 2>/dev/null; then pct=$(( used * 100 / max )); else pct=0; fi
    echo "${used} ${max} ${pct}"
}
set -- $(sem_usage)
SEM_USED="$1"; SEM_MAX="$2"; SEM_PCT="$3"
CLEANUP_HINT="scripts/codenet-sdk/cleanup-codenet-ipc.sh --apply"
if [ "$SEM_PCT" -gt 90 ] 2>/dev/null; then
    die "SysV 信号量已用 ${SEM_USED}/${SEM_MAX}（${SEM_PCT}%），.NET 会全线起不来；先清理：$CLEANUP_HINT"
elif [ "$SEM_PCT" -gt 50 ] 2>/dev/null; then
    echo "::warning::SysV 信号量已用 ${SEM_USED}/${SEM_MAX}（${SEM_PCT}%），建议先跑 $CLEANUP_HINT"
fi

if [ -z "$PROJECT" ]; then
    WORK="$(mktemp -d)"
    echo "创建临时工程：$WORK/app"
    # 建工程这一步本身就可能被并发 GC 崩掉（实测 macOS 27 上 ~1/3 概率），重试即可。
    ok=0
    for _ in 1 2 3 4 5; do
        rm -rf "$WORK/app"
        if "$CODENET" new console -o "$WORK/app" -n StabilityProbe >/dev/null 2>&1; then ok=1; break; fi
    done
    [ "$ok" = 1 ] || die "codenet new console 连续失败，无法继续"
    PROJECT="$WORK/app"
fi
csproj="$(find "$PROJECT" -maxdepth 1 -name '*.csproj' -print -quit 2>/dev/null || true)"
[ -n "$csproj" ] || die "目录里没有 csproj：$PROJECT"

SDK_RC=""
if [ -n "${DOTNET_ROOT:-}" ] && [ -d "$DOTNET_ROOT/sdk" ]; then
    SDK_RC="$(find "$DOTNET_ROOT/sdk" -maxdepth 2 -name 'dotnet.runtimeconfig.json' -print -quit 2>/dev/null || true)"
fi

# --concurrent 直接改 SDK 自己的 runtimeconfig 再还原：环境变量 DOTNET_gcConcurrent
# 在 configProperties 已经写了同名键时不一定压得住，做 A/B 对照必须走文件才确定。
if [ -n "$CONCURRENT" ]; then
    [ -n "$SDK_RC" ] && [ -f "$SDK_RC" ] || die "--concurrent 需要定位到 SDK 的 dotnet.runtimeconfig.json（先设 DOTNET_ROOT）"
    want=$([ "$CONCURRENT" = "on" ] && echo true || echo false)
    RC_BAK="$SDK_RC.$$.bak"
    RC_TARGET="$SDK_RC"
    cp -p "$SDK_RC" "$RC_BAK"
    python3 - "$SDK_RC" "$want" <<'PYEOF' || die "改写 runtimeconfig 失败（需要 python3）"
import json, sys
path, value = sys.argv[1], sys.argv[2] == "true"
with open(path) as fh:
    cfg = json.load(fh)
props = cfg.setdefault("runtimeOptions", {}).setdefault("configProperties", {})
props["System.GC.Concurrent"] = value
with open(path, "w") as fh:
    json.dump(cfg, fh, indent=2)
    fh.write("\n")
PYEOF
    echo "已临时把 SDK CLI 的并发 GC 设为 ${want}（脚本退出时还原）"
fi

echo "被测 SDK ：${DOTNET_ROOT:-<未知>}"
if [ -n "$SDK_RC" ]; then
    echo "SDK 配置 ：$SDK_RC"
    echo "并发 GC  ：$(grep -o '"System.GC.Concurrent": *[a-z]*' "$SDK_RC" | tail -1 | sed 's/.*: *//')"
fi
echo "工程     ：$PROJECT"
echo "轮数     ：$RUNS"
echo

crashes=0   # 被信号打死（SIGSEGV=139 / SIGBUS=138 / SIGABRT=134）
errors=0    # 正常非零退出（编译错误等），不算崩溃
printf '进度：'
for _ in $(seq 1 "$RUNS"); do
    rm -rf "$PROJECT/obj" "$PROJECT/bin"
    # 必须在工程目录下执行，否则 MSBuild 找不到 csproj（MSB1003），会被算成 E 而不是崩溃。
    ( cd "$PROJECT" && "$CODENET" build -c Release ) >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ge 128 ]; then
        crashes=$((crashes + 1)); printf 'X'
    elif [ "$rc" -ne 0 ]; then
        errors=$((errors + 1)); printf 'E'
    else
        printf '.'
    fi
done
echo
echo

rate=$(awk -v c="$crashes" -v n="$RUNS" 'BEGIN{printf "%.0f", 100*c/n}')
echo "崩溃 $crashes/$RUNS (${rate}%)   其他失败 $errors/$RUNS"

# 收尾再看一眼信号量：跑之前 ${SEM_USED} 个，跑完剩多少。正常会小幅上涨（每次构建漏几十个），
# 若一次涨几千，说明有进程在异常终止。
set -- $(sem_usage)
echo "SysV 信号量：${SEM_USED} -> ${1}/${2}（${3}%）  超过 50% 时用 $CLEANUP_HINT 清理"

if [ "$crashes" -gt 0 ]; then
    echo "::error::检测到信号崩溃 —— SDK CLI 的并发 GC 大概率没关，检查 sdk/<ver>/dotnet.runtimeconfig.json"
    exit 1
fi
if [ "$errors" -gt 0 ]; then
    echo "::warning::有 $errors 次非崩溃失败，请确认工程本身能正常编译"
fi
echo "通过：$RUNS 次构建无崩溃"
exit 0
