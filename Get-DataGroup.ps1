# Set variables...
$f5partition = "Production"
$f5poolname = "Frontend_App_pool"
$f5port = 8080
$user = "myf5userid"
$pass = "myf5password"
$f5server = "myf5server.mydomain.local"

# ======= NO CHANGES BELOW THIS LINE! =======
$servername = $env:COMPUTERNAME

# ====== AUTHORISATION SECTION ==========
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

# Uncomment this if you have untrusted certificates...

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


# === CONNECT TO F5 API =========
$reply = Invoke-RestMethod -Uri https://${f5server}/mgmt/tm/ltm/pool/~${f5partition}~${f5poolname}/members/~${f5partition}~${servername}:${f5port}/stats/?$select=serverside.curConns -Headers $Headers