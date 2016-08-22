Import-Module Pester
Import-Module $PSScriptRoot/envDSL.psm1 -Force

Describe "computer DSL item" {

    It "Executes code if the current computer name equal to the given name" {
        $script:wasCalled = $false
        computer "zumsel",$env:COMPUTERNAME {
            $script:wasCalled = $true
        }
        $script:wasCalled | Should Be $true
    }

    It "Executes code if the current computer name is member of the specified list" {
        $script:wasCalled = $false
        computer $env:COMPUTERNAME {
            $script:wasCalled = $true
        }
        $script:wasCalled | Should Be $true
    }

    It "Doesn't Execute code if the current computer name is member of the specified list" {
        $script:wasCalled = $false
        computer "zumsel" {
            $script:wasCalled = $true
        }
        $script:wasCalled | Should Be $false
    }
}

Describe "powershellHost DSL Item" {
    
    It "Execute code is the current processes powershell host name matches specified hostname" {
        $script:wasCalled = $false
        powershellHost $Host.Name {
            $script:wasCalled = $true
        }
        $script:wasCalled | Should Be $true
    }
     
    It "Execute code is the current processes powershell host name matches a specified hostname in the list" {
        $script:wasCalled = $false
        powershellHost "zumsel",$Host.Name {
            $script:wasCalled = $true
        }
        $script:wasCalled | Should Be $true
    }

    It "Don't execute code is the current processes powershell host name foesn't match specified hostname" {
        $script:wasCalled = $false
        powershellHost "zumsel" {
            $script:wasCalled = $true
        }
        $script:wasCalled | Should Be $false
    }
}