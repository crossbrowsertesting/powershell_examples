Add-Type -AssemblyName System.Web

# Specify your username and authKey
$username = "you@yourDomain.com"
$authKey = "yourActualAuthKey"

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
    $params = @{url="$($url)"}
    $reqResponse = Invoke-WebRequest -Uri $requestUrl -Method POST -Headers $Headers -Body $params | ConvertFrom-JSON
    
    # Prevent the next test from starting until 30 seconds after this one is done.
    $session = $reqResponse.screenshot_test_id
    $version = $reqResponse.versions.version_id
    $running = "True"
    while($running -ne "False")
    {
        Write-Host "Polling..."
        $status = Invoke-WebRequest -Uri "https://crossbrowsertesting.com/api/v3/screenshots/$($session)/$($version)" -Headers $Headers -Method GET | ConvertFrom-JSON
        $running = $status.versions.active
        Write-Host "Test Still Active: $($running)"
        Start-Sleep -s 30 
    }
    Write-Host "Test Completed, waiting for processing to finish"
    Start-Sleep -s 30
}