
$clientId = "" 

function GetAuthToken
{
    if(-not (Get-Module AzureRm.Profile)) {
      Import-Module AzureRm.Profile
    }

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"

    $authority = "https://login.microsoftonline.com/5a89ca1e-6149-40f1-95b4-3123ceacb89c/oauth2/nativeclient";

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

    return $authResult
}

function get_groups_path($group_id) {
    if ($group_id -eq "me") {
        return "myorg"
    } else {
        return "myorg/groups/$group_ID"
    }
}

# 1: Auth
# ==================================================================
$token = GetAuthToken

Add-Type -AssemblyName System.Net.Http


# Get authorization token
$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

# Prompt for user input
# ==================================================================
# Get the list of groups that the user is a member of
$uri = "https://api.powerbi.com/v1.0/myorg/groups/"
$all_groups = (Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET).value

# Ask for the source workspace name
$source_group_ID = ""
while (!$source_group_ID) {
    $source_group_name = Read-Host -Prompt "Enter the name of the workspace you'd like to Download"

    $temp_path_root = "$PSScriptRoot\pbirdlcopyworkspace.$source_group_name"

    if($source_group_name -eq "My Workspace") {
        $source_group_ID = "me"
        break
    }

    Foreach ($group in $all_groups) {
        if ($group.name -eq $source_group_name) {
            if ($group.isReadOnly -eq "True") {
                "Invalid choice: you must have edit access to the group"
                break
            } else {
                $source_group_ID = $group.id
                break
            }
        }
    }

    if(!$source_group_id) {
        "Please try again, making sure to type the exact name of the group"  
    } 
}


# PART 3: try exporting RDL PBIX
# ==================================================================
$report_ID_mapping = @{}      # mapping of old report ID to new report ID
$dataset_ID_mapping = @{}     # mapping of old model ID to new model ID
$failure_log = @()  
$import_jobs = @()
$source_group_path = get_groups_path($source_group_ID)

$uri = "https://api.powerbi.com/v1.0/$source_group_path/reports/"
$reports_json = Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET
$reports = $reports_json.value

# For My Workspace, filter out reports that I don't own - e.g. those shared with me
if ($source_group_ID -eq "me") {
    $reports_temp = @()
    Foreach($report in $reports) {
        if ($report.isOwnedByMe -eq "True") {
            $reports_temp += $report
        }
    }
    $reports = $reports_temp
}


New-Item -Path $temp_path_root -ItemType Directory 
"=== Exporting PBIX files to copy datasets..."
Foreach($report in $reports) {
   
    $report_id =   $report.id
    $report_name = $report.name
    $report_type = $report.reportType
    $dataset_id =  $report.datasetId

    
    if ($report_name -eq "Report Usage Metrics Report")
    {
    continue
    }
     
     try {
     if ($dataset_ID_mapping[$dataset_id]) {
        continue
        }
        }catch {}
    
    
    
    "== Exporting $report_name with id: $report_id to $temp_path"
    $uri = "https://api.powerbi.com/v1.0/$source_group_path/reports/$report_id/Export"

    if ($report_type -eq "PaginatedReport")
    {
    $temp_path = "$temp_path_root\$report_name.rdl"
    try {
        Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET -OutFile "$temp_path"
    } catch [Exception] {
        Write-Host "= This report and dataset cannot be copied, skipping. This is expected for most workspaces."
        Write-Host $_.Exception
        Write-Host $report.id
         Write-Host $report.name
         Write-Host $report.reportType
        continue
    }
    }

    if ($report_type -eq "PowerBIReport")
    {
    $temp_path = "$temp_path_root\$report_name.pbix"
    try {        
        Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET -OutFile "$temp_path"
    } catch [Exception]  {
        Write-Host "= This report and dataset cannot be copied, skipping. This is expected for most workspaces."
         Write-Host $_.Exception
         Write-Host $report.id
         Write-Host $report.name
         Write-Host $report.reportType
        continue
    }
    }
    }