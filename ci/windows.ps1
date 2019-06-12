Param( 
    [Parameter(Mandatory=$False,Position=1)]
    [string]$ServerVersion,
    [Parameter(Mandatory=$False)]
    [string]$Framework,
    [Parameter(Mandatory=$False)]
    [switch]$InstallDotnet = $True
)

Function Write-TeamCity($Text) 
{
    If ($env:TEAMCITY_PROJECT_NAME) 
    {
        Echo $Text
    } 
}

$RootDir = Split-Path -parent $PSCommandPath

# Install dotnet core
$DotnetDir = "$RootDir\..\Build\dotnet"
If ($InstallDotnet -and !(Test-Path -Path $DotnetDir -PathType Container)) {
    Write-TeamCity "##teamcity[progressStart 'Installing dotnet']"

    &powershell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://dot.net/v1/dotnet-install.ps1'))) -Channel 2.0 -Version latest -InstallDir $DotnetDir -NoPath"
    If ($LastExitCode -ne 0) {
        Write-TeamCity "##teamcity[buildStatus status='FAILURE' text='dotnet installation failed']"
        Exit $LastExitCode
    }

    $env:Path = "$DotnetDir;$env:Path"
    Write-TeamCity "##teamcity[progressFinish 'Installed dotnet']"
}

Invoke-Expression "$RootDir\..\Neo4j.Driver\runTests.ps1 $(If ($ServerVersion) {"-ServerVersion '$ServerVersion'"}) $(If ($Framework) {"-Framework '$Framework'"})"
Exit $LastExitCode
