# Check Traceability Completeness
# PowerShell script to verify bidirectional traceability
# Usage: .\check-traceability.ps1 -Feature "001-feature-name"

param(
    [Parameter(Mandatory=$true)]
    [string]$Feature,
    
    [switch]$Verbose,
    [switch]$Report
)

function Check-Traceability {
    param(
        [string]$FeatureDir
    )
    
    $results = @{
        "ForwardTraceability" = @()
        "BackwardTraceability" = @()
        "CoverageGaps" = @()
        "OrphanCode" = @()
        "OrphanTests" = @()
        "Metrics" = @{}
    }
    
    Write-Host "Checking traceability for: $FeatureDir" -ForegroundColor Cyan
    Write-Host ""
    
    # Forward traceability check (Requirements exist for all code/tests)
    Write-Host "Checking Forward Traceability (Requirements → Implementation)..." -ForegroundColor Yellow
    
    $requirementsFile = "$FeatureDir/requirements.md"
    if (Test-Path $requirementsFile) {
        $reqContent = Get-Content $requirementsFile -Raw
        
        # Extract requirement IDs
        $reqIDs = [regex]::Matches($reqContent, '(SG|FSR|SYS-REQ|TSR-HW|TSR-SW)-\d+-\d+') | 
            ForEach-Object { $_.Value } | Select-Object -Unique
        
        Write-Host "  Found $($reqIDs.Count) unique requirements"
        
        # Check if each requirement has design/code/test
        foreach ($reqID in $reqIDs) {
            $designed = $false
            $implemented = $false
            $tested = $false
            
            # Look in design files
            $designFiles = Get-ChildItem "$FeatureDir" -Filter "*design*.md" -ErrorAction SilentlyContinue
            foreach ($file in $designFiles) {
                if ((Get-Content $file -Raw) -match $reqID) {
                    $designed = $true
                }
            }
            
            # Look in code files
            $codeFiles = Get-ChildItem "$FeatureDir" -Filter "*.c", "*.v", "*.sv" -ErrorAction SilentlyContinue
            foreach ($file in $codeFiles) {
                $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
                if ($content -match "@requirement.*$reqID") {
                    $implemented = $true
                }
            }
            
            # Look in test files
            $testFiles = Get-ChildItem "$FeatureDir" -Filter "*test*.md" -ErrorAction SilentlyContinue
            foreach ($file in $testFiles) {
                if ((Get-Content $file -Raw) -match $reqID) {
                    $tested = $true
                }
            }
            
            if (!$designed -or !$implemented -or !$tested) {
                $results["CoverageGaps"] += @{
                    "Requirement" = $reqID
                    "Designed" = $designed
                    "Implemented" = $implemented
                    "Tested" = $tested
                }
                Write-Host "  ⚠️  $reqID - Missing: $(if(!$designed) { 'Design ' })$(if(!$implemented) { 'Code ' })$(if(!$tested) { 'Test' })" -ForegroundColor Yellow
            } else {
                Write-Host "  ✓ $reqID - Complete"
                $results["ForwardTraceability"] += $reqID
            }
        }
    }
    
    Write-Host ""
    
    # Backward traceability check (All code/tests are traced to requirements)
    Write-Host "Checking Backward Traceability (Implementation → Requirements)..." -ForegroundColor Yellow
    
    $codeFiles = Get-ChildItem "$FeatureDir" -Filter "*.c", "*.v", "*.sv" -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $codeFiles) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        
        # Check for traceability tags
        if ($content -notmatch "@requirement") {
            $results["OrphanCode"] += $file.FullName
            Write-Host "  ⚠️  No traceability in: $($file.Name)" -ForegroundColor Yellow
        }
    }
    
    $testFiles = Get-ChildItem "$FeatureDir" -Filter "*test*.md" -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $testFiles) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        
        # Check if test references requirements
        if ($content -notmatch "(SG|FSR|SYS-REQ|TSR-HW|TSR-SW)-\d+-\d+") {
            $results["OrphanTests"] += $file.FullName
            Write-Host "  ⚠️  Test not traced to requirement: $($file.Name)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    # Calculate metrics
    $totalReqs = if ($reqIDs) { $reqIDs.Count } else { 0 }
    $completereqs = $results["ForwardTraceability"].Count
    $completeCoverage = if ($totalReqs -gt 0) { ($completereqs / $totalReqs * 100) } else { 0 }
    $orphanCodeCount = $results["OrphanCode"].Count
    $orphanTestCount = $results["OrphanTests"].Count
    
    $results["Metrics"] = @{
        "TotalRequirements" = $totalReqs
        "FullyTraced" = $completereqs
        "CoveragePercentage" = [math]::Round($completeCoverage, 1)
        "OrphanCodeFiles" = $orphanCodeCount
        "OrphanTestFiles" = $orphanTestCount
    }
    
    return $results
}

