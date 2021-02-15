# Set variables...
$User = "<f5-admin>"
$Pass = "<f5-password>"
$F5ManagementAddress = "<f5-management-ip-or-dns>"
$DataGroup = "Exchange_Online_Nodes"

# Generate authentication token
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
    }

# Use this section if your F5 management management interface doesn't use a trusted TLS cert.
# If you use valid certificates - well done! You can comment out or delete this section...

### START ignore invalid TLS certificate block ###

if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
[ServerCertificateValidationCallback]::Ignore()

### END ignore invalid TLS certificate block ###

# Invoke request
$URI = "https://$F5ManagementAddress/mgmt/tm/ltm/data-group/internal/$DataGroup"
$Response = Invoke-RestMethod -Uri $URI -Headers $Headers

Write-Host ("These are the records in the `"" + $datagroup + "`" data group...") -ForegroundColor Yellow
$DataGroupIPs = $Response.records.name
$DataGroupIPs

# Get Exchange Online SMTP IP ranges

# Generate random number to insert into ClientRequestID
$Random = Get-Random -Minimum 100000000000 -Maximum 999999999999

# Define the URL to query. We'll get all Exchange-related data and exclude IPv6 addresses
$ExchangeQueryURL = "https://endpoints.office.com/endpoints/Worldwide?ServiceAreas=Exchange&NoIPv6=true&ClientRequestId=b10c5ed1-bad1-445f-b386-$Random"

# Create an array which includes the TCP ports we'll filter on
$TCPPorts = @('25','587')

# Get the data
$ExchangeData = Invoke-RestMethod -Uri $ExchangeQueryURL -Method Get

# Filter to just extract IP addresses
$MailRelayIPs = ($ExchangeData | Where-Object {$TCPPorts -contains $_.tcpPorts} | Select ips).ips | Sort-Object

Write-Host
Write-Host ("These are IP addresses associated with Exchange Online SMTP...") -ForegroundColor Yellow
$MailRelayIPs

If (Compare-Object $MailRelayIPs $DataGroupIPs) {
    Write-Host
    Write-Host "Data group needs to be updated!!!" -ForegroundColor Red
    $UpdateGroup = $true
    } Else {
    Write-Host
    Write-Host "Data group is in sync with Microsoft's service IPs" -ForegroundColor Green
    }

# Update the data group if F5 and Microsoft-stated addresses differ...

If (Compare-Object $MailRelayIPs $DataGroupIPs) {
   Write-Host "Press a key to update the data group, or CTRL+C to exit" -ForegroundColor Yellow
   Pause

$Template = '{"records":[]}' | ConvertFrom-Json

ForEach ($IP in $MailRelayIPs) {
    $JsonDataAdd = @"
    {
        "name": "$IP",
        "data": ""
    }
"@
    $Template.records += (ConvertFrom-Json $JsonDataAdd)
    }
    # Execute the update
    Invoke-RestMethod -Uri $URI -Headers $Headers -Body ($Template | ConvertTo-Json) -Method Put -ContentType 'application/json'
}