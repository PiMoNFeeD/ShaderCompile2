[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)][System.IO.FileInfo]$File,
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$false)][switch]$Dynamic,
    [Parameter(Mandatory=$false)][System.UInt32]$Threads
)

$versionList = @("20", "20b", "30", "40", "41", "50", "51")
$versionIndex = [array]::IndexOf($versionList, $Version)

if ($versionIndex -lt 0) {
	return
}

function CheckFileVersion {
	param (
		[string]$file
	)

	for ( $i = 0; $i -lt $versionList.Length; $i++ ) {
		if ( $file.EndsWith( $versionList[$i], [System.StringComparison]::OrdinalIgnoreCase ) ) {
			return ($versionIndex -ge $i)
		}
	}

	return $true
}

$fileList = $File.OpenText()
while ($null -ne ($line = $fileList.ReadLine())) {
	if ($line -match '^\s*$' -or $line -match '^\s*//') {
		continue
	}

	if ( !(CheckFileVersion -file ([System.IO.Path]::GetFileNameWithoutExtension( $line ))) ) {
		continue
	}

	if ($Dynamic) {
		& "$PSScriptRoot\ShaderCompile" "-dynamic" "-ver" $Version "-shaderpath" $File.DirectoryName $line
		continue
	}

	if ($Threads -ne 0) {
		& "$PSScriptRoot\ShaderCompile" "-threads" $Threads "-ver" $Version "-shaderpath" $File.DirectoryName $line
		continue
	}

	& "$PSScriptRoot\ShaderCompile" "-ver" $Version "-shaderpath" $File.DirectoryName $line
}
$fileList.Close()
