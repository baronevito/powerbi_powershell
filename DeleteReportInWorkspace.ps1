#Install-Module -Name AzureAD
#Install-Module -Name MicrosoftPowerBIMgmt

# Esegui l'autenticazione interattiva
#Connect-AzureAD

# Autenticazione
Connect-PowerBIServiceAccount

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


# Ottieni l'access token
$accessToken = (Get-PowerBIAccessToken).AccessToken

# Ottieni l'elenco dei report nel workspace specificato
$reports = Get-PowerBIReport -WorkspaceId $workspaceId
$datasets = Get-PowerBIDataset -WorkspaceId $workspaceId

# Elimina tutti i report nel workspace
foreach ($report in $reports) {

     $ReportURL=$report.WebUrl.Replace("https://app.powerbi.com/","").Replace("rdlreports","reports")
     Invoke-PowerBIRestMethod -Url $ReportURL -Method Delete

     $nam= $report.Name

     Write-Host "Il report eliminato: $nam"
      
}

# Elimina tutti i dataset nel workspace
foreach ($dataset in $datasets) {

$DatasetURL = 'groups/' + $workspaceId + '/datasets/' + $dataset.Id
Invoke-PowerBIRestMethod -Url $DatasetURL -Method Delete

$nam2 = $dataset.Name
 Write-Host "Il report eliminato: $nam2"
}