function workingDirectory {
    <#
    .SYNOPSIS
        Executes a script block if $PWD's base name od drive name is contained in the specified list of basenames or drives
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="byBasename")]
        [string[]]
        $Basenames,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName="byDrive")]
        [string[]]
        $Drives,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName="byContains")]
        [string[]]
        $Contains,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName="byContainsNot")]
        [string[]]
        $ContainsNot,

        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]
        $ContinueWith
    )
    process {
        $run = $false

        switch($PSCmdlet.ParameterSetName) {
            "byBasename" {
                if($Drives.Contains((Get-Item .).BaseName)) {
                    $run = $true
                } 
            }
            "byDrive" {
                if($Drives.Contains((Get-Item .).PSDrive.Name)) {
                    $run = $true
                } 
            }
            "byContains" {
                $Contains | foreach {
                    if(Test-Path $_) {
                        $run=$true
                    }
                }
            }
            "byContainsNot" {
                $ContainsNot | foreach {
                    if(!(Test-Path $_)) {
                        $run=$true
                    }
                }
            }
        } 

        if($run) {
            return $ContinueWith.InvokeReturnAsIs()
        } else {
            Write-Verbose "Skipped execution of workingDirectory specific code basename=($Basenames),drives=($Drives)`: $($ContinueWith.ToString())"
        }
    }
}