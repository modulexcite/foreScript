﻿<# 
    https://servergeeks.wordpress.com/2013/05/14/t-sql-monitoring-database-backup-status/
    http://thomaslarock.com/2012/05/how-to-find-long-running-backups-in-sql-server/
    https://www.mssqltips.com/sqlservertip/2850/querying-sql-server-agent-job-history-data/
    http://sqlrepository.co.uk/code-snippets/sql-dba-code-snippets/script-to-finds-failed-sql-server-agent-jobs/


function Get-QueryResults {

    Param (
        $SQLConnection,
        $Query
    )

    $ds = New-object "System.Data.DataSet" "SQLServerChecklistData"
    #$ds = New-object "System.Data.DataTable" "SQLServerChecklistData"
    $da = New-Object "System.Data.SqlClient.SqlDataAdapter" ($Query, $SQLConnection)
    $da.Fill($ds) | Out-Null
    return @(,$ds)
    
}

               msdb.dbo.backupset.backup_finish_date, msdb.dbo.backupset.expiration_date,

               CASE msdb..backupset.type

                WHEN 'D' THEN 'Database'

                WHEN 'L' THEN 'Log'

              END AS backup_type,

             msdb.dbo.backupset.backup_size, msdb.dbo.backupmediafamily.logical_device_name, msdb.dbo.backupmediafamily.physical_device_name,

             msdb.dbo.backupset.name AS backupset_name, msdb.dbo.backupset.description

             FROM msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id

             WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 1)

             ORDER BY msdb.dbo.backupset.database_name, msdb.dbo.backupset.backup_finish_date"
                             ;
                             WITH BackupHistData AS
                             (
                                SELECT database_guid, type, MAX(backup_set_id) AS [MAX_BSID]
	                            ,AVG(CAST(DATEDIFF(s, backup_start_date, backup_finish_date) AS int)) AS [AVG]
	                            ,STDEVP(CAST(DATEDIFF(s, backup_start_date, backup_finish_date) AS int)) AS [SIGMA]
	                            FROM msdb.dbo.backupset GROUP BY database_guid, type
                              )
                                SELECT bup.database_name, bup.backup_set_id, bup.type
	                            ,CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int) AS [backup_time_sec]
	                            ,bhd.[AVG] as [avg_sec] ,(1.0*bhd.[AVG]+2.0*bhd.SIGMA) as [max_duration_sec]
                                 
                                 FROM BackupHistData bhd INNER JOIN msdb.dbo.backupset bup ON bhd.database_guid = bup.database_guid

                                /*Filter for the outliers*/
                                WHERE CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int) > (1.0*bhd.[AVG]+2.0*bhd.SIGMA)

                                /*Filter for only the most recent backup, if desired*/
                                AND bup.backup_set_id = bhd.MAX_BSID

                                /*Filter for backups with an average duration time, if desired*/
                                AND bhd.[AVG] >= @MinAvgSecsDuration

                                /*Filter for specific backup types, if desired*/
                                AND bhd.type IN ('D', 'I', 'L')"
                      SET @Date = DATEADD(dd, -1, GETDATE()) -- Last 1 day


                     SELECT j.[name] [Agnet_Job_Name], js.step_name [Step_name], js.step_id [Step ID], js.command [Command_executed], js.database_name [Databse_Name],
                     msdb.dbo.agent_datetime(h.run_date, h.run_time) as [Run_DateTime] , h.sql_severity [Severity], h.message [Error_Message], h.server [Server_Name],
                     h.retries_attempted [Number_of_retry_attempts],
                     CASE h.run_status 
                      WHEN 0 THEN 'Failed'
                      WHEN 1 THEN 'Succeeded'
                      WHEN 2 THEN 'Retry'
                      WHEN 3 THEN 'Canceled'
                    END as [Job_Status],
                    CASE js.last_run_outcome
                      WHEN 0 THEN 'Failed'
                      WHEN 1 THEN 'Succeeded'
                      WHEN 2 THEN 'Retry'
                      WHEN 3 THEN 'Canceled'
                      WHEN 5 THEN 'Unknown'
                   END as [Outcome_of_the_previous_execution]
                   FROM msdb.dbo.sysjobhistory h INNER JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id 
                   INNER JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id AND h.step_id = js.step_id
                   WHERE h.run_status = 0 AND msdb.dbo.agent_datetime(h.run_date, h.run_time)> @Date 
                                Declare @Date2 datetime

                                Set @Date1 = DATEADD(dd, -2, GETDATE()) --2 Days ago
                                Set @Date2 = DATEADD(dd, -1, GETDATE()) --1 day ago

                                select j.name as 'JobName', s.step_id as 'Step', s.step_name as 'StepName',
                                msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
                                ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'RunDurationMinutes'
                                From msdb.dbo.sysjobs j 
                                INNER JOIN msdb.dbo.sysjobsteps s 
                                ON j.job_id = s.job_id
                                INNER JOIN msdb.dbo.sysjobhistory h 
                                ON s.job_id = h.job_id 
                                AND s.step_id = h.step_id 
                                AND h.step_id <> 0
                                where j.enabled = 1   --Only Enabled Jobs
                                and  ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) > 10 -- Jobs running longer than 10 minutes

                                and msdb.dbo.agent_datetime(run_date, run_time) 
                                BETWEEN @Date1 and @Date2 "
                               FROM MSDB.dbo.SYSJOBS JOIN MASTER.dbo.SYSPROCESSES
                               ON SUBSTRING(SYSPROCESSES.PROGRAM_NAME,30,34) = MASTER.dbo.fn_varbintohexstr ( SYSJOBS.job_id) "

    $checklistparams.Credential = $FS_Credential
}
        }

        #$ConnectionString 
        $cn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)

        $fsresult = Format-FSTypes -InputObject $queryresult.Tables -Type 'ForeScript.Types.SQLServerData' -Header $header
        $result += $fsresult

 $fsresult = Format-FSTypes -InputObject $queryresult.Tables -Type 'ForeScript.Types.SQLServerChecklist' -Header $header
 $fsresult#>
else {
  
  "Could not connect to computer $Computer...`r`n" 


}