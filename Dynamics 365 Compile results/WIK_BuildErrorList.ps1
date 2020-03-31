cls

$displayErrorsOnly = $false # $true # $false
$rootDirectory = "C:\AOSService\PackagesLocalDirectory"

$results = Get-ChildItem -Path $rootDirectory -Filter BuildModelResult.log -Recurse -Depth 1 -ErrorAction SilentlyContinue -Force
$totalErrors = 0
$totalWarnings = 0

foreach ($result in $results)
{
    try
    {
        $errorText = Select-String -LiteralPath $result.FullName -Pattern ^Errors: | ForEach-Object {$_.Line}
        $errorCount = [int]$errorText.Split()[-1]
        $totalErrors += $errorCount

        $warningText = Select-String -LiteralPath $result.FullName -Pattern ^Warnings: | ForEach-Object {$_.Line}
        $warningCount = [int]$warningText.Split()[-1]
        $totalWarnings += $warningCount

        if ($displayErrorsOnly -eq $true -and $errorCount -eq 0)
        {
            continue
        }

        Write-Host "$($result.DirectoryName)\$($result.Name) " -NoNewline
        if ($errorCount -gt 0)
        {
            Write-Host " $errorText" -NoNewline -ForegroundColor Red
        }
        if ($warningCount -gt 0)
        {
            Write-Host " $warningText" -ForegroundColor Yellow
        }
        else
        {
            Write-Host
        }
    }
    catch
    {
    Write-Host
    Write-Host "Error during processing"
    }
}

Write-Host "Total Errors: $totalErrors" -ForegroundColor Red
Write-Host "Total Warnings: $totalWarnings" -ForegroundColor Yellow
