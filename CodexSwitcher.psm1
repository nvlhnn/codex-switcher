Set-StrictMode -Version Latest

function Invoke-CodexAccount {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('save', 'use', 'rename', 'delete', 'list', 'current')]
        [string] $Action = 'list',

        [Parameter(Position = 1)]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [string] $Name,

        [Parameter(Position = 2)]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [string] $NewName
    )

    $codexDir = Join-Path $HOME '.codex'
    $authFile = Join-Path $codexDir 'auth.json'
    $storeDir = Join-Path $codexDir 'accounts'
    $activeFile = Join-Path $storeDir '.active-account'

    New-Item -ItemType Directory -Force -Path $storeDir | Out-Null

    switch ($Action) {
        'save' {
            if (-not $Name) { throw 'Usage: codex-account save <name>' }
            if (-not (Test-Path -LiteralPath $authFile)) {
                throw "Codex auth file not found: $authFile"
            }

            Get-Content -LiteralPath $authFile -Raw |
                ConvertFrom-Json -ErrorAction Stop | Out-Null

            $destination = Join-Path $storeDir "$Name.auth.json"
            Copy-Item -LiteralPath $authFile -Destination $destination -Force
            Set-Content -LiteralPath $activeFile -Value $Name -NoNewline
            Write-Host "Saved the current Codex account as '$Name'."
        }

        'use' {
            if (-not $Name) { throw 'Usage: codex-account use <name>' }
            $source = Join-Path $storeDir "$Name.auth.json"
            if (-not (Test-Path -LiteralPath $source)) {
                throw "Saved account '$Name' does not exist."
            }

            Get-Content -LiteralPath $source -Raw |
                ConvertFrom-Json -ErrorAction Stop | Out-Null

            if ((Test-Path -LiteralPath $activeFile) -and
                (Test-Path -LiteralPath $authFile)) {
                $current = (Get-Content -LiteralPath $activeFile -Raw).Trim()
                if ($current -match '^[a-zA-Z0-9._-]+$') {
                    $currentFile = Join-Path $storeDir "$current.auth.json"
                    Copy-Item -LiteralPath $authFile -Destination $currentFile -Force
                }
            }

            $temporary = Join-Path $codexDir 'auth.json.switching'
            try {
                Copy-Item -LiteralPath $source -Destination $temporary -Force
                [System.IO.File]::Move($temporary, $authFile, $true)
            }
            finally {
                if (Test-Path -LiteralPath $temporary) {
                    Remove-Item -LiteralPath $temporary -Force
                }
            }

            Set-Content -LiteralPath $activeFile -Value $Name -NoNewline
            Write-Host "Codex account switched to '$Name'." -ForegroundColor Green
            Write-Host "In VS Code run: Developer: Reload Window" -ForegroundColor Yellow
        }

        'rename' {
            if (-not $Name -or -not $NewName) {
                throw 'Usage: codex-account rename <old-name> <new-name>'
            }

            $source = Join-Path $storeDir "$Name.auth.json"
            $destination = Join-Path $storeDir "$NewName.auth.json"

            if (-not (Test-Path -LiteralPath $source)) {
                throw "Saved account '$Name' does not exist."
            }
            if (Test-Path -LiteralPath $destination) {
                throw "Saved account '$NewName' already exists."
            }

            Move-Item -LiteralPath $source -Destination $destination

            if (Test-Path -LiteralPath $activeFile) {
                $current = (Get-Content -LiteralPath $activeFile -Raw).Trim()
                if ($current -eq $Name) {
                    Set-Content -LiteralPath $activeFile -Value $NewName -NoNewline
                }
            }

            Write-Host "Renamed Codex account '$Name' to '$NewName'."
        }

        'delete' {
            if (-not $Name) { throw 'Usage: codex-account delete <name>' }
            $accountFile = Join-Path $storeDir "$Name.auth.json"

            if (-not (Test-Path -LiteralPath $accountFile)) {
                throw "Saved account '$Name' does not exist."
            }

            if (Test-Path -LiteralPath $activeFile) {
                $current = (Get-Content -LiteralPath $activeFile -Raw).Trim()
                if ($current -eq $Name) {
                    throw "'$Name' is active. Switch to another account before deleting it."
                }
            }

            $confirmation = Read-Host "Permanently delete saved account '$Name'? [y/N]"
            if ($confirmation -notmatch '^(y|yes)$') {
                Write-Host 'Delete cancelled.'
                return
            }

            Remove-Item -LiteralPath $accountFile -Force
            Write-Host "Deleted saved Codex account '$Name'."
        }

        'list' {
            Get-ChildItem -LiteralPath $storeDir -Filter '*.auth.json' |
                ForEach-Object { $_.BaseName -replace '\.auth$', '' }
        }

        'current' {
            if (Test-Path -LiteralPath $activeFile) {
                Get-Content -LiteralPath $activeFile
            }
            else {
                Write-Host 'Current account is not registered.'
            }
        }
    }
}

Set-Alias -Name codex-account -Value Invoke-CodexAccount
Export-ModuleMember -Function Invoke-CodexAccount -Alias codex-account
