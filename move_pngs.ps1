$i = 1
Get-ChildItem -Path *.png | Where-Object { $_.Length -gt 1000000 } | ForEach-Object {
    $img = $_.Name
    $newName = "tpl_user_$i"
    $dir = "Assets.xcassets\$newName.imageset"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Copy-Item -Path $img -Destination "$dir\$newName.png"
    $json = @{
        images = @(
            @{
                idiom = "universal"
                filename = "$newName.png"
            }
        )
        info = @{
            version = 1
            author = "xcode"
        }
    } | ConvertTo-Json -Depth 5
    Set-Content -Path "$dir\Contents.json" -Value $json -Encoding UTF8
    Write-Host "Moved $img to $newName"
    $i++
}
