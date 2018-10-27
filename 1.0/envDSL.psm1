Write-Host "Loading module envDSL..."

Get-ChildItem $PSScriptRoot -Include *.ps1 -Recurse | ForEach-Object { . $_.FullName }

function Invoke-EnvironmentSpecificScript {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        $ScriptName  = (Split-Path -Leaf $MyInvocation.ScriptName),
        [Parameter()]
        [ValidateScript({Test-Path})]
        $ContextRoot = $Env:PSCONTEXTROOT,  #"$PWD/.context",
        [ValidateNotNull()]
        $ContextPath = @(".context",$env:USERNAME,$env:COMPUTERNAME),
        $ParametersToSplat = $MyInvocation.UnboundArguments
    )
    process {
        Write-Verbose "Found .context root in $ContextRoot"
        
        $currentExectionLocation = (Split-Path -Parent $ContextRoot)
        # Starting with .context itself descend and try to call context specific incarnations of this script
        $ContextPath | foreach {
            $currentExectionLocation = Join-Path $currentExectionLocation $_ 
            $currentScriptPath = Join-Path $currentExectionLocation $ScriptName
            if((Test-Path $currentScriptPath)) {
                # 'splat' unbound parameters at context script
                & $currentScriptPath @ParametersToSplat
            } 
        }
        return $true # executed (or tried) context specific scripts
    }
}

function New-EnvironmentSpecificContext {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ValidateScript({Test-Path})]
        $ContextRoot = $Env:PSCONTEXTROOT,  #"$PWD/.context",
        [Parameter()]
        [ValidateNotNull()]
        $ContextPath = @(".context",$env:USERNAME,$env:COMPUTERNAME)
    )
    process {
        Write-Verbose "Found .context root in $ContextRoot"

        $currentExectionLocation = (Split-Path -Parent $ContextRoot)
        $ContextPath | foreach {
            $currentExectionLocation = Join-Path $currentExectionLocation $_ 
            $currentScriptPath = Join-Path $currentExectionLocation $ScriptName
            if(!(Test-Path $currentScriptPath)) {
                mkdir $currentScriptPath
            } 
        }
    }
}

Export-ModuleMember -Function "*"
