# Set $environment variables and run script. You're welcome.

$environment = @{
    servers = @{ 
        Live = @('.')
        Target = @{ 
            RNDB = '.'
            Svcs = '.'
            Nav = '.'
            ePCR = '.'
        }
    }
    filePaths = @{ 
        currentCentralShare = 'Q:\Old\CentralShare'
        newCentralShare = 'Q:\ZollData\CentralShare'
        currentePCRConfigs = 'C:\programdata\ZOLL Data Systems\Configurations'
        backupLocation = 'Q:\ZollData\Databases\Backup'
    }
}

# build ZOLL database hash table
$dbList = @{
    RNDB = @('RCSQL', 'Forms', 'PPAPI')
    Svcs = @('RNEventing', 'RNEnterprise', 'UDXMapping')
    Nav = @('ZollData.NavigatorServer')
    ePCR = @('eDistribution', 'Extract', 'PCRServer', 'ZollData.MSCS.PCR.Archive', 'Zolldata.StaticData', 'Zolldata.System','ZOLLData.MercuryMessage')
}

# Begin migration

# Start robocopy as a background job
Start-Job -ScriptBlock { robocopy $args[0] $args[1] /mt /z /e /copyall } -ArgumentList $environment['filePaths']['currentCentralShare'], $environment['filePaths']['newCentralShare']

# Backup and Restore databases
foreach ( $server in $environment['servers']['Live'] ) {
    $dbsPresent = [System.Collections.ArrayList](Get-SqlDatabase -ServerInstance $server) | Where-Object { (-not($_ -match 'master|model|msdb|tempdb')) } | Select-Object -expand Name
    foreach ( $db in $dbsPresent ) {
        $backupFile = $environment['filePaths']['backupLocation'] + "\$db.bak"
        $targetGroup = $dbList.keys | Where-Object { $dbList[$_] -eq $db }
        Backup-SqlDatabase -CopyOnly -ServerInstance $server -Database $db -BackupFile $backupFile | Out-Null
        Write-Output "$db backup successfull"
        Restore-SqlDatabase -RestoreAction Files -ReplaceDatabase -ServerInstance $environment['servers']['Target'][$targetGroup] -Database $db -BackupFile $backupFile
        Write-Output "$db restored succesfully"
    }
}
Get-Job | Wait-Job
Write-Output "Fin."
Read-Host -Prompt "Press Enter to exit"