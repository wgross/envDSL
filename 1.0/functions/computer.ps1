

function computer {
    <#
    .SYNOPSIS
        Executes a script block if $Env:COMPUTERNAME is contained in the given list of names.
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
        
        # determine if the script block has to be executed.

        $run = $false
        switch($PSCmdlet.ParameterSetName) {
            "byComputername" {
                if($Names.Contains($Env:COMPUTERNAME)) {
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
