<#
╔════════════════════════════════════════════════════════════════════════════════╗
║ THE DEVELOPER MAKES NO GUARANTEE THAT THE POWERSHELL SCRIPT WILL SATISFY YOUR  ║
║ SPECIFIC REQUIREMENTS, OPERATE ERROR-FREE, OR FUNCTION WITHOUT INTERRUPTION.   ║
║ WHILE EVERY EFFORT HAS BEEN MADE TO ENSURE THE STABILITY AND EFFICACY OF THE   ║
║ SOFTWARE, IT IS INHERENT IN THE NATURE OF SOFTWARE DEVELOPMENT THAT UNEXPECTED ║
║ ISSUES MAY OCCUR. YOUR PATIENCE AND UNDERSTANDING ARE APPRECIATED AS I         ║
║ CONTINUALLY STRIVE TO IMPROVE AND ENHANCE MY SOFTWARE SOLUTIONS.               ║
╚════════════════════════════════════════════════════════════════════════════════╝
┌───────────┬────────────────────────────────────────────────────────────────────┐
│ Usage     │ 1) Run CMD or PowerShell                                           │
│           │ 2) powershell.exe -File .\sql-load-gen.ps1                         │
├───────────┼────────────────────────────────────────────────────────────────────┤
│ Developer │ Yigit Aktan - yigita@microsoft.com                                 │
└───────────┴────────────────────────────────────────────────────────────────────┘
#>

<# 
    Importing custom functions from the 'functions.psm1' module.
    This module contains various utility functions used throughout the script.
#>
Import-Module -DisableNameChecking .\functions.psm1

<# 
    Hiding the console cursor for cleaner visual output during script execution.
#>
[Console]::CursorVisible = $false

<# 
    Clearing the console to provide a clean slate for our script's output.
#>
Clear-Host

<# 
    Verifying the encoding of the script and its associated function file.
    Ensuring they are encoded in UTF-16LE or UTF-16BE, which is necessary for correct execution.
#>
Get_File_Encoding -FilePath $MyInvocation.MyCommand.Path
$FunctionFile = $PSScriptRoot + "\functions.psm1"
Get_File_Encoding -FilePath $FunctionFile

<# 
    Displaying the application header in the console, providing basic information about the script.
#>
$AppVer = "03.2024.2.001"
Write-Host " ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write_Color_Text -Text ' │                       ','SQL Load Generator','                        │' -Colour DarkGray,White,DarkGray
Write-Host " ├─────────────┬───────────┬──────────────────────┬────────────────┤" -ForegroundColor DarkGray
Write_Color_Text -Text ' │ ','Yigit Aktan',' │ ','Microsoft',' │ ','yigita@microsoft.com',' │ ',$AppVer,'  │' -Colour DarkGray,Gray,DarkGray,Gray,DarkGray,Gray,DarkGray,Gray,DarkGray
Write-Host " └─────────────┴───────────┴──────────────────────┴────────────────┘" -ForegroundColor DarkGray

<#
    The script validates the presence of 'config.txt', creating a sample with default settings if it's missing, and then terminates.
#>
$ConfigFile = $PSScriptRoot + "\config.txt"

if (-not (Test-Path $ConfigFile -PathType Leaf)) {
  try {
    "[AuthenticationType]=SQL" | Set-Content -Path $ConfigFile -Force
    "[ServerName]=SQLINSTANCE" | Add-Content -Path $ConfigFile
    "[DatabaseName]=AdventureWorks2019" | Add-Content -Path $ConfigFile
    "[UserName]=myuser" | Add-Content -Path $ConfigFile
    "[Password]=Password.1" | Add-Content -Path $ConfigFile
    "[ParallelConnections]=10" | Add-Content -Path $ConfigFile
    "[ExecutionTimeLimit]=300" | Add-Content -Path $ConfigFile
    "[SpFile]=sp.txt" | Add-Content -Path $ConfigFile
    "[RandomExecute]=0" | Add-Content -Path $ConfigFile

    Line_Drawer -x 0 -y 4 -Text ' └─────────────┴───────────┴──────────────────────┴────────────────┘' -Colour DarkGray -BlankLineCount 1
    Write_Error_Text -Text "config.txt file not found. However, an example config.txt has been created in the current directory. You should modify its contents according to your needs." -Prefix " [!]" -Color "Gray","Yellow"
    exit
  }
  catch {
    Line_Drawer -x 0 -y 4 -Text ' └─────────────┴───────────┴──────────────────────┴────────────────┘' -Colour DarkGray -BlankLineCount 1
    Write_Error_Text -Text "config.txt file not found. I attempted to create a new config.txt in the same directory as the script but was unsuccessful." -Prefix " [x]" -Color "Gray","Red"
    exit
  }
}

