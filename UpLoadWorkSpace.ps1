#Install-Module -Name AzureAD
#Install-Module -Name MicrosoftPowerBIMgmt

Connect-PowerBIServiceAccount
$accessToken = (Get-PowerBIAccessToken).AccessToken
$workspaceId = $null
$folderPath = $null

#input workspace destination
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
#input Folder
while (-not $folderPath) {
    $folderName = Read-Host "Inserisci il nome della cartella da caricare"
    if (Test-Path $folderName) {
        $folderPath = $folderName
    } else {
        Write-Host "Cartella non trovata. Riprova."
    }
}

Write-Host "Cartella trovata: $folderPath inizio il caricamento sul workspace: $workspaceName"

$files = Get-ChildItem -Path $folderName -File -Include "*.pbix", "*.rdl" -Recurse

foreach ($file in $files) {
    try {
        if ($file.Extension -eq ".pbix") 
        {
            New-PowerBIReport -Path $file.FullName -WorkspaceId $workspaceId -ConflictAction CreateOrOverwrite
        } 
        elseif 
        ($file.Extension -eq ".rdl") 
        {
            
            $fileName = [IO.Path]::GetFileName($file.FullName)
            $boundary = [guid]::NewGuid().ToString()
            $fileBody = Get-Content -Path $file.FullName -Encoding UTF8

            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $encoding = [System.Text.Encoding]::GetEncoding("utf-8")
            $fileBody2 = $encoding.GetString($fileBytes)

            $uri = "groups/$workspaceId/imports?datasetDisplayName=$fileName&nameConflict=Abort"

            $body = @"
---------FormBoundary$boundary
Content-Disposition: form-data; name="$filename"; filename="$filename"
Content-Type: application/rdl

$fileBody2
---------FormBoundary$boundary--

"@


Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body -ContentType "multipart/form-data"

        }
        Write-Host "File '$($file.Name)' caricato con successo."
    } catch {
        Write-Host "Errore durante il caricamento del file '$($file.Name)': $($_.Exception.Message)"
    }
}
# Messaggio di completamento
Write-Host "Processo terminato."