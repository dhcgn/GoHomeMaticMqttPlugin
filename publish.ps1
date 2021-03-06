<#

.SYNOPSIS
Build a Go application to various platforms

.DESCRIPTION


.EXAMPLE


.NOTES
Don't move this script, is must be in the same folder as main.go.

.LINK
https://github.com/dhcgn/GoTemplate

#>

if ((Get-Command Go -ErrorAction Ignore) -eq $null) {
    Write-Error "Couldn't find Go, is PATH to Go missing?"
    return
}

$appName = "GoHomeMaticMqtt"
$version = Get-Content -Path .\packaging\VERSION
$publishFolder = "publish"
$debugFolder = "debug"
$compressPublish = $false

$rootFolder = Split-Path -parent $PSCommandPath
$upx = [System.IO.Path]::Combine($rootFolder, "build", "tools", "upx.exe" )

# Just uncomment the platfoms you don't need
$platforms = @()
$platforms += @{GOOS = "windows"; GOARCH = "amd64"; }
#$platforms += @{GOOS = "windows"; GOARCH = "386"; }
#$platforms += @{GOOS = "linux"; GOARCH = "amd64"; }
#$platforms += @{GOOS = "linux"; GOARCH = "386"; }
$platforms += @{GOOS = "linux"; GOARCH = "arm"; }
# $platforms += @{GOOS = "linux"; GOARCH = "arm64"; }
# $platforms += @{GOOS = "darwin"; GOARCH = "amd64"; }

# Clean Up

Remove-Item -Path ([System.IO.Path]::Combine($rootFolder, "build", $publishFolder)) -Recurse -ErrorAction Ignore
Remove-Item -Path ([System.IO.Path]::Combine($rootFolder, "build", $debugFolder)) -Recurse -ErrorAction Ignore

# Build
$count = 0
$maxCount = $platforms.Count * 2
if($compressPublish)
{
    $maxCount += $platforms.Count
}

foreach ($item in $platforms ) {
    # Write-Host "Build" $item.GOOS $item.GOARCH  -ForegroundColor Green
    Write-Progress -Activity ("Build $($item.GOOS) $($item.GOARCH)")  -PercentComplete ([Double]$count / $maxCount * 100)
    

    $env:GOOS = $item.GOOS
    $env:GOARCH = $item.GOARCH

    if ($item.GOOS -eq "windows") {
        $extension = ".exe"
    }
    else {
        $extension = $null
    }
        
    $buildCode = (Join-Path -Path $rootFolder "cmd\hm2mqtt\")
   
    $count += 1
    Write-Progress -Activity ("Build $($item.GOOS) $($item.GOARCH)") -Status "Build publish" -PercentComplete ([Double]$count / $maxCount * 100)

    $buildOutput = ([System.IO.Path]::Combine( $rootFolder, "build", $publishFolder, ("{0}_{1}_{2}{3}" -f $appName, $item.GOOS, $item.GOARCH, $extension)))
    $executeExpression = "go build -ldflags ""-s -w -X main.version={0}"" -trimpath -o {1} {2}" -f $version, $buildOutput, $buildCode 
    Write-Host "Execute", $executeExpression -ForegroundColor Green
    Invoke-Expression $executeExpression
    if ($LASTEXITCODE -ne 0){
        Write-Host "ERROR" -ForegroundColor Red
    }

    if ($compressPublish) {
        $count += 1
        Write-Progress -Activity ("Build $($item.GOOS) $($item.GOARCH)") -Status "Compress publish" -PercentComplete ([Double]$count / $maxCount * 100)
       
        $executeExpression =  "$upx --lzma $buildOutput -q"
        Write-Host "Execute", $executeExpression -ForegroundColor Green
        Invoke-Expression -Command $executeExpression >> $null
    }

    $count += 1
    Write-Progress -Activity ("Build $($item.GOOS) $($item.GOARCH)") -Status "Build debug" -PercentComplete ([Double]$count / $maxCount * 100)

    $buildOutput = ([System.IO.Path]::Combine( $rootFolder, "build", $debugFolder, ("{0}_{1}_{2}{3}" -f $appName, $item.GOOS, $item.GOARCH, $extension)))
    $executeExpression = "go build -ldflags ""-X main.version={0}"" -o {1} {2}" -f $version, $buildOutput, $buildCode 
    Write-Host "Execute", $executeExpression -ForegroundColor Green
    Invoke-Expression $executeExpression
    if ($LASTEXITCODE -ne 0){
        Write-Host "ERROR" -ForegroundColor Red
    }
}

Write-Host "Done!" -ForegroundColor Green