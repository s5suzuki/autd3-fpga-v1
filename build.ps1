# File: build.ps1
# Project: autd3-library-firmware-fpga
# Created Date: 06/12/2021
# Author: Shun Suzuki
# -----
# Last Modified: 06/12/2021
# Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
# -----
# Copyright (c) 2021 Hapis Lab. All rights reserved.
# 


Param(
    [string]$vivado_dir = "NULL",
    [uint16]$version_num = 0,
    [int]$bram_width = 64
)

function ColorEcho($color, $PREFIX, $message) {
    Write-Host $PREFIX -ForegroundColor $color -NoNewline
    Write-Host ":", $message
}

function FindVivado() {
    $xilinx_reg = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object DisplayName -match Vivado | Select-Object -first 1
    if ($xilinx_reg) {
        return $xilinx_reg.InstallLocation
    }
    else {
        return "NULL"
    }
}

Start-Transcript "build.log" | Out-Null
Write-Host "Vivado project build"

ColorEcho "Green" "INFO" "Generationg coefficient file..."
./generate_bram_init_coe.ps1 -version_num $version_num -bram_width $bram_width

ColorEcho "Green" "INFO" "Invoking Vivado..."
if (-not (Get-Command vivado -ea SilentlyContinue)) {
    if ($vivado_dir -eq "NULL") {
        ColorEcho "Green" "INFO" "Vivado is not found in PATH. Looking for Vivado..."
        $xilinx_path = FindVivado
        if (($xilinx_path -eq "NULL")) {
            ColorEcho "Red" "Error" "Vivado is not found. Install Vivado."
            Stop-Transcript | Out-Null
            $host.UI.RawUI.ReadKey() | Out-Null
            exit
        }
        
        $vivado_path = Join-Path $xilinx_path "Vivado"
        if (-not (Test-Path $vivado_path)) {
            ColorEcho "Red" "Error" "Vivado is not found. Install Vivado."
            Stop-Transcript | Out-Null
            $host.UI.RawUI.ReadKey() | Out-Null
            exit
        }
        
        $vivados = Get-ChildItem $vivado_path
        if ($vivados.Length -eq 0) {
            ColorEcho "Red" "Error" "Vivado is not found. Install Vivado."
            Stop-Transcript | Out-Null
            $host.UI.RawUI.ReadKey() | Out-Null
            exit
        }

        $vivado_ver = $vivados | Select-Object -first 1
        ColorEcho "Green" "INFO" "Find Vivado", $vivado_ver.Name
        $vivado_dir = $vivado_ver.FullName
    }

    $vivado_bin = Join-Path $vivado_dir "bin"
    $vivado_lib = Join-Path $vivado_dir "lib" | Join-Path -ChildPath "win64.o" 
    $env:Path = $env:Path + ";" + $vivado_bin + ";" + $vivado_lib
}
$command = "vivado -mode batch -source autd3-fpga.tcl"
Invoke-Expression $command

ColorEcho "Green" "INFO" "Press any key to exit..."
Stop-Transcript | Out-Null
$host.UI.RawUI.ReadKey() | Out-Null
exit
