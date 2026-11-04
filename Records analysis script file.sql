create Database healthcare_database;

use healthcare_database;

create table Records (
	Name varchar(50),
    Age int,
    Gender varchar(10),
    Blood varchar(6),
    Medical_Condition varchar(20),
    Date_of_Admission date,
    Doctor varchar(100),
    Hospital varchar(250),
    Insurance varchar(150),
    Billing_Amount Decimal(10,2),
    Room_Number int,
    Admission_Type varchar(50),
    Discharge_Date date,
    Medication varchar(25),
    Test_Results varchar(20)
    );


select * from records;

-- Check the first 10 records
select *
From records
LIMIT 10;

-- renaming the column name
Alter table Records
Rename Column Name to Patient_name;

-- Total records and Admissions
select count(*) AS total_records
From records;

-- Average Patient Age
select 
    round(Avg(age), 2)
        as average_age
From records;

-- Age Group Distribution
select 
    Case
        When age < 18 Then 'Under 18'
        When age Between 18 And 29 Then '18-29'
        When age Between 30 And 44 Then '30-44'
        When age Between 45 And 59 Then '45-59'
        When age Between 60 And 74 Then '60-74'
        ELSE '75+'
    End as age_group,
    count(*) as record_count
From records
Where age Between 0 And 120
group by
    Case
        When age < 18 Then 'Under 18'
        When age Between 18 And 29 Then '18-29'
        When age Between 30 And 44 Then '30-44'
        When age Between 45 And 59 Then '45-59'
        When age Between 60 And 74 Then '60-74'
        Else '75+'
    End
    order by min(age);

-- Medical Condition MIx
select
    medical_condition,
    count(*) as record_count,
    round(
        100.0 * COUNT(*) /
        nullif((select count(*) from records), 0),
        2
    ) as record_percentage,
    round(sum(billing_amount), 2)
        as total_billing,
    round(Avg(billing_amount), 2)
        as average_billing
From records
group by medical_condition
order by record_count desc;

-- Admission Type
select
    admission_type,
    count(*) as record_count,
    round(
        100.0 * COUNT(*) /
        NULLIF((select count(*) From records), 0),
        2
    ) as admission_percentage,
    round(Avg(billing_amount), 2)
        as average_billing,
    round(Avg(
        Case
            When discharge_date >= date_of_admission
            Then discharge_date - date_of_admission
        END
    ), 2) as average_stay_days
From records
group by admission_type
order by record_count DESC;

-- Monthly admission trends
select
    Year(date_of_admission) as admission_year,
    Month(date_of_admission) as admission_month,
    count(*) AS admission_records,
    round(sum(billing_amount), 2) as total_billing,
    round(Avg(billing_amount), 2) as average_billing
From records
Where date_of_admission Is not Null 
group by
    Year(date_of_admission),
    Month(date_of_admission)
order by
    admission_year,
    admission_month asc;
    
-- Total Billing Amount
select
    count(*) as total_records,
    round(sum(Billing_Amount), 2) as total_billing_amount
From records;

-- Average Billing Per record
Select        
    round(Avg(Billing_Amount), 2)
        as average_billing_per_record
from records;

-- Insurance provider analysis
select
    insurance,
    count(*) as record_count,
    round(sum(billing_amount), 2)
        as total_billing,
    round(Avg(billing_amount), 2)
        as average_billing,
    round(
        100.0 * sum(billing_amount) /
        NULLIF(
            (select sum(billing_amount)
             From records), 0
        ),
        2
    ) as share_of_total_billing_pct
From records
group by insurance
order by total_billing Desc;

-- Check date inconsistencies
select *
From records
WHERE discharge_date < date_of_admission;

-- Average Length Stay Days
select
    round(Avg(age), 2)
        as average_age,
    round(Avg(
        Case
            When discharge_date >= date_of_admission
            Then discharge_date - date_of_admission
        end
    ), 2) as average_length_of_stay_days
from records;

-- Hospital performance comparison
select
    hospital,
    count(*) as total_records,
    round(sum(billing_amount), 2)
        as total_billing,
    round(Avg(billing_amount), 2)
        as average_billing,
    round(Avg(
        Case
            When discharge_date >= date_of_admission
            Then discharge_date - date_of_admission
        End
    ), 2) as average_stay_days
From records
group by hospital
Order by total_records Desc
Limit 10;

-- Doctor-wise analysis
select
    doctor,
    count(*) as record_count,
    round(Avg(billing_amount), 2)
        as average_billing,
    round(Avg(
        Case
            When discharge_date >= date_of_admission
            Then discharge_date - date_of_admission
        end
    ), 2) as average_stay_days
From records
group by doctor
order by record_count Desc
limit 10;

-- Test-result distribution
select
    test_results,
    count(*) as record_count,
    round(
        100.0 * count(*) /
        Nullif((Select count(*) From records), 0),
        2
    ) as result_percentage
From records
group by test_results
order by record_count Desc;

-- Medication distribution
select
    medication,
    count(*) as record_count,
    round(Avg(billing_amount), 2)
        as average_billing,
    round(sum(billing_amount), 2)
        as total_billing
From records
group by medication
order by record_count desc;

-- Check missing values in key columns
select
    sum(Case When Patient_name Is Null Then 1 ELSE 0 END)
        AS missing_names,

    sum(Case When date_of_admission Is Null  Then 1 ELSE 0 END)
        AS missing_admission_dates,

    sum(Case When discharge_date Is Null  Then 1 ELSE 0 END)
        AS missing_discharge_dates,

    sum(Case When billing_amount Is Null Then 1 ELSE 0 END)
        AS missing_billing_amounts
From records;

 -- Highest Hospital Billing Rank (Self Join)
SELECT
    hospital,
    SUM(billing_amount) AS total_billing,
    DENSE_RANK() OVER (
        ORDER BY SUM(billing_amount) DESC
    ) AS billing_rank
FROM records
GROUP BY hospital
limit 20;

-- Hospital Billing (Sub-Queries)
SELECT
    hospital,
    SUM(billing_amount) AS total_billing
FROM records
GROUP BY hospital
HAVING SUM(billing_amount) > (
    SELECT AVG(hospital_billing)
    FROM (
        SELECT
            hospital,
            SUM(billing_amount) AS hospital_billing
        FROM records
        GROUP BY hospital
    ) AS hospital_totals
)
ORDER BY total_billing DESC
limit 25;

-- Highest Billing Record within each Hospital
WITH ranked_records AS (
    SELECT
        hospital,
        patient_name,
        medical_condition,
        billing_amount,
        ROW_NUMBER() OVER (
            PARTITION BY hospital
            ORDER BY billing_amount DESC 
        ) AS row_num
    FROM records
)
SELECT
    hospital,
    patient_name,
    medical_condition,
    billing_amount
FROM ranked_records
WHERE row_num = 1;



drop table records;

truncate table records;

drop database healthcare_database;