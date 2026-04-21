<#
.SYNOPSIS
    蓄水池抽样估算文件平均大小（改进版）
.DESCRIPTION
    固定内存开销，支持置信区间、扩展名分布和错误报告。
#>
param(
    [string]$Path = "E:\",
    [int]$SampleSize = 15000
)

# ---------- 1. 前置检查 ----------
if (-not (Test-Path -Path $Path)) {
    Write-Error "路径不存在: $Path"; return
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 明确类型，避免 object 装箱
$reservoir = [System.Collections.Generic.List[int64]]::new($SampleSize)
$extList   = [System.Collections.Generic.List[string]]::new($SampleSize)

$count = 0

Write-Host "[扫描中] $Path ..." -ForegroundColor Cyan

# ---------- 2. 流式遍历（带错误收集） ----------
Get-ChildItem -Path $Path -Recurse -File `
    -ErrorAction SilentlyContinue -ErrorVariable gciErrors | ForEach-Object {

    $count++
    $len = $_.Length

    # 蓄水池抽样核心
    if ($reservoir.Count -lt $SampleSize) {
        $reservoir.Add($len)
        $extList.Add($_.Extension.ToLower())
    } else {
        $j = Get-Random -Maximum $count
        if ($j -lt $SampleSize) {
            $reservoir[$j] = $len
            $extList[$j]   = $_.Extension.ToLower()
        }
    }

    # 进度：每2万文件或每3秒刷新一次
    if ($count % 20000 -eq 0) {
        $rate = if ($sw.Elapsed.TotalSeconds -gt 0) { [int]($count / $sw.Elapsed.TotalSeconds) } else { 0 }
        Write-Host ("`r  已扫描 {0:N0} 个文件 | {1:N0} 文件/秒" -f $count, $rate) -NoNewline -ForegroundColor DarkGray
    }
}

# ---------- 3. 错误报告 ----------
$errTotal = $gciErrors.Count
if ($errTotal -gt 0) {
    $denied = ($gciErrors | Where-Object { $_.Exception -is [System.UnauthorizedAccessException] }).Count
    Write-Host "`n`n⚠️  跳过错误: $errTotal 个（含 $denied 个访问被拒绝）" -ForegroundColor Yellow
}

Write-Host "`n`n完成：遍历 $count 个文件，成功抽样 $($reservoir.Count) 个`n" -ForegroundColor Green

# 空目录保护
if ($reservoir.Count -eq 0) { Write-Host "该路径下无文件，退出。" -ForegroundColor Red; return }

# ---------- 4. 统计计算 ----------
$reservoir.Sort()
$n = $reservoir.Count

# 平均值
$sum = [int64]0
foreach ($x in $reservoir) { $sum += $x }
$avg = [double]$sum / $n

# 中位数
$mid = [math]::Floor($n / 2)
$median = if ($n % 2 -eq 0) { ($reservoir[$mid - 1] + $reservoir[$mid]) / 2.0 } else { $reservoir[$mid] }

# 样本标准差（无偏估计 ÷ N-1）
$sqSum = [double]0
foreach ($x in $reservoir) { $d = $x - $avg; $sqSum += $d * $d }
$std = if ($n -gt 1) { [math]::Sqrt($sqSum / ($n - 1)) } else { 0 }

# 95% 置信区间（大样本正态近似）
$se = $std / [math]::Sqrt($n)
$margin = 1.96 * $se
$ciLow  = [math]::Max(0, $avg - $margin)
$ciHigh = $avg + $margin

# ---------- 5. 输出 ----------
Write-Host "========== 统计结果 ==========" -ForegroundColor DarkGray
Write-Host ("  平均大小 : {0:N2} KB ({1:N2} MB)" -f ($avg/1KB), ($avg/1MB)) -ForegroundColor Yellow
Write-Host ("  95% 置信 : [{0:N2}, {1:N2}] MB  (误差±{2:N2} MB)" -f ($ciLow/1MB), ($ciHigh/1MB), ($margin/1MB)) -ForegroundColor DarkCyan
Write-Host ("  中位大小 : {0:N2} KB ({1:N2} MB)" -f ($median/1KB), ($median/1MB)) -ForegroundColor Yellow
Write-Host ("  最小/最大: {0:N2} KB / {1:N2} GB" -f ($reservoir[0]/1KB), ($reservoir[-1]/1GB))
Write-Host ("  样本标准差: {0:N2} MB" -f ($std/1MB))
Write-Host "==============================`n" -ForegroundColor DarkGray

# ---------- 6. 大小分布 ----------
$buckets = @(
    @{Name="0 ~ 4 KB";     Max=4KB},
    @{Name="4 KB ~ 64 KB"; Max=64KB},
    @{Name="64 KB ~ 1 MB"; Max=1MB},
    @{Name="1 MB ~ 16 MB"; Max=16MB},
    @{Name="16 MB ~ 1 GB"; Max=1GB},
    @{Name="> 1 GB";       Max=[long]::MaxValue}
)
$prev = 0L
Write-Host "大小分布:" -ForegroundColor Cyan
foreach ($b in $buckets) {
    $c = 0
    for ($i = 0; $i -lt $n; $i++) {
        if ($reservoir[$i] -ge $prev -and $reservoir[$i] -lt $b.Max) { $c++ }
    }
    $pct = $c / $n * 100
    Write-Host ("  {0,-14} : {1,5:N1}%  {2}" -f $b.Name, $pct, ("#" * [math]::Round($pct / 2)))
    $prev = $b.Max
}

# ---------- 7. 扩展名分布（Top 5，基于样本） ----------
$extStats = @{}
foreach ($e in $extList) {
    $key = if ($e) { $e } else { "(无扩展名)" }
    $extStats[$key]++
}
Write-Host "`nTop 扩展名（样本）:" -ForegroundColor Cyan
$extStats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host ("  {0,-12} : {1,5:N1}%" -f $_.Key, ($_.Value / $n * 100))
}

# ---------- 8. 簇大小建议 ----------
$smallPct = 0
for ($i = 0; $i -lt $n; $i++) { if ($reservoir[$i] -lt 64KB) { $smallPct++ } }
$smallPct = $smallPct / $n * 100

Write-Host "`n💡 簇大小建议:" -ForegroundColor Green
if ($median -lt 8KB -or $smallPct -gt 50) {
    Write-Host "   小文件极多（$([math]::Round($smallPct,1))% < 64KB），强烈建议保持 4 KB"
} elseif ($median -lt 1MB) {
    Write-Host "   中位数在 8KB~1MB，建议 4 KB（SSD）或 8 KB（HDD）"
} elseif ($median -lt 32MB) {
    Write-Host "   中位数在 1MB~32MB，机械硬盘可考虑 16~32 KB；SSD 保持 4 KB"
} else {
    Write-Host "   大文件为主，机械硬盘建议 64 KB；SSD 保持 4 KB"
}
Write-Host ("`n耗时: {0:mm\:ss\.fff}" -f $sw.Elapsed) -ForegroundColor DarkGray