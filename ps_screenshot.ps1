Add-Type -AssemblyName System.Web


$username = "you@yourDomain.com"
$authKey = "yourActualAuthKey"
$Headers = @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$authKey))) }

$apiEndpoint = "crossbrowsertesting.com/api/v3/screenshots"

$browserString = "?"
Import-CSV browsers.csv | ForEach-Object {
    $browserString += "browsers=$($_.os)|$($_.browser)$($_.version)&"
}

Get-Content urlList.txt | ForEach-Object {
    $url = $_
    $requestUrl = "https://$($apiEndpoint)/$($browserString)send_email=false"
    Write-Host "Sending screenshot request for $($url)"
    $params = @{url="$($url)"}
    $reqResponse = Invoke-WebRequest -Uri $requestUrl -Method POST -Headers $Headers -Body $params | ConvertFrom-JSON
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