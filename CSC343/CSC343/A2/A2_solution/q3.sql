-- Promotion

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q3 cascade;

create domain patronCategory as varchar(10)
  check (value in ('inactive', 'reader', 'doer', 'keener'));

create table q3 (
    patronID Char(20),
    category patronCategory
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS patron_event_count CASCADE;
DROP VIEW IF EXISTS patron_checkout_count CASCADE;
DROP VIEW IF EXISTS event_library CASCADE;
DROP VIEW IF EXISTS checkout_library CASCADE;
DROP VIEW IF EXISTS patron_library CASCADE;
DROP VIEW IF EXISTS comparison_checkout CASCADE;
DROP VIEW IF EXISTS comparison_event CASCADE;
DROP VIEW IF EXISTS event_comparison_result CASCADE;
DROP VIEW IF EXISTS checkout_comparison_result CASCADE;
DROP VIEW IF EXISTS patron_library_information CASCADE;
DROP VIEW IF EXISTS categorized CASCADE;
-- Define views for your intermediate steps here:

-- Find all libraries and their corresponding users of checked out books
CREATE VIEW patron_event_count AS
SELECT Patron.card_number AS patron_id, COUNT(EventSignUp.event) AS event_count
FROM Patron
LEFT JOIN EventSignUp
ON EventSignUp.patron = Patron.card_number
GROUP BY Patron.card_number;

CREATE VIEW patron_checkout_count AS
SELECT Patron.card_number AS patron_id, COUNT(Checkout.id) AS checkout_count 
FROM Patron
LEFT JOIN Checkout
ON Checkout.patron = Patron.card_number
GROUP BY Patron.card_number;

-- Find all libraries and their corresponding users of register at least one event or booked at least one book
CREATE VIEW event_library AS
SELECT DISTINCT LibraryBranch.code AS library_code, EventSignUp.patron AS patron_id
FROM EventSignUp, LibraryBranch, LibraryEvent, LibraryRoom
WHERE EventSignUp.event = LibraryEvent.id AND LibraryEvent.room = LibraryRoom.id
  AND LibraryRoom.library = LibraryBranch.code;

CREATE VIEW checkout_library AS
SELECT DISTINCT LibraryBranch.code AS library_code, Checkout.patron AS patron_id
FROM Checkout, LibraryBranch
WHERE LibraryBranch.code = Checkout.library;

CREATE VIEW patron_library AS
SELECT library_code, patron_id
FROM event_library
UNION 
SELECT library_code, patron_id
FROM checkout_library;

-- Find two comparsion groups
CREATE VIEW comparison_checkout AS
SELECT DISTINCT patron_library.patron_id AS patron_id, checkout_library.patron_id AS comparison_id
FROM patron_library, checkout_library
WHERE patron_library.library_code = checkout_library.library_code;

CREATE VIEW comparison_event AS
SELECT DISTINCT patron_library.patron_id AS patron_id, event_library.patron_id AS comparison_id
FROM patron_library, event_library
WHERE patron_library.library_code = event_library.library_code;

-- Find their average and their own value
CREATE VIEW event_comparison_result AS
SELECT AVG(himself.event_count) AS event_count, AVG(comparison.event_count) AS event_comparison_avg, 
  himself.patron_id AS patron_id
FROM patron_event_count comparison, patron_event_count himself, comparison_event
WHERE himself.patron_id = comparison_event.patron_id AND comparison_event.comparison_id = comparison.patron_id
GROUP BY himself.patron_id; 

CREATE VIEW checkout_comparison_result AS
SELECT AVG(himself.checkout_count) AS checkout_count, AVG(comparison.checkout_count) AS checkout_comparison_avg, 
  himself.patron_id AS patron_id
FROM patron_checkout_count comparison, patron_checkout_count himself, comparison_checkout
WHERE himself.patron_id = comparison_checkout.patron_id AND comparison_checkout.comparison_id = comparison.patron_id
GROUP BY himself.patron_id; 

-- Find their average and their own value 
CREATE VIEW patron_library_information AS
SELECT checkout_comparison_result.patron_id, checkout_count, checkout_comparison_avg, event_count, event_comparison_avg
FROM checkout_comparison_result, event_comparison_result
WHERE checkout_comparison_result.patron_id = event_comparison_result.patron_id;

-- Join two tables 


-- Find average checked out books for every users and average number of events

-- Merge with all patrons
CREATE VIEW categorized AS
SELECT Patron.card_number, 
  (CASE WHEN event_count > 0.75 * event_comparison_avg AND checkout_count > 0.75 * checkout_comparison_avg
    THEN 'keener'
    WHEN event_count > 0.75 * event_comparison_avg AND checkout_count < 0.25 * checkout_comparison_avg
    THEN 'doer'
    WHEN event_count < 0.25 * event_comparison_avg AND checkout_count > 0.75 * checkout_comparison_avg
    THEN 'reader'
    WHEN event_count < 0.25 * event_comparison_avg AND checkout_count < 0.25 * checkout_comparison_avg
    THEN 'inactive'
  ELSE NULL 
  END) AS category
FROM Patron
LEFT JOIN patron_library_information
ON patron_library_information.patron_id = Patron.card_number;

-- Your query that answers the question goes below the "insert into" line:
insert into q3 
SELECT * FROM categorized;

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 


-- Define views for your intermediate steps here:
