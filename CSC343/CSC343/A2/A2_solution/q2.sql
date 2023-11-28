-- Overdue Items

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q2 cascade;

create table q2 (
    branch CHAR(5),
    email TEXT,
    title TEXT,
    overdue INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS check_out_information CASCADE;
DROP VIEW IF EXISTS return_information CASCADE;
DROP VIEW IF EXISTS overdue_information CASCADE;
-- Define views for your intermediate steps here:

-- Find all branches in the ward “Parkdale-High Park”, and all check_out information
-- in those branches. (branch, patron, title, checkout_time, htype)
CREATE VIEW check_out_information AS
SELECT Checkout.id AS checkout_id, Checkout.library AS branch, Holding.title AS title,
    Checkout.checkout_time AS checkout_time, htype, Patron.email AS email
FROM Checkout, Ward, LibraryBranch, Patron, Holding
WHERE Checkout.library = LibraryBranch.code AND LibraryBranch.ward = Ward.id
    AND Ward.name = 'Parkdale-High Park'
    AND Checkout.patron = Patron.card_number AND Checkout.holding = Holding.id;

-- Find all overdue items with their corresponding information (Left join)
-- (branch, patron, title, time_diff, htype)
CREATE VIEW return_information AS 
SELECT branch AS branch, title, email, CURRENT_DATE - DATE(check_out_information.checkout_time) AS overdue, htype
FROM check_out_information
LEFT JOIN Return
ON check_out_information.checkout_id = Return.checkout
WHERE Return.return_time IS NULL;

-- Find if items are overdue
CREATE VIEW overdue_information AS 
SELECT branch, email, title, (CASE 
    WHEN htype IN ('books', 'audiobooks') THEN overdue - 21
    ELSE overdue - 7
    END) AS overdue
FROM return_information
WHERE ((htype IN ('books', 'audiobooks') AND overdue > 21)
    OR  (htype IN ('music', 'movies', 'magazines and newspapers') AND overdue > 7));
    

-- Your query that answers the question goes below the "insert into" line:
insert into q2
SELECT * FROM overdue_information;
