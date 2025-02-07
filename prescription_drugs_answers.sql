SELECT COUNT (drug_name)
FROM drug;

SELECT COUNT (DISTINCT drug_name)
FROM drug;

SELECT 
	DISTINCT npi,
	SUM(total_claim_count) AS total_claim_sum
FROM prescriber
	INNER JOIN prescription USING (npi)
GROUP BY npi
ORDER BY total_claim_sum DESC;

-- 1a) Provider 1881634483 had the highest total of claims with 99,707 claims

SELECT 
	nppes_provider_last_org_name,
	nppes_provider_first_name,
	specialty_description,
	SUM(total_claim_count) AS claims_sum
FROM prescriber
	INNER JOIN prescription USING (npi)
GROUP BY nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
ORDER BY claims_sum DESC;

-- 1b) Bruce Pendley, the FP was the doctor with 99,707 total claims

SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- 2a) Family Practice had the most total claims at 9,752,347

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_opioid_claims
FROM prescriber
	INNER JOIN prescription USING (npi)
	INNER JOIN drug ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_opioid_claims DESC;

-- 2b) Nurse Practitioners had the highest total opioid claims at 900,845

SELECT 
	DISTINCT pscr.specialty_description
FROM prescriber AS pscr
	LEFT JOIN prescription As psc USING (npi)
WHERE psc.npi IS NULL;

-- 2c) There are 92 specialties that are not associated with no prescriptions given



SELECT 
	generic_name,
	total_drug_cost
FROM drug
	INNER JOIN prescription AS psc USING (drug_name)
ORDER BY total_drug_cost DESC;

-- 3a) Pirfenidone cost the most out of all the generic drugs at 2,829,174.30

SELECT
	generic_name,
	ROUND((SUM(total_drug_cost)/SUM(total_day_supply)), 2) AS cost_per_day
FROM drug
	INNER JOIN prescription AS psc USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

-- 3b) C1 Esterase Inhibitor cost the most per day at 3495.22

SELECT
	drug_name,
	CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	WHEN opioid_drug_flag = 'N' AND antibiotic_drug_flag  = 'N' THEN 'neither' END AS drug_type
FROM drug
ORDER BY drug_type;

SELECT
	CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	END AS drug_type,
	SUM(total_drug_cost::MONEY) AS total_cost
FROM drug
	INNER JOIN prescription AS psc USING (drug_name)
WHERE opioid_drug_flag = 'Y' OR antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_cost DESC;

-- 4b) They spent more on opioids ($105m vs $38m)

SELECT 
	COUNT (cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN';

-- 5a) 33 CBSAs are in TN

SELECT 
	cbsaname,
	MAX(population) AS pop_max
FROM cbsa
INNER JOIN population USING (fipscounty)
GROUP BY cbsaname
ORDER BY pop_max DESC;

-- 5b) Memphis, TN-MS-AR has the highest population at 937,847 while Morristown has the smallest at 63,465

SELECT *
FROM cbsa
FULL JOIN population USING (fipscounty)
FULL JOIN fips_county USING (fipscounty)
WHERE cbsa IS NULL AND population IS NOT NULL
ORDER BY population DESC;

-- 5c) Sevier county is the largest county with 95,523 without a cbsa

SELECT 
	drug_name,
	nppes_provider_first_name,
	nppes_provider_last_org_name
	total_claim_count,
	opioid_drug_flag
FROM prescription
INNER JOIN drug USING (drug_name)
INNER JOIN prescriber ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000 AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC;

-- 6) David Coffey prescribed Oxycodone HCL and Hyrdocodone-Acetaminohen at least 3000 times.

SELECT
	prescriber.npi,
	drug.drug_name,
	COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	ON prescription.npi = prescriber.npi
	AND drug.drug_name = prescription.drug_name
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name, total_claims
ORDER BY total_claims DESC;

-- 7) Answer above

-- BONUS --

SELECT COUNT(npi)
FROM prescriber
EXCEPT
SELECT COUNT(npi)
FROM prescription;

-- 1) 25050 npi in the prescriber table and not in the prescription table

SELECT 
	generic_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription ON prescriber.npi = prescription.npi
INNER JOIN drug ON prescription.drug_name = drug.drug_name
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 2a) Top 5 Family Practice Drugs are "LEVOTHYROXINE SODIUM", "LISINOPRIL", "ATORVASTATIN CALCIUM", "AMLODIPINE BESYLATE", "OMEPRAZOLE"

