#$ExchangeQueryURL = "https://endpoints.office.com/endpoints/Worldwide?ServiceAreas=Exchange&NoIPv6=true&ClientRequestId=b10c5ed1-bad1-445f-b386-b919946339a7"

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