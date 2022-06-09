﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function global:Remove-ExPerfWiz {
    <#

    .SYNOPSIS
    Removes data collector sets from perfmon

    .DESCRIPTION
    Used to remove data collector sets from perfmon.

    .PARAMETER Name
    Name of the Perfmon Collector set

    Default Exchange_Perfwiz

    .PARAMETER Server
    Name of the server to remove the collector set from

    Default LocalHost

    .OUTPUTS
    Logs all activity into $env:LOCALAPPDATA\ExPerfWiz.log file

    .EXAMPLE
    Remove a collector set on the local machine

    Remove-ExPerfwiz -Name "My Collector Set"

    .EXAMPLE
    Remove a collect set on another server

    Remove-ExPerfwiz -Server RemoteServer-01


    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Name = "Exchange_Perfwiz",

        [string]
        $Server = $env:ComputerName
    )

    process {

        Write-SimpleLogFile -string ("Removing Experfwiz for: " + $server) -Name "ExPerfWiz.log"

        # Remove the experfwiz counter set
        if ($PSCmdlet.ShouldProcess("$Server\$Name", "Removing Performance Monitor Data Collector")) {
            [string]$logman = logman delete -name $Name -s $server
        }

        # Check if we have an error and throw and error if needed.
        if ([string]::isnullorempty(($logman | Select-String "Error:"))) {
            Write-SimpleLogFile "ExPerfwiz removed" -Name "ExPerfWiz.log"
        } else {
            Write-SimpleLogFile "[ERROR] - Unable to remove Collector" -Name "ExPerfWiz.log"
            Write-SimpleLogFile $logman -Name "ExPerfWiz.log"
            throw $logman
        }
    }
}
