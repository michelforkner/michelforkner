-- ==================================================================================
-- PROJECT: 10-Year Regional Private Equity & Venture Capital Investment Analysis
-- OBJECTIVE: Extract, aggregate, and clean a decade of deal flow data (2014-2023)
--            to evaluate capital velocity, geographic concentration, and sector dominance.
-- PROJECT BY: Michel Ilah Dein Forkner
-- ==================================================================================

SELECT 
    -- 1. Standardize and group geographic metadata
    UPPER(c.country_name) AS target_nation,
    
    -- 2. Categorize core macro industries
    i.industry_group AS macro_sector,
    
    -- 3. Extract the calendar year of the deal execution
    EXTRACT(YEAR FROM t.transaction_date) AS deal_year,
    
    -- 4. Calculate total volume of distinct institutional transactions
    COUNT(DISTINCT t.deal_id) AS total_deal_count,
    
    -- 5. Calculate total equity deployed in millions (USD)
    ROUND(SUM(t.equity_amount_usd) / 1000000.0, 2) AS total_equity_deployed_millions,
    
    -- 6. Calculate average deal size to understand investment ticket sizes
    ROUND(AVG(t.equity_amount_usd) / 1000000.0, 2) AS avg_deal_size_millions

FROM 
    institutional_deals_master AS t
INNER JOIN 
    portfolio_companies AS c ON t.company_id = c.company_id
INNER JOIN 
    industry_classifications AS i ON c.industry_id = i.industry_id

WHERE 
    -- Filter for the exact historical 10-year baseline horizon
    t.transaction_date BETWEEN '2014-01-01' AND '2023-12-31'
    -- Ensure data integrity by filtering out broken or cancelled deals
    AND t.deal_status IN ('Completed', 'Closed', 'Updated')
    -- Focus purely on institutional Private Equity and Venture Capital asset classes
    AND t.funding_round_type IN ('Seed', 'Series A', 'Series B', 'Series C', 'Growth Equity', 'Buyout')

GROUP BY 
    UPPER(c.country_name),
    i.industry_group,
    EXTRACT(YEAR FROM t.transaction_date)

ORDER BY 
    deal_year DESC, 
    total_equity_deployed_millions DESC;
