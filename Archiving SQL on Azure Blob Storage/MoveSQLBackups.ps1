$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(512,80)
$VerbosePreference = 'Continue'

Start-Transcript -Path "U:\backuplog.txt" -Append -Verbose

$totalElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()
$sourceFolder = 'U:\Backup'
$targetFolder = '\\NetworkStorageUNCPATH\Backup'

$sourceInstances = Get-ChildItem -Directory $sourceFolder

foreach ($instance in $sourceInstances)
{
    $sourceInstance = Join-Path -Path $sourceFolder -ChildPath $instance
    $sourceDatabases = Get-ChildItem -Directory $sourceInstance

    foreach ($database in $sourceDatabases)
    {
        $ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()
        $sourceDatabase = Join-Path -Path $sourceInstance -ChildPath $database
        $targetDatabase = Join-Path -Path $targetFolder -ChildPath $instance\$database
        Write-Host "Moving $sourceDatabase\* to $targetDatabase ... " -NoNewline
        Write-Output "Moving $sourceDatabase\* to $targetDatabase ... "
        Move-Item -Path "$sourceDatabase\*" -Destination $targetDatabase | Write-Output
        Write-Host "Done" -ForegroundColor Yellow | Write-Output
 	    Write-Host "Elapsed Time: $($ElapsedTime.Elapsed.ToString())"
 	    Write-Output "Elapsed Time: $($ElapsedTime.Elapsed.ToString())"
    }
}

Write-Host "Total Elapsed Time: $($totalElapsedTime.Elapsed.ToString())"
Write-Output "Total Elapsed Time: $($totalElapsedTime.Elapsed.ToString())"

Stop-Transcript
