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
    This function checks the encoding of a file and ensures it is either UTF-16LE or UTF-16BE.
    If the encoding is not one of these, it writes an error message and exits the script.
#>
function Get_File_Encoding {
  param(
    [string]$FilePath
  )

  $Byte = Get-Content -Encoding Byte -ReadCount 2 -TotalCount 2 -Path $FilePath
  if ($Byte[0] -eq 0xff -and $Byte[1] -eq 0xfe) {
    #Return 'UTF-16LE'
  }
  elseif ($Byte[0] -eq 0xfe -and $Byte[1] -eq 0xff) {
    #Return 'UTF-16BE'
  }
  else {
    Write_Color_Text -Text ' SQL Load Generator' -Colour Yellow
    Write-Host ""
    Write_Error_Text -Text "The 'sql-log-gen.ps1' and 'functions.psm1' files must be in either UTF-16LE or UTF-16BE encoding. Please open these files in a text editor like Notepad++ and save them as specified." -Prefix " [x]" -Color "Gray","Red"
    exit
  }
}

<# 
    This function moves the cursor to a specified position in the console window.
    It is useful for controlling where text is output in the console. 
#>
function Move_The_Cursor ([int]$x,[int]$y) {
  $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $x,$y
}

<# 
    This function writes text to the console in specified colors.
    It allows for colorful console output to make messages stand out. 
#>
function Write_Color_Text {
  param([String[]]$Text,[ConsoleColor[]]$Colour,[switch]$NoNewline = $false)
  for ([int]$i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -Foreground $Colour[$i] -NoNewline }
  if ($NoNewline -eq $false) { Write-Host '' }
}

<# 
    This function draws a line in the console and can also output text in specified colors.
    It is useful for creating visually distinct sections in the console output. 
#>
function Line_Drawer {
  param([int]$x,[int]$y,[int]$BlankLineCount = 0,[String[]]$Text,[ConsoleColor[]]$Colour,[switch]$NoNewline = $false)
  $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $x,$y
  for ([int]$i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -Foreground $Colour[$i] -NoNewline }
  if ($NoNewline -eq $false) { Write-Host '' }
  for ($j = 1; $j -le $BlankLineCount; $j++) { Write-Host '' }
}

<# 
    This function generates random parameter values based on a provided input string.
    It is useful for creating dynamic input for testing or other purposes. 
#>
function Generate_Random_Parameter_Values ([string]$InputString) {
  $RndTextRegex = [regex]::new("\{rnd-text:(\d+),([A-Za-z]+)\}")
  $RndNumberRegex = [regex]::new("\{rnd-number:(\d+),([0-9]+)\}")
  $RndDateRegex = [regex]::new("\{rnd-date:([0-9]+)-([0-9]+)\}")
  $Rand = New-Object Random

  $OutputString = $RndTextRegex.Replace($InputString,{
      param($Match)
      $Length = [int]::Parse($Match.Groups[1].Value)
      $Characters = $Match.Groups[2].Value
      $Result = New-Object System.Text.StringBuilder
      1..$Length | ForEach-Object {
        $c = $Characters[$Rand.Next(0,$Characters.Length)]
        [void]$Result.Append($c)
      }
      return $Result.ToString()
    })

  $OutputString = $RndNumberRegex.Replace($OutputString,{
      param($Match)
      $Length = [int]::Parse($Match.Groups[1].Value)
      $Numbers = $Match.Groups[2].Value
      $Result = New-Object System.Text.StringBuilder
      1..$Length | ForEach-Object {
        $c = $Numbers[$Rand.Next(0,$Numbers.Length)]
        [void]$Result.Append($c)
      }
      return $Result.ToString()
    })

  $OutputString = $RndDateRegex.Replace($OutputString,{
      param($Match)
      $StartYear = [int]::Parse($Match.Groups[1].Value)
      $EndYear = [int]::Parse($Match.Groups[2].Value)
      $Year = $Rand.Next($StartYear,$EndYear + 1)
      $Month = $Rand.Next(1,13)
      $DaysInMonth = [datetime]::DaysInMonth($Year,$Month)
      $Day = $Rand.Next(1,$DaysInMonth + 1)
      $DateStr = (Get-Date -Year $Year -Month $Month -Day $Day).ToString("yyyy-MM-dd")
      return $DateStr
    })

  return $OutputString
}

<# 
    This function writes an error message to a specified file.
    It is useful for logging errors for later review. 
