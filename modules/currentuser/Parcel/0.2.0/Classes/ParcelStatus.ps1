class ParcelStatus
{
    [ParcelStatusType] $Status
    [string] $Reason = [string]::Empty

    ParcelStatus([ParcelStatusType]$_status)
    {
        $this.Status = $_status
    }

    ParcelStatus([ParcelStatusType]$_status, [string]$_reason)
    {
        $this.Status = $_status
        $this.Reason = $_reason
    }

    [void] WriteStatusMessage([bool]$_dryRun)
    {
        if ($_dryRun) {
            Write-Host '[WhatIf]: ' -ForegroundColor Cyan -NoNewline
        }

        switch ($this.Status) {
            'Skipped' {
                Write-Host $this.Status -ForegroundColor Green -NoNewline
            }

            'Changed' {
                Write-Host $this.Status -ForegroundColor Yellow -NoNewline
            }
        }

        if ([string]::IsNullOrWhiteSpace($this.Reason)) {
            Write-Host ([string]::Empty)
        }
        else {
            Write-Host " (reason: $($this.Reason.ToLowerInvariant()))"
        }
    }
}