# Clean up previous AzCopy journal executions
Remove-Item "$env:USERPROFILE\AppData\Local\Microsoft\Azure\AzCopy\*.jnl"

# Reset Archive bits
#.\Clear-ArchiveBit.ps1 -Filter "*.bak" -Path "U:\Backup" -Recurse
#.\Clear-ArchiveBit.ps1 -Filter "*.trn" -Path "U:\Backup" -Recurse

# /@ Use parameter file
# /S Recursive processing
# /Y No prompt
# Table type blob only: /EntityOperation:"InsertOrSkip"
# /XO exclude same or older blob
# /BlobType:block

# get reference date (8th oldest full backup file)
$dir = 'U:\Backup\AlwaysOnCluster\AXDatabaseName\FULL\'
$latest = Get-ChildItem -Path $dir | Sort-Object CreationTime -Descending | Select-Object -Skip 7 -First 1
$RefDate = $latest.CreationTime
if(!$RefDate)
{
    $RefDate = Get-Date
}

# Copy transaction logs
$args = '/@:"U:\Backup\AzCopyTRN.txt" /V:"U:\Backup\AzCopy_' + "$(Get-Date -Format 'yyyy-MM-dd').txt"
$p = Start-Process 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' -ArgumentList $args -wait

# Copy backup files
$args = '/@:"U:\Backup\AzCopyBAK.txt" /V:"U:\Backup\AzCopy_' + "$(Get-Date -Format 'yyyy-MM-dd').txt"
$p = Start-Process 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' -ArgumentList $args -wait

# Remove files which were successfully copied
$dir = 'U:\Backup\ENF-DAXCluster1$DAXSQLAG\AxaptaLive\' 
Get-ChildItem $Dir -Include '*.bak','*.trn' -Recurse | Where-Object { $_.CreationTime -lt $RefDate } | Remove-Item
