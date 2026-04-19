-- Experienced Active Staff by Teams in States starting with ‘A’. 
-- Purpose: To identify and analyze highly experienced, currently employed staff members associated with teams located in states starting with the letter 'A.' If no records match the criteria defined in the query, the query will return an empty result set.
-- Summary: This query retrieves detailed information about teams in states starting with 'A' and their highly experienced, currently employed staff. It includes team and staff details, filtered by relevance, to support workforce and team analysis.
-- Managerial Implications: 
--Evaluate workforce experience levels and specialization by team.
--Highlight best-performing or resource-heavy teams for focused investment or management attention.
--Ensure compliance with diversity and employment policies by assessing demographic data of experienced staff.
SELECT 
    t.TeamID,
    t.TeamName,
    t.city,
    t.state,
    t.division,
    t.conference,
    t.FoundingYear,
    ts.full_name AS StaffName,
    ts.gender,
    ts.race,
    ts.role_title AS RoleTitle,
    ts.specialization AS Specialization,
    ts.years_of_experience AS Experience,
    ts.employment_status AS EmploymentStatus,
    st.staff_role_name AS StaffRole,
    st.department,
    st.level
FROM 
    TeamTable t
JOIN 
    TeamStaffTable4 ts
    ON t.TeamID = ts.team_id
JOIN 
    StaffType st
    ON ts.staff_type_id = st.staff_type_id
WHERE 
    t.state LIKE 'A%' -- Filter states starting with 'A'
    AND ts.employment_status = 'Employed' -- Filter employed staff
    AND ts.years_of_experience > 10 -- Filter staff with more than 10 years of experience
ORDER BY 
    t.TeamName, ts.years_of_experience DESC;

-- Fetch Asian Staff with Experience by Team
-- Purpose: To retrieve detailed information about Asian staff members associated with a specified team, ensuring they meet a minimum of 2 years of experience. The procedure validates the team name before executing the query
-- ​​Summary: The GetAsianStaffByTeam procedure retrieves details of Asian staff with at least 2 years of experience for a specified team. It validates the team name and returns key staff and role information if valid, or raises an error if invalid.
-- Managerial Implications: 
-- Evaluate the representation of Asian staff in a specific team.
-- Identify experienced Asian employees for role-specific planning, promotions, or projects.
-- Provide demographic and role-specific data that can guide team-building strategies or ensure diversity benchmarks.
-- Validation Check: Built-in team name validation ensures accuracy, reducing errors and misreports.

SELECT 
    t.TeamID,
    t.TeamName,
    t.city,
    t.state,
    t.division,
    t.conference,
    t.FoundingYear,
    ts.full_name AS StaffName,
    ts.gender,
    ts.race,
    ts.role_title AS RoleTitle,
    ts.specialization AS Specialization,
    ts.years_of_experience AS Experience,
    ts.employment_status AS EmploymentStatus,
    st.staff_role_name AS StaffRole,
    st.department,
    st.level
FROM 
    TeamTable t
JOIN 
    TeamStaffTable4 ts
    ON t.TeamID = ts.team_id
JOIN 
    StaffType st
    ON ts.staff_type_id = st.staff_type_id
WHERE 
    t.state LIKE 'A%' -- Filter states starting with 'A'
    AND ts.employment_status = 'Employed' -- Filter employed staff
    AND ts.years_of_experience > 10 -- Filter staff with more than 10 years of experience
ORDER BY 
    t.TeamName, ts.years_of_experience DESC;

    /* Query to analyze average diversity metrics by department and year */

/*
Purpose:
Calculate average player, staff, and gender diversity percentages for departments by year, focusing on those with staff diversity > 50%.

Summary:
- Outputs diversity metrics grouped by year and department.
- Sorted by the latest year and highest staff diversity.

Managerial Implications:
- Highlight top-performing departments for diversity recognition.
- Use results to guide and improve diversity initiatives.
*/