SELECT 
	generic_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription ON prescriber.npi = prescription.npi
INNER JOIN drug ON prescription.drug_name = drug.drug_name
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 2b) Top 5 Cardiology drugs are Atorvastatin Calcium, Carvedilol, Metoprolol Tartrate, Clopidogrel Bisulfate, Amlodipine Besylate

SELECT 
	generic_name,
	SUM(total_claim_count) as total_claims
FROM prescriber
INNER JOIN prescription ON prescriber.npi = prescription.npi
INNER JOIN drug ON prescription.drug_name = drug.drug_name
WHERE specialty_description IN('Family Practice', 'Cardiology')
GROUP BY generic_name
ORDER BY total_claims DESC;

-- 2c) Top 5 combined are "ATORVASTATIN CALCIUM", "LEVOTHYROXINE SODIUM", "AMLODIPINE BESYLATE", "LISINOPRIL", "FUROSEMIDE"

SELECT 
	prescriber.npi,
	COALESCE(SUM(total_claim_count), 0) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- 3a) Top 5 Providers in Nashville are 1538103692, 1497893556, 1659331924, 1881638971, and 1962499582

SELECT 
	prescriber.npi,
	COALESCE(SUM(total_claim_count), 0) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- 3b) Top 5 providers for Memphis are 1346291432, 1225056872, 1801896881, 1669470316, and 1275601346

SELECT 
	prescriber.npi,
	COALESCE(SUM(total_claim_count), 0) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

SELECT 
	prescriber.npi,
	COALESCE(SUM(total_claim_count), 0) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- 3c) Knoxville = 1295762276 1528094000 1508868969 1194793679 1588638019
--     Chattanooga = 1568494474 1548234826 1013994615 1437191749 1891734711

SELECT 
	prescriber.npi,
	COALESCE(SUM(total_claim_count), 0) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city IN ('CHATTANOOGA', 'MEMPHIS', 'NASHVILLE', 'KNOXVILLE')
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 20;

-- Combining all 4 cities together

SELECT 
	DISTINCT county,
	SUM(overdose_deaths) AS od_total
FROM overdose_deaths
INNER JOIN fips_county ON overdose_deaths.fipscounty = fips_county.fipscounty::NUMERIC
WHERE overdose_deaths > (SELECT 
							ROUND(AVG(overdose_deaths), 2)
							FROM overdose_deaths)
GROUP BY county
ORDER BY od_total DESC;

-- 4) Davidson: 689
--    Knox: 683
--    Shelby: 567
--    Rutherford: 205
--    Hamilton: 191
--    Sullivan: 131
--    Montgomery: 101
--    Sumner: 100
--    Blount: 99
--    Wilson: 98
--    Sevier: 97
--    Anderson: 96
--    Williamson: 94
--    Roane: 77
--    Cheatham: 73
--    Washington: 71
--    Greene: 48
--    Dickson, Hawkins, Maury: 33
--    Bradley: 31
--    Carter: 30
--    Hamblen: 19
--    Loudon: 18
--    Campbell, Tipton: 16
--    Robertson: 15
--    Coffee: 13


SELECT 
	state,
	SUM(population)
FROM population
INNER JOIN fips_county USING (fipscounty)
GROUP BY state;


SELECT 
	county,
	ROUND(SUM(population)*100/(SELECT 
							SUM(population)
							FROM population
							INNER JOIN fips_county USING (fipscounty)), 2) AS avg_of_county_pop
FROM population
INNER JOIN fips_county USING (fipscounty)
GROUP BY county
ORDER BY avg_of_county_pop DESC;


-- 5a) total TN population is 6,597,381
-- 5b) Answer above

-- GROUPING SETS --

SELECT 
	SUM(total_claim_count) AS total_claims,
	specialty_description
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY specialty_description;

-- 1) IPM: 55906
--    PM: 70853

SELECT
	npi,
	specialty_description
FROM prescriber
UNION
SELECT
	total_claim_count,
	drug_name
FROM prescription;

-- 2) WIP

WITH combined_claims AS (SELECT 
							SUM(total_claim_count) AS sum_of_claims
							FROM prescription
							INNER JOIN prescriber USING (npi)
							WHERE specialty_description = 'Interventional Pain Management'
								OR specialty_description = 'Pain Management')

SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims,
	sum_of_claims
FROM prescriber
INNER JOIN prescription USING (npi)
CROSS JOIN combined_claims
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY GROUPING SETS ((specialty_description), (sum_of_claims));

-- 3) answer above

