-- Branch Activity

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q1 cascade;

CREATE TABLE q1 (
    branch CHAR(5),
    year INT,
    events INT NOT NULL,
    sessions FLOAT NOT NULL,
    registration INT NOT NULL,
    holdings INT NOT NULL,
    checkouts INT NOT NULL,
    duration FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS all_events CASCADE;
DROP VIEW IF EXISTS session_count CASCADE;
DROP VIEW IF EXISTS registration_count CASCADE;
DROP VIEW IF EXISTS holding_count CASCADE;
DROP VIEW IF EXISTS all_checkouts CASCADE;
DROP VIEW IF EXISTS duration_average CASCADE;
DROP VIEW IF EXISTS event_count CASCADE;
DROP VIEW IF EXISTS all_information CASCADE;
-- Define views for your intermediate steps here:

-- Find event ID every each branch in each year (year, branch, event_id), it is not distinct
CREATE VIEW all_events AS 
SELECT EXTRACT(YEAR FROM EventSchedule.edate) AS year, LibraryBranch.code AS branch, 
    LibraryEvent.id AS event_id
FROM EventSchedule, LibraryEvent, LibraryRoom, LibraryBranch
WHERE (2014 < EXTRACT(YEAR FROM EventSchedule.edate)
    AND 2020 > EXTRACT(YEAR FROM EventSchedule.edate)
    AND EventSchedule.event = LibraryEvent.id 
    AND LibraryEvent.room = LibraryRoom.id 
    AND LibraryRoom.library = LibraryBranch.code);

-- Find event counts
CREATE VIEW event_count AS
SELECT year, branch, COUNT(DISTINCT event_id) AS events
FROM all_events
GROUP BY year, branch;

-- Find number of sessions for each branch in the previou step (year, branch, session)
CREATE VIEW session_count AS
SELECT year, branch, COUNT(event_id) * 1.0 / COUNT(DISTINCT event_id) AS sessions
FROM all_events 
GROUP BY year, branch;

-- Find number of registrations for each branch in the previous step (year, branch, registration)
CREATE VIEW registration_count AS
SELECT year, branch, COUNT(patron) AS registration
FROM (SELECT DISTINCT year, branch, event_id FROM all_events) AS all_events, EventSignUp
WHERE all_events.event_id = EventSignUp.event
GROUP BY year, branch;

-- Find number of holdings of every branch (same branch has same number of holdings for different years)
-- (year, branch, holdings)
CREATE VIEW holding_count AS
SELECT library AS branch, SUM(num_holdings) AS holdings
FROM LibraryCatalogue
GROUP BY library;

-- Find checksouts for every branch in every year (year, branch, checksout, checkout_id)
CREATE VIEW all_checkouts AS
SELECT library AS branch, EXTRACT(YEAR FROM Checkout.checkout_time) AS year, COUNT(id) AS checkouts
FROM Checkout
GROUP BY library, EXTRACT(YEAR FROM Checkout.checkout_time);

-- Find average duration based on previous step for every branch in every year (year, branch, duration)
CREATE VIEW duration_average AS
SELECT AVG(DATE(Return.return_time) - DATE(Checkout.checkout_time)) AS duration,  
    EXTRACT(YEAR FROM Checkout.checkout_time) AS year, library AS branch
FROM Checkout, Return
WHERE Checkout.id = Return.checkout
GROUP BY EXTRACT(YEAR FROM Checkout.checkout_time), library;

DROP VIEW IF EXISTS years CASCADE;
DROP VIEW IF EXISTS year_branch CASCADE;
DROP VIEW IF EXISTS solution1 CASCADE;
DROP VIEW IF EXISTS solution2 CASCADE;
DROP VIEW IF EXISTS solution3 CASCADE;
DROP VIEW IF EXISTS solution4 CASCADE;
DROP VIEW IF EXISTS solution5 CASCADE;
DROP VIEW IF EXISTS solution6 CASCADE;

CREATE VIEW years AS(
    (SELECT 2015 AS year)
    UNION 
    (SELECT 2016 AS year)
    UNION
    (SELECT 2017 AS year)
    UNION
    (SELECT 2018 AS year)
    UNION
    (SELECT 2019 AS year)
);

CREATE VIEW year_branch AS
SELECT year, LibraryBranch.code AS branch
FROM LibraryBranch, years;

CREATE VIEW solution1 AS
SELECT year_branch.year, year_branch.branch, (CASE 
    WHEN events IS NULL THEN 0
    ELSE events
    END) AS events
FROM year_branch
LEFT JOIN event_count
ON year_branch.year = event_count.year AND year_branch.branch = event_count.branch;

CREATE VIEW solution2 AS
SELECT solution1.year, solution1.branch, events, (CASE 
    WHEN sessions IS NULL THEN 0
    ELSE sessions
    END) AS sessions
FROM solution1
LEFT JOIN session_count
ON solution1.year = session_count.year AND solution1.branch = session_count.branch;

CREATE VIEW solution3 AS
SELECT solution2.year, solution2.branch, events, sessions, (CASE 
    WHEN registration IS NULL THEN 0
    ELSE registration
    END) AS registration
FROM solution2
LEFT JOIN registration_count
ON solution2.year = registration_count.year AND solution2.branch = registration_count.branch;

CREATE VIEW solution4 AS
SELECT solution3.year, solution3.branch, events, sessions, registration, (CASE 
    WHEN holdings IS NULL THEN 0
    ELSE holdings
    END) AS holdings
FROM solution3
LEFT JOIN holding_count
ON solution3.branch = holding_count.branch;

CREATE VIEW solution5 AS
SELECT solution4.year, solution4.branch, events, sessions, registration, holdings, (CASE 
    WHEN checkouts IS NULL THEN 0
    ELSE checkouts
    END) AS checkouts
FROM solution4
LEFT JOIN all_checkouts
ON solution4.year = all_checkouts.year AND solution4.branch = all_checkouts.branch;

CREATE VIEW solution6 AS
SELECT solution5.branch, solution5.year, events, sessions, 
    registration, holdings, checkouts, (CASE 
    WHEN duration IS NULL THEN 0
    ELSE duration
    END) AS duration
FROM solution5
LEFT JOIN duration_average
ON solution5.year = duration_average.year AND solution5.branch = duration_average.branch;

-- Merge all the information
-- Create a cross join between year and branch
-- Left join 
-- Your query that answers the question goes below the "insert into" line:

insert into q1 SELECT * FROM solution6;
