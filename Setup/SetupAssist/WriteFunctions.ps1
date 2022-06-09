﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

. $PSScriptRoot\..\..\Shared\Out-Columns.ps1
function Write-Verbose {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'In order to log Write-Verbose')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 1, ValueFromPipeline)]
        [string]$Message
    )

    process {
        Write-DebugLog $Message
        Microsoft.PowerShell.Utility\Write-Verbose $Message
    }
}

function Write-Warning {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'In order to log Write-Waring')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 1, ValueFromPipeline)]
        [string]$Message
    )

    process {
        Write-DebugLog $Message
        Microsoft.PowerShell.Utility\Write-Warning $Message
    }
}

function Write-DebugLog($Message) {
    $Script:DebugLogger = $Script:DebugLogger | Write-LoggerInstance $Message
}

function Write-HostLog($Message) {
    $Script:HostLogger = $Script:HostLogger | Write-LoggerInstance $Message
    Write-DebugLog $Message
}

function Write-OutColumns {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object[]]
        $InputObject,

        [Parameter(Mandatory = $false, Position = 0)]
        [string[]]
        $Properties,

        [Parameter(Mandatory = $false, Position = 1)]
        [scriptblock[]]
        $ColorizerFunctions = @(),

        [Parameter(Mandatory = $false)]
        [int]
        $IndentSpaces = 0,

        [Parameter(Mandatory = $false)]
        [int]
        $LinesBetweenObjects = 0
    )
    begin {
        $objects = New-Object System.Collections.ArrayList
    }
    process {
        foreach ($thing in $InputObject) {
            [void]$objects.Add($thing)
        }
    }
    end {
        $stringOutput = [string]::Empty
        SetWriteHostAction $null
        $objects | Out-Columns -Properties $Properties `
            -ColorizerFunctions $ColorizerFunctions `
            -IndentSpaces $IndentSpaces `
            -LinesBetweenObjects $LinesBetweenObjects `
            -StringOutput ([ref]$stringOutput)
        Write-HostLog $stringOutput
        SetWriteHostAction ${Function:Write-HostLog}
    }
}
