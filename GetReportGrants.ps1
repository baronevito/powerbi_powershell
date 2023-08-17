#Install-Module -Name AzureAD
#Install-Module -Name MicrosoftPowerBIMgmt

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

$reports = Get-PowerBIReport -WorkspaceId $workspaceId
#input Folder
$folderName = Read-Host "Inserisci il nome della cartella dove depositare il file"
$folderName = "$folderName\"+$workspaceName+"_permission.csv"


foreach ($report in $reports) {
   $getuser ="https://api.powerbi.com/v1.0/myorg/admin/reports/"+$report.Id+"/users"
   
   $reportUser =Invoke-PowerBIRestMethod -Url $getuser -Method Get

   $ReportUserList = $reportUser | ConvertFrom-Json

   foreach ($usr in $ReportUserList.value) 
   {
   

   if($usr.principalType -eq "User")
   {
     $dispname= $usr.emailAddress 
   }else
   {
     $dispname= $usr.displayName 
   }


        [PsCustomObject]@{
                       workspaceId= $workspaceId
                       workspaceName= $workspaceName
                       reportId=$report.Id
                       reportName =$report.Name
                       reportUserAccessRight= $usr.reportUserAccessRight
                       displayName= $dispname
                       principalType= $usr.principalType
                    } | Export-CSV $folderName -Append -NoTypeInformation -Force
   }
}