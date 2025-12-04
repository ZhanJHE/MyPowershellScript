# 定义要测试的DNS服务器列表。这里使用一个哈希表（字典），键是IP地址，值是服务器名称。
$DnsServers = @{
    "223.5.5.5"      = "AliDNS";
    "119.29.29.29"   = "DNSPod";
    "1.1.1.1"        = "CloudFlare";
    "114.114.114.114" = "114DNS";
    "8.8.8.8"        = "Google";
}

# 定义要查询的网站域名列表。
$Websites = "github.com", "netflix.com", "youtube.com", "bilibili.com", "baidu.com", "google.com", "microsoft.com"

# 打印脚本开始的提示信息。
Write-Host "=================================================="
Write-Host "正在开始DNS查询测试..."
Write-Host "=================================================="
Write-Host ""

# 创建一个空数组，用于存储所有查询结果的对象。
$results = @()

# 遍历每一个需要测试的网站。
foreach ($website in $Websites) {
    # 在屏幕上打印当前正在测试的域名，给用户反馈。
    Write-Host "正在测试域名: $website"
    
    # 遍历每一个DNS服务器。
    foreach ($server in $DnsServers.GetEnumerator()) {
        # 格式化DNS服务器的名称，方便后续显示。
        $dnsServerName = "$($server.Value) ($($server.Key))"
        
        # 使用 try...catch 块来捕获可能发生的错误，例如DNS查询超时。
        try {
            # 使用 Measure-Command 来测量DNS查询所花费的时间。
            $measurement = Measure-Command {
                # 使用 Resolve-DnsName cmdlet 执行DNS查询。
                # -DnsOnly 参数确保只使用DNS协议，避免了LLMNR和NetBIOS等本地名称解析。
                # -ErrorAction Stop 表示如果发生错误，则立即停止并跳转到 catch 块。
                $dnsResult = Resolve-DnsName -Name $website -Server $server.Key -DnsOnly -ErrorAction Stop
            }
            
            # 如果查询成功并返回了结果。
            if ($dnsResult) {
                # 一个域名可能解析出多个记录（例如多个A记录），所以需要遍历所有返回的记录。
                foreach ($record in $dnsResult) {
                    # 创建一个自定义的PowerShell对象 (PSCustomObject) 来存储本次查询的详细结果。
                    $results += [PSCustomObject]@{
                        Domain         = $website
                        DNSServer      = $dnsServerName
                        RecordType     = $record.Type
                        IPAddress      = $record.IPAddress
                        ResponseTimeMs = [math]::Round($measurement.TotalMilliseconds) # 将响应时间四舍五入到毫秒。
                    }
                }
            }
        } catch {
            # 如果 try 块中发生错误，则执行这里的代码。
            # 清理错误信息中的换行符，使其在表格中能正确显示。
            $errorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            # 创建一个表示错误结果的对象。
            $results += [PSCustomObject]@{
                Domain         = $website
                DNSServer      = $dnsServerName
                RecordType     = "错误"
                IPAddress      = $errorMessage
                ResponseTimeMs = "N/A" # 响应时间不适用。
            }
        }
    }
}

# 所有查询完成后，将结果数组通过管道传递给 Format-Table。
# Format-Table 会将对象数组格式化为易于阅读的表格。
# -AutoSize 参数会自动调整列宽以适应内容。
$results | Format-Table -AutoSize

# 打印脚本结束的提示信息。
Write-Host "=================================================="
Write-Host "DNS查询测试完成。"
Write-Host "=================================================="
Write-Host ""
