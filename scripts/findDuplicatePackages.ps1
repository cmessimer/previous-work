#This script was used to list all NuGet packages stored as artifacts in Azure DevOps to spot duplicates within an Azure Pipeline.
# Initially I was having an issue listing the packages, but once I removed the specific project parameter, it resolved my issue.

# Variables
$targetVersion = "2.0.2"  
$organization = ""
$feedName = ""
$viewName = "Release"  # Specify the correct view (e.g., Release, Local)
$packageName = ""
$pat = "inserttoken" 

# Encode PAT for authentication
$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
}

# Get all feeds in the organization
$feedsUrl = "https://feeds.dev.azure.com/$organization/_apis/packaging/feeds?api-version=6.0-preview.1"
$feeds = Invoke-RestMethod -Uri $feedsUrl -Headers $headers -Method Get

# Find the correct feed ID
$feed = $feeds.value | Where-Object { $_.name -eq $feedName }
if (-not $feed) {
    Write-Output "Error: Feed '$feedName' not found."
    exit 1
}
$feedId = $feed.id
Write-Output "Using Feed ID: $feedId"

# Get all available views in the feed
$viewsUrl = "https://feeds.dev.azure.com/$organization/_apis/packaging/feeds/$feedId/views?api-version=6.0-preview.1"
$views = Invoke-RestMethod -Uri $viewsUrl -Headers $headers -Method Get

# Find the correct view ID
$view = $views.value | Where-Object { $_.name -eq $viewName }
if (-not $view) {
    Write-Output "Error: View '$viewName' not found in feed '$feedName'."
    exit 1
}
$viewId = $view.id
Write-Output "Using View ID: $viewId"

# Fetch all packages in the Release view
$packagesUrl = "https://feeds.dev.azure.com/$organization/_apis/packaging/feeds/$feedId/views/$viewId/packages?api-version=6.0-preview.1"
$packages = Invoke-RestMethod -Uri $packagesUrl -Headers $headers -Method Get

if ($packages.value) {
    Write-Output "Packages found in view '$viewName' of feed '$feedName':"
    $packages.value | ForEach-Object { Write-Output $_.name }
} else {
    Write-Output "No packages found in view '$viewName' of feed '$feedName'."
}

# Search for the package in the view
$packageExists = $packages.value | Where-Object { $_.name -eq $packageName }
if ($packageExists) {
    Write-Output "Package '$packageName' EXISTS in view '$viewName'."
} else {
    Write-Output "Package '$packageName' NOT FOUND in view '$viewName'."
}
