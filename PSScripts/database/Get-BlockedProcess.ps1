﻿<# 


function Get-QueryResults {

    Param (
        $SQLConnection,
        $Query
    )

    $ds = New-object "System.Data.DataSet" "BlockedProcessData"
    $da = New-Object "System.Data.SqlClient.SqlDataAdapter" ($Query, $SQLConnection)
    $da.Fill($ds) | Out-Null
    if ($ds.Tables[0].Rows.Count  -gt 0) {
        return $ds
    }
    return $null
    
}
        $SQLInstance,
        $SPID
    )
                         ,r.STATUS 
                         ,r.blocking_session_id 'blocked by'
                         ,r.wait_type
                         ,wait_resource
                         ,r.wait_time / (1000.0) 'Wait Time (in Sec)'
                         ,r.cpu_time
                         ,r.logical_reads
                         ,r.reads
                         ,r.writes
                         ,r.total_elapsed_time / (1000.0) 'Elapsed Time (in Sec)'
                         ,Substring(st.TEXT, (r.statement_start_offset / 2) + 1, (
                         (
                            CASE r.statement_end_offset
                              WHEN - 1
                              THEN Datalength(st.TEXT)
                            ELSE r.statement_end_offset
                            END - r.statement_start_offset
                          ) / 2
                          ) + 1) AS statement_text
                          ,Coalesce(Quotename(Db_name(st.dbid)) + N'.' + Quotename(Object_schema_name(st.objectid, st.dbid)) + N'.' + 
                          Quotename(Object_name(st.objectid, st.dbid)), '') AS command_text
                          ,r.command
                          ,s.login_name
                          ,s.host_name
                          ,s.program_name
                          ,s.host_process_id
                          ,s.last_request_end_time
                          ,s.login_time
                          ,r.open_transaction_count
                          FROM sys.dm_exec_sessions AS s
                          INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
                          CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
                          WHERE r.session_id != @@SPID
                          ORDER BY r.cpu_time DESC
                            ,r.STATUS
                            ,r.blocking_session_id

    $checklistparams.Credential = $FS_Credential
}
        }

        #$ConnectionString 
        $cn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)

        $fsresult = Format-FSTypes -InputObject $queryresult.Tables -Type 'ForeScript.Types.SQLServerData' -Header $header
        $result += $fsresult
else {
  
  "Could not connect to computer $Computer...`r`n" 


}