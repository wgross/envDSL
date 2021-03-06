using namespace System
using namespace System.Linq
using namespace System.Collections.Generic
using namespace System.Security.Principal

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
        '"ServerRemoteHost"'
        '"Visual Studio Code Host"'
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

#region Edit-PathVariableContent

function Edit-PathVariableContent {
    <#
    .SYNOPSIS
        Adds the specified pathes to an environment variable
    .DESCRIPTION
        If an array is specified the relative order is obtained. Pathes can be appended or prependend or both.
        If the path is already contained in the variable, it is removed from its current place and agein appended or prepended
        as specified.
    .PARAMETER Path
        The path to the variables content like: Env:\VariableName
    .PARAMETER Separator
        Specifies the seperator character used by the edited path variable. On windows this usually ';' on unix ':'.
        A default value is guessed from the current value of the $PWD variable.
    .EXAMPLE  
        Edit-PathVariableContent -Path Env:\Path -Append "C:\tmp\"

        Appends the path c:\tmp to the execution path environment variable.
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
        [string]$Separator = $(if($PWD.Path.Contains(":")) { return ";" } else { return ":" })
    )
    process {
        
        # split the current content into a list of entries. Pathes are seperated with ';'
        [List[string]]$splitted = [List[string]]::new()
        if(Test-Path -Path $Path) {
            [List[string]]$splitted = [Enumerable]::ToList((Get-Content -Path $Path) -split $Separator)
        }

        if($Append) {
            $Append | ForEach-Object -Process {
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
            $Prepend | ForEach-Object -Process {
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
        Set-Content -Path $Path -Value ([string]::Join($Separator,($splitted | Where-Object -FilterScript { ![string]::IsNullOrWhiteSpace($_) })))
    }
}

function Test-PathVariableContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [ArgumentCompleter({'";"';'":"'})]
        [string]$Separator = $(if($PWD.Path.Contains(":")) { return ";" } else { return ":" })
    )
    process {
        [List[string]]$splitted = [List[string]]::new()
        if(Test-Path -Path $Path) {
            [List[string]]$splitted = [Enumerable]::ToList((Get-Content -Path $Path) -split $Separator)
        }
        
        $splitted | Where-Object -FilterScript { ![string]::IsNullOrEmpty($_) } | ForEach-Object -Process {
            # test every path item and return item with result
            [pscustomobject]@{
                Path = $_
                Exists = (Test-Path -Path $_)
            }
        }
    }
}

#endregion 

#region Edit environment variables

class EnvironmentVariableInfo {
    [string]$Name
    [string]$Machine
    [string]$User
    [string]$Process
}

function Get-EnvVariable {
    <#
    .SYNOPSIS
        Reads the values of an environment variable from process, user and machine
    #>
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({$wordToComplete = $args[2]; ([Environment]::GetEnvironmentVariables()).Keys | Where-Object { $_.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase) }})]
        [string[]]$Name = (([Environment]::GetEnvironmentVariables()).Keys)
    )
    process {
        $Name | ForEach-Object {
            [EnvironmentVariableInfo]@{
                Name = $_
                Process = [Environment]::GetEnvironmentVariable($_,[EnvironmentVariableTarget]::Process)
                User = [Environment]::GetEnvironmentVariable($_,[EnvironmentVariableTarget]::User)
                Machine = [Environment]::GetEnvironmentVariable($_,[EnvironmentVariableTarget]::Machine) 
            }
        }       
    }
}

function Set-EnvVariable {
    <#
    .SYNOPSIS
        Writes the values of an environment variable to process, user or machine
    #>
    param(
        [Parameter(Position=0,Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({$wordToComplete = $args[2]; ([Environment]::GetEnvironmentVariables()).Keys | Where-Object { $_.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase) }})]
        [string]$Name,

        [Parameter(Position=0,Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [EnvironmentVariableTarget]$Target
    )
    process {
        if($Target) {
            [Environment]::SetEnvironmentVariable($Name,$Value,$Target)
        } else {
            [Environment]::SetEnvironmentVariable($Name,$Value)
        }
    }
}

#endregion 

#region Test-AdminUser

function Test-AdminUser {
    param(
        [Parameter(Mandatory=$false)]
        $Throw
    )
    process {
        if([WindowsPrincipal]::new([WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole]::Administrator)) {
            return $true
        } elseif($PSBoundParameters.ContainsKey("Throw")) {
            throw ($Throw)
        } else {
            return $false
        }
    }
}
 
#enregion 
