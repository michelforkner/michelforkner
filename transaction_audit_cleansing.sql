-- ==================================================================================
-- PROJECT: Transaction Integrity & Data Cleansing Protocol (LSEG Master Dataset)
-- OBJECTIVE: Extract, validate, and audit granular institutional transaction records
--            across 49 firms to isolate and remediate anomalies for reporting.
-- AUTHOR: Michel Ilah Dein Forkner
-- ==================================================================================

WITH validated_transactions AS (    
    SELECT 
        t.deal_id,
        t.company_id,
        COALESCE(t.investor_firm_id, 'UNKNOWN_INSTITUTION') AS investor_firm_id,
        
        -- Clean and standardize round classification naming conventions
        CASE 
            WHEN LOWER(t.funding_round_type) LIKE '%seed%' THEN 'Early-Stage Venture'
            WHEN LOWER(t.funding_round_type) LIKE '%series a%' THEN 'Mid-Stage Venture'
            WHEN LOWER(t.funding_round_type) LIKE '%series b%' THEN 'Mid-Stage Venture'
            WHEN LOWER(t.funding_round_type) LIKE '%series c%' THEN 'Late-Stage Venture'
            WHEN LOWER(t.funding_round_type) LIKE '%growth%' THEN 'Growth Equity'
            WHEN LOWER(t.funding_round_type) LIKE '%buyout%' THEN 'Buyout / Control'
            ELSE 'Other Institutional'
        END AS asset_classification,

        -- Standardize currency formats and enforce strict data type rules
        CAST(t.equity_amount_usd AS DECIMAL(18,2)) AS raw_equity_usd,
        t.transaction_date,
        
        -- Data Integrity Flag: Identify records missing critical transaction fields
        CASE 
            WHEN t.equity_amount_usd IS NULL OR t.equity_amount_usd <= 0 THEN 'FLAG: Missing Financial Data'
            WHEN t.investor_firm_id IS NULL THEN 'FLAG: Anonymous Investor'
            ELSE 'Verified'
        END AS compliance_status

    FROM 
        raw_deals_ingestion AS t
    WHERE 
        t.transaction_date BETWEEN '2014-01-01' AND '2023-12-31'
)

-- Final extraction layer isolating the master audit dataset
SELECT 
    vt.deal_id,
    vt.investor_firm_id,
    vt.asset_classification,
    vt.raw_equity_usd AS deal_value_usd,
    vt.transaction_date,
    vt.compliance_status
FROM 
    validated_transactions AS vt
WHERE 
    -- Filter out broken or unverified transactions to maintain strict reporting standards
    vt.compliance_status = 'Verified'
    AND vt.asset_classification IN ('Early-Stage Venture', 'Mid-Stage Venture', 'Late-Stage Venture', 'Growth Equity', 'Buyout / Control')
ORDER BY 
    vt.transaction_date DESC;