function Show-TraceabilityReport {
    param(
        [hashtable]$Results
    )
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "TRACEABILITY ANALYSIS REPORT" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "METRICS:" -ForegroundColor Cyan
    Write-Host "  Total Requirements:      $($Results.Metrics.TotalRequirements)"
    Write-Host "  Fully Traced:            $($Results.Metrics.FullyTraced)"
    Write-Host "  Coverage:                $($Results.Metrics.CoveragePercentage)%"
    Write-Host "  Orphan Code Files:       $($Results.Metrics.OrphanCodeFiles)"
    Write-Host "  Orphan Test Files:       $($Results.Metrics.OrphanTestFiles)"
    Write-Host ""
    
    if ($Results.CoverageGaps.Count -gt 0) {
        Write-Host "COVERAGE GAPS:" -ForegroundColor Yellow
        foreach ($gap in $Results.CoverageGaps) {
            Write-Host "  $($gap.Requirement):"
            Write-Host "    - Design:       $(if($gap.Designed) { '✓' } else { '✗' })"
            Write-Host "    - Implementation: $(if($gap.Implemented) { '✓' } else { '✗' })"
            Write-Host "    - Tests:        $(if($gap.Tested) { '✓' } else { '✗' })"
        }
        Write-Host ""
    }
    
    if ($Results.OrphanCode.Count -gt 0) {
        Write-Host "ORPHAN CODE (Not traced to requirements):" -ForegroundColor Red
        foreach ($orphan in $Results.OrphanCode) {
            Write-Host "  - $orphan"
        }
        Write-Host ""
    }
    
    if ($Results.OrphanTests.Count -gt 0) {
        Write-Host "ORPHAN TESTS (Not traced to requirements):" -ForegroundColor Red
        foreach ($orphan in $Results.OrphanTests) {
            Write-Host "  - $orphan"
        }
        Write-Host ""
    }
    
    # Overall assessment
    $coverage = $Results.Metrics.CoveragePercentage
    if ($coverage -eq 100 -and $Results.Metrics.OrphanCodeFiles -eq 0 -and $Results.Metrics.OrphanTestFiles -eq 0) {
        Write-Host "STATUS: ✓ TRACEABILITY COMPLETE" -ForegroundColor Green
    } elseif ($coverage -ge 95) {
        Write-Host "STATUS: ⚠️  TRACEABILITY ACCEPTABLE (>95%)" -ForegroundColor Yellow
    } else {
        Write-Host "STATUS: ✗ TRACEABILITY GAPS FOUND" -ForegroundColor Red
    }
    Write-Host ""
}

# Main execution
$featureDir = "specs/$Feature"

if (!(Test-Path $featureDir)) {
    Write-Host "Error: Feature directory not found: $featureDir" -ForegroundColor Red
    exit 1
}

$results = Check-Traceability -FeatureDir $featureDir

if ($Report) {
    Show-TraceabilityReport -Results $results
    
    # Optional: Export to file
    $reportFile = "$featureDir/traceability-report.json"
    $results | ConvertTo-Json | Set-Content $reportFile
    Write-Host "Report saved to: $reportFile" -ForegroundColor Green
} else {
    Show-TraceabilityReport -Results $results
}
