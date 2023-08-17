#Install-Module -Name AzureAD
#Install-Module -Name MicrosoftPowerBIMgmt

Connect-PowerBIServiceAccount
# Ottieni l'access token
$accessToken = (Get-PowerBIAccessToken).AccessToken

# Ottieni l'elenco dei report nel workspace specificato
$addrep ="https://app.powerbi.com/groups/me/rdlreports/"

Write-Host "Accesso a Power BI"
while (-not $workspaceId) {
    $workspaceName = Read-Host "Inserisci il nome del workspace di Power BI"
    $workspace = Get-PowerBIWorkspace -Name $workspaceName

    if ($workspace) {
        $workspaceId = $workspace.Id
        Write-Host "Workspace ID: $workspaceId"
    } else {
        Write-Host "Workspace non trovato. Riprova."
    }
}

$reports = Get-PowerBIReport -WorkspaceId $workspaceId
#input Folder
$folderName = Read-Host "Inserisci il nome della cartella dove depositare il file"

$folderName = "$folderName\$workspaceName.csv"


foreach ($report in $reports) {
   [PsCustomObject]@{
        WorkspaceId     = $workspaceId
        WorkspaceName     = $workspaceName
        ReportName   = $report.Name
        ReportId     = $report.Id
        ReportAddress = $addrep+$report.Id
    } | Export-CSV $folderName -Append -NoTypeInformation -Force  
}