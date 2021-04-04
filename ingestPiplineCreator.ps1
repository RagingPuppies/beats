function create-ingestPipeline(){

 param(
            [Parameter(Mandatory=$true)]
            [string]$user,
            [Parameter(Mandatory=$true)]
            [string]$pass, 
            [Parameter(Mandatory=$true)]
            [string]$elastic,
            [Parameter(Mandatory=$true)]
            [string]$template

        )



add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $pair = "$($user):$($pass)"

    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

    $basicAuthValue = "Basic $encodedCreds"

    $Headers = @{
        Authorization = $basicAuthValue
    }

    $uri = "https://raw.githubusercontent.com/RagingPuppies/beats/main/$template.json"

    $body = (Invoke-WebRequest -uri $uri ).content | Convertfrom-Json

    try{

        $response = Invoke-RestMethod ("$elastic/_ingest/pipeline/$template") -Method PUT -Headers $Headers -Body ( $body | ConvertTo-Json -Depth 100) -ContentType application/json
        $response
    }
    catch{

        $ErrorMessage = $_.Exception
        $ErrorMessage

    }

}
