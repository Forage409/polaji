$images = @(
    "真心话大冒险.png",
    "谁最像老板.png",
    "群聊判官.png",
    "好友投票局.png",
    "谁最容易脱单.png",
    "谁最会熬夜.png",
    "今日摸鱼人设卡.png",
    "谁最像隐藏富豪.png"
)

foreach ($img in $images) {
    if (Test-Path $img) {
        $name = [io.path]::GetFileNameWithoutExtension($img)
        $dir = "Assets.xcassets\$name.imageset"
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Copy-Item -Path $img -Destination "$dir\$img"
        $json = @{
            images = @(
                @{
                    idiom = "universal"
                    filename = $img
                }
            )
            info = @{
                version = 1
                author = "xcode"
            }
        } | ConvertTo-Json -Depth 5
        Set-Content -Path "$dir\Contents.json" -Value $json -Encoding UTF8
        Write-Host "Moved $img to Assets"
    } else {
        Write-Host "File not found: $img"
    }
}
