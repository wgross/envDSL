#region $env:Computername or /bin/hostname

function Get-ComputerName {
    if(Test-Path Env:\COMPUTERNAME) {
        return $env:COMPUTERNAME
    } elseif(Test-Path "/bin/hostname") {
        return $(/bin/hostname -s)
    } else {
        return "UNKNOWN"
    }
}

function computer {
    <#
    .SYNOPSIS
        Executes a script block if $Env:COMPUTERNAME is contained in the given list of names.
    .DESCRIPTION
        If the environment variable is empty existence of /bin/histname is checkend and teh retusn value of 
        /bin/hostname -s is taken as the name of the current machine
    .EXAMPLE
        $script:wasCalled = $false
        computer $env:COMPUTERNAME { $script:wasCalled = $true }
        
        Sets $script:wasCalled always to $true
    #>
    [CmdletBinding(DefaultParameterSetName="byComputername")]
    param(
        [Parameter(Position=0,ParameterSetName="byComputername")]
        [ArgumentCompleter({Get-ComputerName})]
        [string[]]$Names,
        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$ContinueWith,
        [Parameter(Mandatory=$false)]
        [scriptblock]$OrElse = $null
    )
    process {
        
        $computerName = Get-ComputerName
        
        # determine if the script block has to be executed.

        $run = $false
        switch($PSCmdlet.ParameterSetName) {
            "byComputername" {
                if($Names.Contains($computerName)) {
                    $run = $true
                }
            }
        } 

        # execute the script block of the else-branch

        if($run) {
            return $ContinueWith.InvokeReturnAsIs()
        } else {
            Write-Verbose "Skipped execution of computer specific code ($Name)`: $($ContinueWith.ToString())"
            if($OrElse) {
                return $OrElse.InvokeReturnAsIs()
            }
        }
    }
}

#endregion 

#region powershell host name 

function Get-CurrentAndKnownHostNames {
    return @(
        $Host.Name
        "ConsoleHost" 
        "Windows PowerShell ISE Host"
        "PowerShell Tools for Visual Studio Host"
        "PowerShell Server"
    ) | Sort-Object -Unique
}

function powershellHost {
    <#
    .SYNOPSIS
        Executes a script block if Get-Host is of the given type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ParameterSetName="byKnownHostname")]
        [ArgumentCompleter({Get-CurrentAndKnownHostNames})]
        [string[]]$Names,
        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$ContinueWith
    )
    process {
        # Find out if the scriotblock has to be run

        $run = $false

        switch($PSCmdlet.ParameterSetName) {
            "byKnownHostname" {
                if($Names.Contains($Host.Name)) {
                    $run = $true
                }
            }
        }

        # run the scriptblock 

        if($run) {
            return $ContinueWith.InvokeReturnAsIs()
        } else {
            Write-Verbose "Skipped execution of powershellHost specific code host=$((Get-Host).Name)`: $($ContinueWith.ToString())"
        }
    }
}

#endregion 