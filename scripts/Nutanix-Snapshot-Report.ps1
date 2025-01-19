# Define Nutanix cluster credentials and users variables 
$URI = "https://NTNX-IP:9440/PrismGateway/services/rest/v2.0/snapshots" 
$NTNXUser = "NTNX-USER" 
$NTNXPassword = "NTNX-PASSWORD" 
$SmtpServer ="SMTP-SERVER" 
$emailfrom = "report-ntnx@XXXX" 
$emailto = "@XXXXX" 
$subject = "Nutanix Snapshot Report" 
# Get all snapshots from Nutanix cluster 
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $NTNXUser, $NTNXPassword))) 
$NTNXSnapshots = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -URI $URI 
$AllNTNXSnapshots = $NTNXSnapshots.entities 
# Create a DataTable to store snapshot details 
$Results = New-Object system.Data.DataTable "AllNTNXSnapshots" 
$Columns = @( 
    @{Name="UUID"; Type=[string]}, 
    @{Name="Snapshot-Name"; Type=[string]}, 
    @{Name="VM-Name"; Type=[string]}, 
    @{Name="Creation-Time"; Type=[string]} 
) 
# Add columns to the DataTable 
foreach ($Column in $Columns) { 
    $DataColumn = New-Object System.Data.DataColumn $Column.Name, $Column.Type 
    $Results.Columns.Add($DataColumn) 
} 
# Process each snapshot and add details to the DataTable 
foreach ($Snapshot in $AllNTNXSnapshots) { 
    $UUID = $Snapshot.uuid 
    $SnapshotName = $Snapshot.snapshot_name 
    $VMName = $Snapshot.vm_create_spec.name 
    $CreationTimeStamp = ($Snapshot.created_time) / 1000 
    $CreationTime = (Get-Date '1/1/1970').AddMilliseconds($CreationTimeStamp) 
    $SnapshotCreationTime = $CreationTime.ToLocalTime() 
    $Row = $Results.NewRow() 
    $Row."UUID" = $UUID 
    $Row."Snapshot-Name" = $SnapshotName 
    $Row."VM-Name" = $VMName 
    $Row."Creation-Time" = $SnapshotCreationTime 
    $Results.Rows.Add($Row) 
} 
# Output results to console in table format 
$Results | Format-Table -AutoSize 
# Select only the desired columns for the HTML report 
$SelectedColumns = $Results | Select-Object UUID, "Snapshot-Name", "VM-Name", "Creation-Time" 
# Convert the selected columns to HTML format 
$HtmlReport = $SelectedColumns | ConvertTo-Html -Fragment -PreContent "<h1>Nutanix Snapshot Report</h1>" 
# Convert HTML report to a single string 
$HtmlReportString = $HtmlReport -join "`r`n" 
# Define email parameters 
$EmailParams = @{ 
    From       = $emailfrom 
    To         = $emailto 
    Subject    = $subject 
    Body       = $HtmlReportString 
    BodyAsHtml = $true 
    SmtpServer = $SmtpServer 
} 
# Send the email with the HTML report 
Send-MailMessage @EmailParams
