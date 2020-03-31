cls

#File processing
$packageName = "JADOperation"

$rootDirectory = "C:\AOSService\PackagesLocalDirectory\$packageName"
$outputFile = "C:\Temp\$packageName-Error.csv"

$results = Get-ChildItem -Path $rootDirectory -Filter BuildModelResult.log -Recurse -ErrorAction SilentlyContinue -Force
$objects = @()

foreach ($result in $results)
{
    try
    {
        $errorText = Select-String -LiteralPath $result.FullName -Pattern '(^.*) Error: (.*)' | ForEach-Object {$_.Line}
        # Skip modules that do not have errors
        if ($errorText)
        {
            Write-Host "Processing $($result.DirectoryName)\$($result.Name) "# -NoNewline
        
            foreach ($line in $errorText)
            {
                # Remove positioning text in the format of "[(5,5),(5,39)]: " for methods
                if ($line -match '(?=\[\().*(?=\)\])')
                {
                    $lineReplaced = [regex]::Split($line, '(.*)(?=\[\().*(?:\)\]: )(.*)')
                    $line = $lineReplaced[1] + $lineReplaced[2]
                }

                try
                {
                    # Regular expression matching to split line details into groups
                    $regex = '(?:Compile Fatal|MetadataProvider|Metadata|Compile|Unspecified|Generation) (Error): (Query Method|Interface Method|Form Method LocalFunction|Form Control Method|Form Datasource Method|Form DataSource Method|Form DataSource DataField Method|Form Method|Map Method|Class Delegate|Table Method LocalFunction|Class Method LocalFunction|Table Method|Class Method|Table|Class|View|Form|)(?: |)(?:dynamics:|)(.*)(?:: )(.*)'
                
                    $Matches = [regex]::split($line, $regex)
                    $object = [PSCustomObject]@{
                        ErrorType  = $Matches[1].trim()
                        ObjectType = $Matches[2].trim()
                        Path       = $Matches[3].trim()
                        Text       = $Matches[4].trim()
                    }# | ft

                    # Store all entries
                    $objects += $object
                }
                catch
                {
                    Write-Host "Error during processing line <" -ForegroundColor Yellow -NoNewline
                    Write-Host "$line" -ForegroundColor Red -NoNewline
                    Write-Host ">" -ForegroundColor Yellow
                    #Write-Host $regex
                }
                #break
            }
        }
    }
    catch
    {
        Write-Host
        Write-Host "Error during processing"
    }
}

# Write output to CSV
$objects | export-csv -Path $outputFile -NoTypeInformation
