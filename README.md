# CBT Powershell Examples

A collection of examples for scripting tests using PowerShell.

## browsers.csv

Just a simple CSV containing the browser name, version, and OS you wish to test against in your test.  Must follow the API names for CrossBrowserTesting.

## urlList.txt

A list of line-separated URLs to test.

## basic_auth.json
A JSON-formatted configuration for HTTP basic authentication.  Enable by changing "enabled" from false to true.

## ps_screenshot

This script will take the contents of urlList.txt and browsers.csv and use them to generate screenshot test requests using our API.


