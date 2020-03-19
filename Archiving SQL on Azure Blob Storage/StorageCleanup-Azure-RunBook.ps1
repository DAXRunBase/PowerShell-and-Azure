# Azure Automation RunBook
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'

$StorageAccountName = "yourbackupstorageaccount"
$storageKey = "yourstorageaccountkey"

$connectionName = "AzureRunAsConnection"
$SubscriptionName = 'Backups'

$DaysOld = 31

# Get the Azure connection asset that is stored in the Automation service based on the name that was passed into the runbook  
$azureConn = Get-AutomationConnection -Name $connectionName 

if ($azureConn -eq $null) 
{ 
    throw "Could not retrieve '$connectionName' connection asset. Check that you created this first in the Automation service." 
} 

Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $azureConn.TenantId `
    -ApplicationId $azureConn.ApplicationId `
    -CertificateThumbprint $azureConn.CertificateThumbprint

# Get the Azure management certificate that is used to connect to this subscription 
$Certificate = Get-AutomationCertificate -Name 'AzureRunAsCertificate'
if ($Certificate -eq $null) 
{ 
    throw "Could not retrieve '$azureConn.AutomationCertificateName' certificate asset. Check that you created this first in the Automation service." 
}

# Set the Azure subscription configuration 
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

Get-AzureRmStorageAccount | Select-Object StorageAccountName,CreationTime
$storageAccount = Get-AzureRmStorageAccount

$storageContainer = Get-AzureStorageContainer -Name "daxsql-backup" -Context $storageAccount.Context

foreach ($container in $storageContainer)
{
    Write-Output ("Searching Container: {0}" -f $container.Name)
    $blobs = Get-AzureStorageBlob `
        -Container $container.Name `
        -Context $storageAccount.Context
        #-MaxCount 5000
        #-Blob "*AxaptaLive*.bak"

    if ($blobs -ne $null)
    {
        $currentCount = 0

        ForEach ($blob in $blobs)
        {
            $currentCount += 1
            $lastModified = $blob.LastModified.UtcDateTime
            if ($lastModified -ne $null)
            {
                $blobDays = ([DateTime]::Now - [DateTime]$lastModified)

                # Process blobs that are older than the minimum keep date
                if ($blobDays.Days -gt $DaysOld)
                {
                    $fileName = [string][io.path]::GetFileNameWithoutExtension($blob.Name)

                    # Our files are starting with an EN prefix, remove if you do not need it
                    #if (($fileName.StartsWith("EN")) -And ($blob.Name -NotMatch '(?=\/FULL\/)'))
                    if ($fileName.StartsWith("EN"))
                    {
                        # File names must contain creation date from SQL Backup tool as YYYYMMDD, split it with regular expression
                        $regex = '(?<filedate>\d{4}(?:\.|-|_)?\d{2}(?:\.|-|_)?\d{2})[^0-9]'
                        try
                        {
                            if ($fileName -match $regex) {
                                $date = $Matches['filedate'] -replace '(\.|-|_)',''
                                $date = [datetime]::ParseExact( `
                                    $date, `
                                    'yyyyMMdd', `
                                    [cultureinfo]::InvariantCulture
                                    )
                            }

                            # Keep blobs which are in the first week of every quarter
                            $canDelete = $true
                            
                            if (($blob.Name -Match '(?=\/FULL\/)') -And ((($date.DayOfYear -in 1..7) `
                                    -Or ($date.DayOfYear -in 92..98) `
                                    -Or ($date.DayOfYear -in 183..189) `
                                    -Or ($date.DayOfYear -in 274..280))) `
                                    -And ($blobDays.Days -lt 366)) # Allow deleting files older than a year
                            {
                                $canDelete = $false
                            }
                        }
                        catch
                        {
                            Write-Error ("Exception while running Regular Expression")
                        }

                        if ($canDelete)
                        {
                            Write-Output ("[{0}/{1} ({2})] {3} AGE: {4} STAMP: {5}" -f $blobs.count, $currentCount, $blobsRemoved, $blob.Name, $blobDays, [DateTime]$date)
                            try
                            {
                                Remove-AzureStorageBlob -Blob $blob.Name -Container $container.Name -Context $storageAccount.Context
                                $blobsremoved += 1
                            }
                            catch
                            {
                                Write-Error ("Exception when trying to delete file {0}" -f $blob.Name)
                            }
                        }
                        else
                        {
                            Write-Output ("[{0}/{1} ({2})] ***KEEPING BLOB*** {3} AGE: {4} STAMP: {5}" -f $blobs.count, $currentCount, $blobsRemoved, $blob.Name, $blobDays, [DateTime]$date)
                        }
                    }
                    else
                    {
                        Write-Verbose ("[{0}/{1} ({2})] Skipping blob due to EN* or FULL mask: {3}" -f $blobs.count, $currentCount, $blobsRemoved, $blob.Name)
                    }
                }
                else
                {
                    Write-Verbose ("[{0}/{1} ({2})] Skipping blob due to age: {3}" -f $blobs.count, $currentCount, $blobsRemoved, $blob.Name)
                }
            }
            else
            {
                Write-Error ("[{0}/{1} ({2})] ERROR: Blob {3} has no modified date!" -f $blobs.count, $currentCount, $blobsRemoved, $blob.Name)
            }
        } 
    }
}
