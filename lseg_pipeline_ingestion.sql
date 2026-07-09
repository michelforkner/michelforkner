-- ==================================================================================
-- PROJECT: Multi-Tier Institutional Data Ingestion & Integrity Validation Script
-- OBJECTIVE: Join and validate records across Firms, Funds, and Transactions/Rounds
--            to audit data integrity, tranche values, and regulatory alignment.
-- AUTHOR: Michel Ilah Dein Forkner
-- ==================================================================================

SELECT 
    -- 1. Firm Metadata Tracking
    f.firm_id,
    f.firm_name,
    f.firm_type_classification AS firm_archetype, -- e.g., Buyout, VC, Generalist PE
    
    -- 2. Fund Pool Tracking
    fund.fund_id,
    fund.fund_name,
    fund.fundraise_status_stage, -- e.g., Closed, Rumored, Active
    fund.fund_vintage_year,
    
    -- 3. Granular Transaction / Round Field Level Mapping
    r.deal_id,
    r.tranche_number,
    r.deal_status_execution, -- e.g., Completed, Pending
    r.security_type_structure, -- e.g., Quasi-Equity, Common Stock, Preferred
    
    -- 4. Financial Allocation Splits (Stored in Thousands USD)
    ROUND(r.equity_amount_thousands * 1000.0, 2) AS equity_deployed_usd,
    ROUND(r.debt_amount_thousands * 1000.0, 2) AS debt_leveraged_usd,
    ROUND(r.total_transaction_value_thousands * 1000.0, 2) AS total_deal_value_usd,
    
    -- 5. Governance and Verification Lineage
    r.deal_source_attribution,
    r.legal_advisor_counsel

FROM 
    pe_firms_master AS f
INNER JOIN 
    pe_funds_registry AS fund ON f.firm_id = fund.managing_firm_id
INNER JOIN 
    transaction_rounds_ledger AS r ON fund.fund_id = r.source_fund_id

WHERE 
    -- Filter out edge-case errors to protect baseline accuracy
    r.total_transaction_value_thousands IS NOT NULL 
    AND r.total_transaction_value_thousands > 0
    
    -- Audit specific focus categories outlined in data framework docs
    AND f.firm_type_classification IN ('Buyout', 'Venture Capital', 'Generalist PE', 'Fund of Funds')

ORDER BY 
    total_deal_value_usd DESC;