#>
function Write-ErrorToFile {
  param(
    [string]$FilePath,
    [string]$ErrorMsgSpName,
    [string]$ErrorMsgSpSent,
    [string]$ErrorMsgException
  )

  if (-not (Test-Path $FilePath)) {
    New-Item -Path $FilePath -ItemType File -Force
  }

  $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

  $RetryCount = 0
  $MaxRetries = 5
  $WaitSeconds = 2

  do {
    try {
      $FileStream = [System.IO.File]::Open($FilePath,[System.IO.FileMode]::Append,[System.IO.FileAccess]::Write,[System.IO.FileShare]::Read)
      $StreamWriter = New-Object System.IO.StreamWriter ($FileStream)
      $StreamWriter.WriteLine("Created: $Timestamp")
      $StreamWriter.WriteLine("SP Name: $ErrorMsgSpName")
      $StreamWriter.WriteLine("SP Sent: $ErrorMsgSpSent")
      $StreamWriter.WriteLine("Err Msg: $ErrorMsgException")
      $StreamWriter.WriteLine("------------------------------------------------------------")
      $StreamWriter.WriteLine("")
      $StreamWriter.Close()
      $FileStream.Close()
      $RetryCount = $MaxRetries
    }
    catch {
      if ($RetryCount -ge $MaxRetries) {

      } else {
        Start-Sleep -Seconds $WaitSeconds
        $RetryCount++
      }
    }
  } while ($RetryCount -lt $MaxRetries)
}

<# 
    This function displays a spinning animation in the console while running a specified function.
    It provides a visual indicator that something is happening in the background. 
#>
function Connection_Spinner {
  param([scriptblock]$function,[string]$Label)

  $JobArguments = @($Global:Connectionstring)
  $Job = Start-Job -ScriptBlock $function -ArgumentList $jobArguments

  #$Symbols = @("⣾⣿", "⣽⣿", "⣻⣿", "⢿⣿", "⡿⣿", "⣟⣿", "⣯⣿", "⣷⣿", "⣿⣾", "⣿⣽", "⣿⣻", "⣿⢿", "⣿⡿", "⣿⣟", "⣿⣯", "⣿⣷")
  $Symbols = @("|","/","-","\")
  $i = 0;

  while ($Job.State -eq "Running") {
    $Symbol = $Symbols[$i]

    Line_Drawer -x 0 -y 4 -Text ' └─────────────┴───────────┴──────────────────────┴────────────────┘' -Colour DarkGray -BlankLineCount 1

    Write-Host -NoNewline " [" -ForegroundColor Gray
    Write-Host -NoNewline "$symbol" -ForegroundColor DarkGray
    Write-Host -NoNewline "]" -ForegroundColor Gray
    Write-Host " $Label" -ForegroundColor Yellow -NoNewline

    Start-Sleep -Milliseconds 100
    $i++
    if ($i -eq $Symbols.Count) {
      $i = 0;
    }
  }
  $Result = Receive-Job -Job $Job
  Remove-Job -Job $Job
  return $Result
}

<# 
    This function writes error messages to the console in a standardized format.
    It ensures that error messages are consistently formatted and colored. 
#>
function Write_Error_Text {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,

    [Parameter(Mandatory = $true)]
    [string]$Prefix,

    [Parameter(Mandatory = $true)]
    [string[]]$Color
  )

  $PrefixColor = $Color[0]

  $TextColor = $Color[1]

  function GetNextLine ([string]$RemainingText,[int]$MaxLength) {
    if ($RemainingText.Length -le $MaxLength) { return $RemainingText }

    $BreakPoint = $MaxLength
    while ($BreakPoint -gt 0 -and ($RemainingText[$BreakPoint] -ne ' ')) {
      $BreakPoint --
    }

    if ($BreakPoint -eq 0) {
      $BreakPoint = $MaxLength
    }

    return $RemainingText.Substring(0,$BreakPoint)
  }

  $FirstLineMaxLen = 68 - $Prefix.Length - 1
  $FirstLine = GetNextLine $Text $FirstLineMaxLen
  $Text = $Text.Substring($FirstLine.Length).Trim()

  Write-Host $Prefix -NoNewline -ForegroundColor $PrefixColor
  Write-Host " $FirstLine" -ForegroundColor $TextColor

  $Padding = " " * ($Prefix.Length + 1)

  while ($Text.Length -gt 0) {
    $Line = GetNextLine $Text 64
    $Text = $Text.Substring($Line.Length).Trim()

    Write-Host "$Padding$Line" -ForegroundColor $TextColor
  }
}

<# 
    This function validates the parameters read from a configuration file.
    It checks that mandatory parameters are present and correctly formatted, and writes error messages if not. 
