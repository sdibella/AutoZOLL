# Set $envieronment variables and run script. You're welcome.

$RNePCRUser = "yes" # yes/no

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
    Services = @('RNEventing', 'RNEnterprise', 'UDXMapping')
    Navigator = @('ZollData.NavigatorServer')
    ePCR = @('eDistribution', 'Extract', 'PCRServer', 'ZollData.MSCS.PCR.Archive', 'Zolldata.StaticData', 'Zolldata.System','ZOLLData.MercuryMessage')
 }

 # Create ePCR config list or remove ePCR databases
 if ( $RNePCRUser = 'no' ) {
    $dbList.Remove('ePCR')
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
        Backup-SqlDatabase -ServerInstance $server -Database $db -CopyOnly -BackupFile $backupFile
        Write-Output "$db backup successfull, attempting to restore to target server as background job"
        Restore-SqlDatabase -ReplaceDatabase -ServerInstance $environment['servers']['Target'][$targetGroup] -Database $db -BackupFile $backupFile
    }
 }