<# 
    Extracting configuration parameters from the configuration file.
    These parameters will be used to control how the script interacts with SQL Server.
#>
$AuthenticationType = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[AuthenticationType\]=(.*)$") { $Matches[1].Trim() } }
$ServerName = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[ServerName\]=(.*)$") { $Matches[1].Trim() } }
$ParallelConnections = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[ParallelConnections\]=(.*)$") { $Matches[1].Trim() } }
$DatabaseName = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[DatabaseName\]=(.*)$") { $Matches[1].Trim() } }
$UserName = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[UserName\]=(.*)$") { $Matches[1].Trim() } }
$Password = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[Password\]=(.*)$") { $Matches[1].Trim() } }
$ExecutionTimeLimit = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[ExecutionTimeLimit\]=(.*)$") { $Matches[1].Trim() } }
$SpFile = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[SpFile\]=(.*)$") { $Matches[1].Trim() } }
$RandomExecute = Get-Content -Path $ConfigFile | ForEach-Object { if ($_ -match "^\[RandomExecute\]=(.*)$") { $Matches[1].Trim() } }

<# 
    Validating the extracted configuration parameters to ensure they are present and correctly formatted.
#>
$ConfigParams = @{
  AuthenticationType = $AuthenticationType
  ServerName = $ServerName
  ParallelConnections = $ParallelConnections
  DatabaseName = $DatabaseName
  UserName = $UserName
  Password = $Password
  ExecutionTimeLimit = $ExecutionTimeLimit
  SpFile = $SpFile
  RandomExecute = $RandomExecute
}

Validate_Config_File -ConfigParams $ConfigParams

<# 
    Constructing the connection string based on the extracted and validated configuration parameters.
#>
if ($AuthenticationType.ToUpper() -eq "WIN") {
  $Global:Connectionstring = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=True;"
}
elseif ($AuthenticationType.ToUpper() -eq "SQL") {
  $Global:Connectionstring = "Server=$ServerName;Database=$DatabaseName;User Id=$UserName;Password=$Password;"
}

<# 
    Testing the SQL connection to ensure the script can communicate with SQL Server.
#>
$ConnectionSuccessful = Connection_Spinner -Function {
  param($ConnString)
  try {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $ConnString
    $SqlConnection.Open()
    $SqlConnection.Close()
    return $true
  }
  catch {
    $SqlConnection.Close()
    return $false
  }
} -Label "Establishing connection to the server..."

if (-not $ConnectionSuccessful) {
  Line_Drawer -x 0 -y 4 -Text ' └─────────────┴───────────┴──────────────────────┴────────────────┘' -Colour DarkGray -BlankLineCount 1
  Write_Error_Text -Text "Failed to establish SQL connection. Please check the credentials in the config.txt file." -Prefix " [x]" -Color "Gray","Red"
  Write-Host
  exit
}

Line_Drawer -x 0 -y 4 -Text ' ├─────────────┴───────────┴──────────────────────┼────────────────┤' -Colour DarkGray -BlankLineCount 0

<# 
    Opening SQL connections based on the 'ParallelConnections' configuration parameter.
#>
$SuccessfulSpCount = 0
$ErrorSpCount = 0
$Connections = @()

for ($i = 1; $i -le $ParallelConnections; $i++) {
  $Connection = New-Object System.Data.SqlClient.SqlConnection
  $Connection.ConnectionString = $Global:Connectionstring
  $Connection.Open()
  $Connections += $Connection
}

<# 
    Setting the start time and end time for the script's execution.
#>
$CountdownStartTime = Get-Date
$EndTime = $CountdownStartTime.AddSeconds($ExecutionTimeLimit)

$RemainingTime = $EndTime - (Get-Date)
$RemainingTimeFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $RemainingTime.Hours,$RemainingTime.Minutes,$RemainingTime.Seconds

