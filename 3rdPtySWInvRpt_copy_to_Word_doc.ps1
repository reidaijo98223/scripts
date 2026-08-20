# ==============================================================================
# CONFIGURATION AND PATHS
# ==============================================================================
$Url = "https://nexus.abc.com/third-party/3PS/3rdPtySoftwareInventoryReport.csv"
$LocalCsvPath = "$env:TEMP\DownloadedReport.csv"
$LocalDocxPath = "$env:lyn-reinogar\Desktop\3rdPtySoftwareInventoryReport.docx"

# Email Configuration
$SmtpServer = "exch-smtp.abc.com"
$SmtpPort = 25 
$ToAddress = "reino.garcia@gmail.com"
$FromAddress = "reino.garcia@gmail.com" #
$Subject = "Third Party Software Inventory Report"
$Body = "Hi Reino,`n`nPlease find attached the formatted Software Inventory Report."

# ==============================================================================
# STEP 1: DOWNLOAD AND ENFORCE COMMA DELIMITATION
# ==============================================================================
Write-Host "Downloading CSV securely from Nexus..." -ForegroundColor Cyan
Invoke-RestMethod -Uri $Url -OutFile $LocalCsvPath

# Import the data and re-export it to guarantee strict comma-delimited formatting
$Data = Import-Csv -Path $LocalCsvPath
$Data | Export-Csv -Path $LocalCsvPath -Delimiter ',' -NoTypeInformation -Encoding UTF8

# ==============================================================================
# STEP 2: GENERATE FORMATTED WORD DOCUMENT WITH 0.5" MARGINS
# ==============================================================================
Write-Host "Creating Word Document..." -ForegroundColor Cyan
$Word = New-Object -ComObject Word.Application
$Word.Visible = $false # Run in background

$Doc = $Word.Documents.Add()
$Selection = $Word.Selection

# Set Page Layout to Landscape
$Doc.PageSetup.Orientation = [Microsoft.Office.Interop.Word.WdOrientation]::wdOrientLandscape

# Set Margins to 0.5 Inches (Word COM requires points; 1 inch = 72 points, so 0.5" = 36 points)
$Doc.PageSetup.TopMargin = 36
$Doc.PageSetup.BottomMargin = 36
$Doc.PageSetup.LeftMargin = 36
$Doc.PageSetup.RightMargin = 36

# Set Font properties to Calibri 8pt
$Selection.Font.Name = "Calibri"
$Selection.Font.Size = 8

# Convert the CSV raw text into a string format for Word
$CsvText = Get-Content -Path $LocalCsvPath | Out-String
$Selection.TypeText($CsvText)

# Select all injected text and convert it into a clean Word Table
$Range = $Doc.Content
$Separator = ","
$Table = $Range.ConvertToTable($Separator)

# Auto-fit table to margins so it scales elegantly across landscape orientation
$Table.AutoFitBehavior([Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitWindow)

# ==============================================================================
# STEP 3: SAVE AND CLEAN UP COM OBJECTS
# ==============================================================================
Write-Host "Saving document locally to $LocalDocxPath..." -ForegroundColor Cyan
if (Test-Path $LocalDocxPath) { Remove-Item $LocalDocxPath -Force }
$Doc.SaveAs([ref]$LocalDocxPath)
$Doc.Close()
$Word.Quit()

# Force garbage collection to release MS Word system locks
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word) | Out-Null
Remove-Item $LocalCsvPath -Force

# ==============================================================================
# STEP 4: ATTACH AND SEND VIA SMTP PORT 25
# ==============================================================================
Write-Host "Sending email via Exchange Server on Port 25..." -ForegroundColor Cyan
try {
    Send-MailMessage -SmtpServer $SmtpServer `
                     -Port $SmtpPort `
                     -From $FromAddress `
                     -To $ToAddress `
                     -Subject $Subject `
                     -Body $Body `
                     -Attachments $LocalDocxPath
    Write-Host "Email successfully sent to $ToAddress!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email. Verification details: $_"
}
