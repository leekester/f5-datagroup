# Set variables...
$User = "<f5-username>"
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
$Response.records.name