<# 
    Reading stored procedures (SPs) from the specified file and optionally randomizing their order of execution.
#>
$SpFilePath = $PSScriptRoot + "\" + $SpFile
$SpContent = Get-Content -Path $SpFilePath

if ($RandomExecute -eq 1) {
  $SpContent = $SpContent | Get-Random -Count $SpContent.Count
}

<# 
    Main execution loop: The script will execute stored procedures until the specified end time.
#>
while ((Get-Date) -lt $EndTime) {
  $RemainingTime = $EndTime - (Get-Date)
  $RemainingTimeFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $RemainingTime.Hours,$RemainingTime.Minutes,$RemainingTime.Seconds

  $ProgressPercentage = [math]::Min([math]::Round((1 - ($RemainingTime.TotalSeconds / $ExecutionTimeLimit)) * 100),100)

  $ProgressBar += "    $RemainingTimeFormatted    ║"

  Move_The_Cursor 1 5
  Write_Color_Text -Text '│' -Colour DarkGray

  Move_The_Cursor 50 5
  Write_Color_Text -Text '│' -Colour DarkGray

  Move_The_Cursor 55 5
  Write_Color_Text -Text $RemainingTimeFormatted -Colour Yellow

  Move_The_Cursor 67 5
  Write_Color_Text -Text '│' -Colour DarkGray

  Move_The_Cursor 3 5
  Write_Color_Text -Text ('█' * [math]::Min([math]::Ceiling(($ProgressPercentage / 2)),46)) + (' ' * [math]::Max(0,46 - [math]::Ceiling(($ProgressPercentage / 2)))) -Colour Yellow

  Line_Drawer -x 1 -y 6 -Text '└────────────────────────────────────────────────┴────────────────┘' -Colour DarkGray -BlankLineCount 0

  $ErrFile = $PSScriptRoot + "\errlog.txt"

  foreach ($SpLine in $SpContent) {
    $SpInfo = $SpLine -split ';'
    $SpName = $SpInfo[0].Trim()

    try {
      $SpParams = @{}
      for ($i = 1; $i -lt $SpInfo.Length; $i++) {
        $ParamInfo = $SpInfo[$i] -split '=' | ForEach-Object { $_.Trim() }
        $ParamName = $ParamInfo[0]
        $ParamValue = $ParamInfo[1]
        $SpParams[$ParamName] = $ParamValue
      }

      foreach ($Connection in $Connections) {
        $Command = $Connection.CreateCommand()
        $Command.CommandType = [System.Data.CommandType]::StoredProcedure
        $Command.CommandText = $SpName

        $ParamTexts = @()
        foreach ($ParamName in $SpParams.Keys) {
          $Param = $Command.CreateParameter()
          $Param.ParameterName = $ParamName
          $Param.Value = Generate_Random_Parameter_Values ($SpParams[$ParamName])
          $Command.Parameters.Add($Param) | Out-Null

          if ($Param.Value -is [string]) {
            $ParamTexts += "$ParamName=N'$($Param.Value)'"
          }
          else {
            $ParamTexts += "$ParamName=$($Param.Value)"
          }
        }

        $Command.ExecuteNonQuery() | Out-Null
        $SuccessfulSpCount++

      }
    }
    catch {
      $QueryText = "EXEC $SpName " + ($ParamTexts -join ",")
      Write-ErrorToFile -FilePath $ErrFile -ErrorMsgSpName $SpName -ErrorMsgSpSent $QueryText -ErrorMsgException $($_.Exception.InnerException.Message) | Out-Null
      $ErrorSpCount++
    }
  }
}

<# 
    Closing all SQL connections opened by the script.
#>
foreach ($Connection in $Connections) {
  $Connection.Dispose()
}

<# 
    Displaying a completion message and making the console cursor visible again.
#>
Move_The_Cursor 54 5
Write_Color_Text -Text 'Completed' -Colour Yellow
Write-Host
Write-Host
Write_Color_Text -Text ' Total SPs executed successfully: ',$SuccessfulSpCount -Colour DarkGray,White
Write_Color_Text -Text ' Total SPs failed: ',$ErrorSpCount -Colour DarkGray,White
Write-Host
[Console]::CursorVisible = $true
