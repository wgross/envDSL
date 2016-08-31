#region Computername

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
        [ArgumentCompleter({[System.Environment]::MachineName})]
        [string[]]$Names,
        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$ContinueWith,
        [Parameter(Mandatory=$false)]
        [scriptblock]$OrElse = $null
    )
    process {
        
        $computerName = [System.Environment]::MachineName
        
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
        '"ConsoleHost"'
        '"Windows PowerShell ISE Host"'
        '"PowerShell Tools for Visual Studio Host"'
        '"PowerShell Server"'
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
        [ArgumentCompleter({ Get-CurrentAndKnownHostNames })]
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

#region Add-EnvPathVariable

function Add-EnvPath {
    <#
    .SYNOPSIS
        Adds the specified pathes to an environment variable
    .DESCRIPTION
        If an array is specified the relative order is optained. Pathes can be appende d or prependend or both.
        If the path is already contained in the variable, it is removed from its current place and agein appended or prepended
        as specified.
    .PARAMETER Separator
        Specifies the seperator character used by the edited path variable. On windows this usually ';' on unix ':'.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Prepend,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Append,

        [Parameter(Mandatory=$false)]
        [ArgumentCompleter({'";"';'":"'})]
        [string]$Separator = ";"
    )
    process {
        
        # split the current content into a list of entries. Pathes are seperated with ';'
        [System.Collections.Generic.List[string]]$splitted = [System.Collections.Generic.List[string]]::new()
        if(Test-Path $Path) {
            [System.Collections.Generic.List[string]]$splitted = [System.Linq.Enumerable]::ToList((Get-Content -Path $Path) -split $Separator)
        }

        if($Append) {
            $Append | ForEach-Object {
                if($splitted.Contains($_)) {
                    $splitted.Remove($_) | Out-Null
                    Write-Verbose "Removed before adding $_"
                }
                if($splitted -notcontains $_) {
                    $splitted.Add($_) | Out-Null
                    Write-Verbose "Added at the end $_"
                }
            }
        }
        if($Prepend) {
            # Revert the array to start prepending with the last element
            # ==> The relative order is obtained because the first item is prepended as the last and is 
            #     therefore the first in the result path
            [array]::Reverse($Prepend)
            $Prepend | ForEach-Object {
                if($splitted.Contains($_)) {
                    $splitted.Remove($_) | Out-Null
                    Write-Verbose "Removed before adding $_"
                }
                if($splitted -notcontains $_) {
                    $splitted.Insert(0,$_) | Out-Null
                    Write-Verbose "Added in front $_"
                }
            } 
        }
        Set-Content -Path $Path -Value ([string]::Join($Separator,($splitted | Where-Object { ![string]::IsNullOrWhiteSpace($_) })))
    }
}

#endregion 

#region Test-AdmnUser

function Test-AdminUser {
    param(
        [Parameter(Mandatory=$false)]
        $Throw
    )
    process {
        $isInRole = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        if($PSBoundParameters.ContainsKey("Throw")) {
            throw ($Throw)
        }
        return $isInRole
    }
}
 
#enregion 