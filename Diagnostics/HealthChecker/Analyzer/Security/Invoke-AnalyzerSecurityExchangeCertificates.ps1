﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function Invoke-AnalyzerSecurityExchangeCertificates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ref]$AnalyzeResults,

        [Parameter(Mandatory = $true)]
        [object]$HealthServerObject,

        [Parameter(Mandatory = $true)]
        [object]$DisplayGroupingKey
    )

    Write-Verbose "Calling: $($MyInvocation.MyCommand)"
    $exchangeInformation = $HealthServerObject.ExchangeInformation
    $baseParams = @{
        AnalyzedInformation = $AnalyzeResults
        DisplayGroupingKey  = $DisplayGroupingKey
    }

    foreach ($certificate in $exchangeInformation.ExchangeCertificates) {

        if ($certificate.LifetimeInDays -ge 60) {
            $displayColor = "Green"
        } elseif ($certificate.LifetimeInDays -ge 30) {
            $displayColor = "Yellow"
        } else {
            $displayColor = "Red"
        }

        $params = $baseParams + @{
            Name                   = "Certificate"
            DisplayCustomTabNumber = 1
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Name                   = "FriendlyName"
            Details                = $certificate.FriendlyName
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Name                   = "Thumbprint"
            Details                = $certificate.Thumbprint
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Name                   = "Lifetime in days"
            Details                = $certificate.LifetimeInDays
            DisplayCustomTabNumber = 2
            DisplayWriteType       = $displayColor
        }
        Add-AnalyzedResultInformation @params

        $displayValue = $false
        $displayWriteType = "Grey"
        if ($certificate.LifetimeInDays -lt 0) {
            $displayValue = $true
            $displayWriteType = "Red"
        }

        $params = $baseParams + @{
            Name                   = "Certificate has expired"
            Details                = $displayValue
            DisplayWriteType       = $displayWriteType
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        $certStatusWriteType = [string]::Empty

        if ($null -ne $certificate.Status) {
            switch ($certificate.Status) {
                ("Unknown") { $certStatusWriteType = "Yellow" }
                ("Valid") { $certStatusWriteType = "Grey" }
                ("Revoked") { $certStatusWriteType = "Red" }
                ("DateInvalid") { $certStatusWriteType = "Red" }
                ("Untrusted") { $certStatusWriteType = "Yellow" }
                ("Invalid") { $certStatusWriteType = "Red" }
                ("RevocationCheckFailure") { $certStatusWriteType = "Yellow" }
                ("PendingRequest") { $certStatusWriteType = "Yellow" }
                default { $certStatusWriteType = "Yellow" }
            }

            $params = $baseParams + @{
                Name                   = "Certificate status"
                Details                = $certificate.Status
                DisplayCustomTabNumber = 2
                DisplayWriteType       = $certStatusWriteType
            }
            Add-AnalyzedResultInformation @params
        } else {
            $params = $baseParams + @{
                Name                   = "Certificate status"
                Details                = "Unknown"
                DisplayWriteType       = "Yellow"
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        }

        if ($certificate.PublicKeySize -lt 2048) {
            $params = $baseParams + @{
                Name                   = "Key size"
                Details                = $certificate.PublicKeySize
                DisplayWriteType       = "Red"
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params

            $params = $baseParams + @{
                Details                = "It's recommended to use a key size of at least 2048 bit"
                DisplayWriteType       = "Red"
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        } else {
            $params = $baseParams + @{
                Name                   = "Key size"
                Details                = $certificate.PublicKeySize
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        }

        if ($certificate.SignatureHashAlgorithmSecure -eq 1) {
            $shaDisplayWriteType = "Yellow"
        } else {
            $shaDisplayWriteType = "Grey"
        }

        $params = $baseParams + @{
            Name                   = "Signature Algorithm"
            Details                = $certificate.SignatureAlgorithm
            DisplayWriteType       = $shaDisplayWriteType
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Name                   = "Signature Hash Algorithm"
            Details                = $certificate.SignatureHashAlgorithm
            DisplayWriteType       = $shaDisplayWriteType
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        if ($shaDisplayWriteType -eq "Yellow") {
            $params = $baseParams + @{
                Details                = "It's recommended to use a hash algorithm from the SHA-2 family `r`n`t`tMore information: https://aka.ms/HC-SSLBP"
                DisplayWriteType       = $shaDisplayWriteType
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        }

        if ($null -ne $certificate.Services) {
            $params = $baseParams + @{
                Name                   = "Bound to services"
                Details                = $certificate.Services
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        }

        if ($exchangeInformation.BuildInformation.ServerRole -ne [HealthChecker.ExchangeServerRole]::Edge) {
            $params = $baseParams + @{
                Name                   = "Current Auth Certificate"
                Details                = $certificate.IsCurrentAuthConfigCertificate
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        }

        $params = $baseParams + @{
            Name                   = "SAN Certificate"
            Details                = $certificate.IsSanCertificate
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Name                   = "Namespaces"
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params

        foreach ($namespace in $certificate.Namespaces) {
            $params = $baseParams + @{
                Details                = $namespace
                DisplayCustomTabNumber = 3
            }
            Add-AnalyzedResultInformation @params
        }

        if ($certificate.IsCurrentAuthConfigCertificate -eq $true) {
            $currentAuthCertificate = $certificate
        }
    }

    if ($null -ne $currentAuthCertificate) {
        if ($currentAuthCertificate.LifetimeInDays -gt 0) {
            $params = $baseParams + @{
                Name                   = "Valid Auth Certificate Found On Server"
                Details                = $true
                DisplayWriteType       = "Green"
                DisplayCustomTabNumber = 1
            }
            Add-AnalyzedResultInformation @params
        } else {
            $params = $baseParams + @{
                Name                   = "Valid Auth Certificate Found On Server"
                Details                = $false
                DisplayWriteType       = "Red"
                DisplayCustomTabNumber = 1
            }
            Add-AnalyzedResultInformation @params

            $params = $baseParams + @{
                Details                = "Auth Certificate has expired `r`n`t`tMore Information: https://aka.ms/HC-OAuthExpired"
                DisplayWriteType       = "Red"
                DisplayCustomTabNumber = 2
            }
            Add-AnalyzedResultInformation @params
        }
    } elseif ($exchangeInformation.BuildInformation.ServerRole -eq [HealthChecker.ExchangeServerRole]::Edge) {
        $params = $baseParams + @{
            Name                   = "Valid Auth Certificate Found On Server"
            Details                = $false
            DisplayCustomTabNumber = 1
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Details                = "We can't check for Auth Certificates on Edge Transport Servers"
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params
    } else {
        $params = $baseParams + @{
            Name                   = "Valid Auth Certificate Found On Server"
            Details                = $false
            DisplayWriteType       = "Red"
            DisplayCustomTabNumber = 1
        }
        Add-AnalyzedResultInformation @params

        $params = $baseParams + @{
            Details                = "No valid Auth Certificate found. This may cause several problems. `r`n`t`tMore Information: https://aka.ms/HC-FindOAuthHybrid"
            DisplayWriteType       = "Red"
            DisplayCustomTabNumber = 2
        }
        Add-AnalyzedResultInformation @params
    }
}