WITH AvgDiversity AS (
    SELECT
        hr.year,
        st.department,
        AVG(hr.player_diversity_percentage) AS avg_player_diversity,
        AVG(hr.staff_diversity_percentage) AS avg_staff_diversity,
        AVG(hr.gender_diversity_percentage) AS avg_gender_diversity
    FROM
        HistoricalRepresentation hr
    INNER JOIN
        TeamInitative ti ON hr.team_id = ti.team_id
    INNER JOIN
        StaffType st ON ti.initiative_id = st.staff_type_id
    GROUP BY
        hr.year, st.department
    HAVING AVG(hr.staff_diversity_percentage) > 50
)
SELECT *
FROM AvgDiversity
ORDER BY year DESC, avg_staff_diversity DESC;

/* Stored Procedure: GetOngoingInitiatives */

/*
Purpose:
Retrieve ongoing initiatives (status = 'In Progress') with a budget greater than a specified minimum value.

Summary:
- Validates the input parameter to ensure the minimum budget is greater than zero.
- Returns a list of initiatives that meet the criteria, sorted by budget in descending order.

Managerial Implications:
- Helps prioritize initiatives with significant budgets for monitoring and resource allocation.
- Enables identification of high-value ongoing initiatives for strategic focus.
*/

ALTER PROCEDURE GetOngoingInitiatives (@min_budget DECIMAL(10, 2))
AS
BEGIN
    -- Check for invalid input
    IF @min_budget <= 0
    BEGIN
        RAISERROR ('Budget must be greater than zero', 16, 1); -- Raise an error for invalid input
    END
    ELSE
    BEGIN
        -- Fetch ongoing initiatives with budgets exceeding the minimum value
        SELECT
            initiative_id,
            initative_name,
            start_date,
            end_date,
            budget
        FROM
            Initiative
        WHERE
            status = 'In Progress' -- Filter for initiatives that are ongoing
            AND budget > @min_budget -- Filter for initiatives with significant budgets
        ORDER BY
            budget DESC; -- Sort by budget in descending order
    END
END;

-- Execute the procedure with a minimum budget filter
EXEC GetOngoingInitiatives @min_budget = 100000.00;

-- Drop procedure if it exists
DROP PROCEDURE IF EXISTS GetTeamsByDivisionAndConference;


GO
-- Stored Procedure: GetTeamsByDivisionAndConference
-- Purpose: Retrieve team details based on division and conference. If no matching records are found, display all teams.
-- Summary: 
-- - Validates input parameters.
-- - Queries for teams based on the given division and conference.
-- - Displays all teams if no matching records are found.
-- Managerial Implications: 
-- - Helps managers quickly access team data for a specific division and conference, ensuring no errors due to null inputs.
-- - Provides fallback data to give a broader view of all teams in case of no matches.
CREATE PROCEDURE GetTeamsByDivisionAndConference
    @division VARCHAR(9),
    @conference VARCHAR(3)
AS
BEGIN
    BEGIN TRY
        
        BEGIN TRANSACTION;

        
        IF @division IS NULL OR @conference IS NULL
        BEGIN
            RAISERROR('Division and Conference parameters cannot be NULL.', 16, 1);
            RETURN;
        END;

        
        SELECT TeamID, TeamName, city, state, FoundingYear
        FROM TeamTable
        WHERE division = @division AND conference = @conference
        ORDER BY FoundingYear DESC;

        
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'No matching records found. Displaying all teams:';
            SELECT TeamID, TeamName, city, state, FoundingYear
            FROM TeamTable
            ORDER BY FoundingYear DESC;
        END;

        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        
        PRINT 'An error occurred: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;
END;




GO  

-- Example usage
EXEC GetTeamsByDivisionAndConference 'AFC North', 'NFC';



-- Complex Query: Team Analysis by Division and Conference
-- Purpose:
-- - Aggregate statistics for teams by division and conference.
-- - Rank teams within their division by founding year.
-- Summary:
-- - Calculates the number of teams, average founding year, oldest team, and newest team in each division and conference.
-- - Ranks teams in each division by founding year.
-- Managerial Implications:
-- - Provides insights into division-level trends and historical data.
-- - Enables strategic planning by identifying newer or historically established teams.
WITH DivisionStats AS (
    
    SELECT 
        T.Division,
        T.Conference,
        COUNT(*) AS TeamCount,
        AVG(T.FoundingYear) AS AvgFoundingYear,
        MAX(T.FoundingYear) AS MostRecentTeamYear,
        MIN(T.FoundingYear) AS OldestTeamYear
    FROM TeamTable T
    GROUP BY T.Division, T.Conference
),

