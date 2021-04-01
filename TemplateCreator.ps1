function create-IndexTempalte(){

 param(
            [Parameter(Mandatory=$true)]
            [string]$user,
            [Parameter(Mandatory=$true)]
            [string]$pass, 
            [Parameter(Mandatory=$true)]
            [string]$elastic,
            [Parameter(Mandatory=$true)]
            [string]$template,
            [Parameter(Mandatory=$true)]
            [string]$lifecycle_name,
            [Parameter(Mandatory=$true)]
            [ValidateSet(“metricbeat”,”filebeat”,”auditbeat”,”winlogbeat”)]
            [string]$template_type
        )

$tempalte_types = @{

metricbeat  = 'metricbeat-7.10.2.json';
filebeat    = 'filebeat-7.10.0.json';
auditbeat   = 'auditbeat-7.10.1.json';
winlogbeat  = 'winlogbeat-6.10.1.json';

}

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

    $template_t = $tempalte_types[$template_type]
    $uri = "https://raw.githubusercontent.com/RagingPuppies/beats/main/$template_t"

    $body = (Invoke-WebRequest -uri $uri ).content | Convertfrom-Json
    $template_name                                = $template
    $body.index_patterns                          = ($template + "*")
    $body.settings.index.lifecycle.name           = $lifecycle_name
    $body.settings.index.lifecycle.rollover_alias = $template

    try{

        $response = Invoke-RestMethod ("$elastic/_template/" + $template + "?include_type_name") -Method PUT -Headers $Headers -Body ( $body | ConvertTo-Json -Depth 100) -ContentType application/json
        $response
    }
    catch{

        $ErrorMessage = $_.Exception
        $ErrorMessage

    }

}
