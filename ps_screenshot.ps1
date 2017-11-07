Add-Type -AssemblyName System.Web

# Specify your username and authKey
$username = "you@yourDomain.com"
$authKey = "yourActualAuthKey"

$basic_auth = GetContent -Raw ./basic_auth.json | ConvertFrom-Json

# This is used for doing the HTTP basic authentication we use.  This converts the strings into a HTTP header.
$Headers = @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$authKey))) }

$apiEndpoint = "crossbrowsertesting.com/api/v3/screenshots"

#Generates the string of browsers used for the Test
# Sets to ?, then appends browsers in OS|Browser format
$browserString = "?"
Import-CSV browsers.csv | ForEach-Object {
    $browserString += "browsers=$($_.os)|$($_.browser)$($_.version)&"
}

# Iterate over the list of URLs and run a screenshot test for each one
Get-Content urlList.txt | ForEach-Object {
    $url = $_
    $requestUrl = "https://$($apiEndpoint)/$($browserString)send_email=false"
    Write-Host "Sending screenshot request for $($url)"
    $parameters = @{url="$($url)"}
    if ($basic_auth.enable -eq $true) {
        $parameters += @{basic_username="$($basic_auth.auth_user)"}
        $parameters += @{basic_password="$($basic_auth.auth_pass)"}
    }
    $params = $parameters
    $reqResponse = Invoke-WebRequest -Uri $requestUrl -Method POST -Headers $Headers -Body $params | ConvertFrom-JSON
    
    # Prevent the next test from starting until 5 seconds after this one is done.
    $session = $reqResponse.screenshot_test_id
    Write-Host $session
    $version = $reqResponse.versions.version_id
    Write-Host $version
    $running = "True"
    while($running -ne $false)
    {
	#Debug
        # Write-Host "Polling..."
        $status = Invoke-WebRequest -Uri "https://crossbrowsertesting.com/api/v3/screenshots/$($session)/$($version)" -Headers $Headers -Method GET | ConvertFrom-JSON
        $running = $status.versions.active
        #Debug
        # Write-Host "Test Still Active: $($running)"
        Start-Sleep -s 15 
    }
    Write-Host "Test Completed, waiting for processing to finish"
    Start-Sleep -s 5
}
