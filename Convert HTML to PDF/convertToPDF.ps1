####################################################
# Notion HTML to PDF print with single page layout #
# Vilmos Kintera                                   #
# Version 1.0 - 2023-03-05                         #
####################################################

# CHANGE THESE VARIABLES -->
$inputFile = 'C:\temp\yourinputfile.html'

$pdfOutputPath = 'c:\temp\'
$marginInPixels = 10
$removeHeader = $true # $false or $true
# CHANGE THESE VARIABLES <--


$pdfOutputFile = $pdfOutputPath + "$([System.IO.Path]::GetFileNameWithoutExtension($inputFile)).pdf"


# Initial details
Clear-Host

Write-Host "PDF output location: " -NoNewline
Write-Host $pdfOutputPath -ForegroundColor Green

# Inject print, width and margin fix to HTML
$injectHTML = @"
<!-- Make HTML to fill the entire page, and have a noPrint attribute -->
<style>
  html, body {
    width:  fit-content !important;
    height: fit-content !important;
    margin:  10px !important;
    padding: 0px !important;
    line-height: unset !important;
  }
  @media print {
    .noPrint {
      display:none;
    }
  }
</style>
<!-- Dummy value for page size -->
<style id="page_style">
  @page { size: 1400px 1000px; margin: $($marginInPixels)px; }
</style>
<script>
// Update page width and hight to be the actual document size
window.addEventListener("load", (event) => {
   renderBlock = document.getElementsByTagName("html")[0];
   renderBlockInfo = window.getComputedStyle(renderBlock);
   // fix chrome page bug
   fixHeight = parseInt(renderBlockInfo.height) + 1 + "px";
   pageCss = ``@page { size: `${renderBlockInfo.width} `${fixHeight}; margin: $($marginInPixels)px;}``;
   console.log(pageCss);
   document.getElementById("page_style").innerHTML = pageCss;
});
</script>
</head>
"@

# Replace the HTML block in the file
$htmlCode = Get-Content $inputFile -raw | Foreach-Object {
    $_  -replace '</head>', $injectHTML `
        -replace '<header>', (&{If($removeHeader -eq $true) {'<header class="noPrint">'} Else {'<header>'}})
}

$fixedFile = "$pdfOutputPath" + "fixed.html"
$htmlCode | Set-Content -Path $fixedFile


# Get Chrome install location
$key = 'HKLM:\SOFTWARE\Classes\ChromeHTML\shell\open\command'
$res = (Get-Item -Path $key).GetValue("") -replace " *--.*", ""

Write-Host "Found chrome in: " -NoNewline
Write-Host $res -ForegroundColor Green

if ($res -eq $null)
{
    throw "Chrome is not found via registry"
}

# Generate PDF output with Chrome Headless
$argumments = '--headless',"--print-to-pdf=`"$pdfOutputFile`"","`"$fixedFile`""
Write-Host "Running Chrome Print-To-PDF: " -NoNewLine
Write-Host $argumments -ForegroundColor Green

Start-Process "$res" -ArgumentList $argumments -NoNewWindow -Wait

# Cleanup
Remove-Item $fixedFile

Write-Host "Completed" -ForegroundColor Yellow

# Display generated PDF
Start-Process ((Resolve-Path $pdfOutputFile).Path)
