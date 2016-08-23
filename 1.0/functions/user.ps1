function user {
    <#
    .SYNOPSIS
        Executes a script block if $Env:USERNAME is contained in the given list of names.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ParameterSetName="byUsername")]
        [string[]]$Names,

        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$ContinueWith
    )
    process {
        $run=$false
    
        switch($PSCmdlet.ParameterSetName) {
            "byUsername" {
                if($Names.Contains($env:USERNAME)) {
                    $run = $true
                }
            }
        }

        if($run) {
            return $ContinueWith.InvokeReturnAsIs()
        } else {
            Write-Verbose "Skipped execution of user specific code Name=($Name)`: $($ContinueWith.ToString())"
        }
    }
}