RankedTeams AS (
    
    SELECT 
        T.TeamID, 
        T.TeamName, 
        T.Division, 
        T.Conference, 
        T.FoundingYear,
        ROW_NUMBER() OVER (PARTITION BY T.Division ORDER BY T.FoundingYear DESC) AS DivisionRank
    FROM TeamTable T
)


SELECT 
    RT.Division,
    RT.Conference,
    RT.TeamName,
    RT.FoundingYear,
    RT.DivisionRank,
    DS.TeamCount AS TotalTeamsInDivision,
    DS.AvgFoundingYear AS DivisionAvgFoundingYear,
    DS.MostRecentTeamYear AS MostRecentDivisionTeam,
    DS.OldestTeamYear AS OldestDivisionTeam,
    
    (SELECT COUNT(*) 
     FROM TeamTable T2
     WHERE T2.Conference = RT.Conference) AS TotalTeamsInConference
FROM RankedTeams RT
JOIN DivisionStats DS 
    ON RT.Division = DS.Division AND RT.Conference = DS.Conference
ORDER BY RT.Division, RT.DivisionRank;


-- Complex Query: Comparative Team Performance by Division and Conference with Team Age Calculation
-- Purpose:
-- - Analyze team age within divisions and conferences.
-- - Identify the oldest and newest teams in each division.
-- Summary:
-- - Calculates team age based on the current year and ranks them within their division.
-- - Provides average team age for each division and conference.
-- - Identifies the oldest and newest teams in each division.
-- Managerial Implications:
-- - Supports historical and performance analyses.
-- - Enables targeting of divisions with younger teams for potential growth initiatives or older teams for legacy marketing.
WITH TeamAgeStats AS (
    SELECT 
        T.TeamID,
        T.TeamName,
        T.Division,
        T.Conference,
        T.FoundingYear,
        (YEAR(GETDATE()) - T.FoundingYear) AS TeamAge,  -- Team age based on the founding year
        ROW_NUMBER() OVER (PARTITION BY T.Division ORDER BY (YEAR(GETDATE()) - T.FoundingYear) DESC) AS AgeRank
    FROM TeamTable T
),

DivisionAverageAge AS (
    
    SELECT 
        T.Division,
        AVG(YEAR(GETDATE()) - T.FoundingYear) AS AvgTeamAge
    FROM TeamTable T
    GROUP BY T.Division
),

ConferencePerformance AS (
    
    SELECT 
        T.Conference,
        COUNT(*) AS TotalTeamsInConference,
        AVG(YEAR(GETDATE()) - T.FoundingYear) AS AvgTeamAgeInConference
    FROM TeamTable T
    GROUP BY T.Conference
)


SELECT 
    TAS.TeamName,
    TAS.Division,
    TAS.Conference,
    TAS.TeamAge,
    TAS.AgeRank,
    DAA.AvgTeamAge AS DivisionAvgAge,
    CPA.AvgTeamAgeInConference AS ConferenceAvgAge,
    CPA.TotalTeamsInConference,
    
    (SELECT TOP 1 TeamName
     FROM TeamTable T2
     WHERE T2.Division = TAS.Division
     ORDER BY T2.FoundingYear ASC) AS OldestTeamInDivision,
    
    (SELECT TOP 1 TeamName
     FROM TeamTable T2
     WHERE T2.Division = TAS.Division
     ORDER BY T2.FoundingYear DESC) AS NewestTeamInDivision
FROM TeamAgeStats TAS
JOIN DivisionAverageAge DAA
    ON TAS.Division = DAA.Division
JOIN ConferencePerformance CPA
    ON TAS.Conference = CPA.Conference
ORDER BY TAS.Division, TAS.AgeRank;