#>
function Validate_Config_File {
  param(
    [hashtable]$ConfigParams
  )

  $ErrorMessages = @()

  if ($null -eq $ConfigParams['AuthenticationType'])
  { $ErrorMessages += "[AuthenticationType] parameter was not found in the config.txt file." }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['AuthenticationType']) -or (($ConfigParams['AuthenticationType'].ToUpper() -ne "SQL") -and ($ConfigParams['AuthenticationType'].ToUpper() -ne "WIN")))
    { $ErrorMessages += "You must write 'WIN' for Windows authentication or 'SQL' for SQL Server Authentication as the value for [AuthenticationType] parameter. The parameter cannot be left empty" }
    else {
      if ($ConfigParams['AuthenticationType'].ToUpper() -eq "SQL") {
        if ($null -eq $ConfigParams['UserName'])
        { $ErrorMessages += "[Username] parameter was not found in the config.txt file. Since you selected [AuthenticationType] parameter as 'SQL' [Username] parameter is mandatory." }
        else {
          if ([string]::IsNullOrEmpty($ConfigParams['UserName']))
          { $ErrorMessages += "If [AuthenticationType] parameter is set to 'SQL', you cannot leave the [Username] parameter empty." }
        }
        if ($null -eq $ConfigParams['Password'])
        { $ErrorMessages += "[Password] parameter was not found in the config.txt file. Since you selected [AuthenticationType] parameter as 'SQL' [Password] parameter is mandatory." }
        else {
          if ([string]::IsNullOrEmpty($ConfigParams['Password']))
          { $ErrorMessages += "If [AuthenticationType] parameter is set to 'SQL', you cannot leave the [Password] parameter empty." }
        }
      }
    }
  }

  if ($null -eq $ConfigParams['ServerName']) {
    $ErrorMessages += "[ServerName] parameter was not found in the config.txt file."
  }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['ServerName'])) {
      $ErrorMessages += "You cannot enter an empty value for [ServerName] parameter."
    }
  }

  if ($null -eq $ConfigParams['DatabaseName']) {
    $ErrorMessages += "[DatabaseName] parameter was not found in the config.txt file."
  }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['DatabaseName'])) {
      $ErrorMessages += "You cannot enter an empty value for [DatabaseName] parameter."
    }
  }

  if ($null -eq $ConfigParams['ParallelConnections']) {
    $ErrorMessages += "[ParallelConnections] parameter was not found in the config.txt file."
  }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['ParallelConnections'])) {
      $ErrorMessages += "You cannot enter an empty value for [ParallelConnections] parameter."
    }
    else {
      if ($ConfigParams['ParallelConnections'] -notmatch '^\d+$') {
        $ErrorMessages += "Only numerical values can be entered for [ParallelConnections] parameter."
      }
    }
  }

  if ($null -eq $ConfigParams['ExecutionTimeLimit']) {
    $ErrorMessages += "[ExecutionTimeLimit] parameter was not found in the config.txt file."
  }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['ExecutionTimeLimit'])) {
      $ErrorMessages += "You cannot enter an empty value for [ExecutionTimeLimit] parameter."
    }
    else {
      if ($ConfigParams['ExecutionTimeLimit'] -notmatch '^\d+$') {
        $ErrorMessages += "Only numerical values can be entered for [ExecutionTimeLimit] parameter."
      }
    }
  }

  if ($null -eq $ConfigParams['SpFile']) {
    $ErrorMessages += "[SpFile] parameter was not found in the config.txt file."
  }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['SpFile'])) {
      $ErrorMessages += "You cannot enter an empty value for [SpFile] parameter."
    }
    else {
      if (-not (Test-Path $ConfigParams['SpFile'] -PathType Leaf)) {
        $ErrorMessages += "The file defined in the [SpFile] parameter within config.txt could not be found. Make sure the file is in the same directory as the script."
      }
    }
  }

  if ($null -eq $ConfigParams['RandomExecute']) {
    $ErrorMessages += "[RandomExecute] parameter was not found in the config.txt file."
  }
  else {
    if ([string]::IsNullOrEmpty($ConfigParams['RandomExecute'])) {
      $ErrorMessages += "You cannot enter an empty value for [RandomExecute] parameter."
    }
    else {
      if ($ConfigParams['RandomExecute'] -notmatch '^[01]$') {
        $ErrorMessages += "Only 0 and 1 can be entered for [RandomExecute] parameter.     0 = False (Execute the SPs in order as they appear in the file) 1 = True  (Execute them randomly for each parallel connection)"
      }
    }
  }

  if ($ErrorMessages.Count -gt 0) {
    Write-Host ""
    $ErrorMessages | ForEach-Object {
      Write_Error_Text -Text $_ -Prefix " [x]" -Color "Gray","Red"
      Write-Host ""
    }
    exit
  }

}
