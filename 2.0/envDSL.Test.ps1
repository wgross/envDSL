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

Describe "Add-EnvPathVariable" {
    
    BeforeAll {
        Remove-Item "Env:\samplePath" -ErrorAction SilentlyContinue
    }

    It "Adds a directory at the end of an empty variable" {
        $env:SamplePath = $null
        Add-EnvPath -Path "Env:\samplePath" -Append "TestDrive:\test"
        $env:samplePath | Should Be "TestDrive:\test"
    }
    
    It "Adds a directory at the end of an non-empty variable" {
        $env:SamplePath = "C:\another\path"
        Add-EnvPath -Path "Env:\samplePath" -Append "TestDrive:\test"
        $env:samplePath | Should Be "C:\another\path;TestDrive:\test"
    }

    It "Adds a multiple directories at the end of the specified order of an non-empty variable" {
        $env:SamplePath = "C:\another\path"
        Add-EnvPath -Path "Env:\samplePath" -Append "D:\some\path","TestDrive:\test"
        $env:samplePath | Should Be "C:\another\path;D:\some\path;TestDrive:\test"
    }

    It "Moves a directory at the end if it is appended a second time" {
        $env:SamplePath = "D:\first;C:\another\path"
        Add-EnvPath -Path "Env:\samplePath" -Append "D:\first"
        $env:samplePath | Should Be "C:\another\path;D:\first"
    }

    It "Adds a directory at the beginning of an empty variable" {
        $env:SamplePath = $null
        Add-EnvPath -Path "Env:\samplePath" -Prepend "TestDrive:\test"
        $env:samplePath | Should Be "TestDrive:\test"
    }

    It "Adds a directory at the begining of an non-empty variable" {
        $env:SamplePath = "C:\another\path"
        Add-EnvPath -Path "Env:\samplePath" -Prepend "TestDrive:\test"
        $env:samplePath | Should Be "TestDrive:\test;C:\another\path"
    }

    It "Adds a multiple directories at the beginning of the specified order of an non-empty variable" {
        $env:SamplePath = "C:\another\path"
        Add-EnvPath -Path "Env:\samplePath" -Prepend "D:\some\path","TestDrive:\test"
        $env:samplePath | Should Be "D:\some\path;TestDrive:\test;C:\another\path"
    }

    It "Moves a directory at the Beginning if it is prepended a second time" {
        $env:SamplePath = "C:\another\path;E:\last"
        Add-EnvPath -Path "Env:\samplePath" -Prepend "E:\last"
        $env:samplePath | Should Be "E:\last;C:\another\path"
    }
} 

Describe "Test-AdminUser" {
    
    It "Doesn't execute a script blo$ck if the current user isn't an admin User" {
        $script:wasExecuted = $false
        Test-AdminUser | Should Be $false
    }

    It "Throws instead of returning false if an error test text is given" {
        try {
            Test-AdminUser -Throw "Not Admin"
        } catch {
            $_.ToString() | Should Be "Not Admin"
        }
    }
}