-- Lure Them Back

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q5 cascade;

CREATE TABLE q5 (
    patronID CHAR(20),
    email TEXT NOT NULL,
    usage INT,
    decline INT,
    missed INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS patron_2018 CASCADE;
DROP VIEW IF EXISTS patron_2019 CASCADE;
DROP VIEW IF EXISTS patron_2020_false CASCADE;
DROP VIEW IF EXISTS patron_2020 CASCADE;
DROP VIEW IF EXISTS valid_users CASCADE;
DROP VIEW IF EXISTS all_information CASCADE;

-- Define views for your intermediate steps here

-- Patrons who are active in every month in 2018 
CREATE VIEW patron_2018 AS
SELECT Checkout.patron AS patronID, COUNT(Checkout.holding) AS total_holdings
FROM Checkout
WHERE EXTRACT(YEAR FROM Checkout.checkout_time) = 2018
GROUP BY Checkout.patron
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM Checkout.checkout_time)) = 12;

--- Patrons who actually checked out something in 2018 (patronID, month, number_checkouts)
CREATE VIEW patron_2019 AS
SELECT Checkout.patron AS patronID, COUNT(Checkout.holding) AS total_holdings, 
    12 - COUNT(DISTINCT EXTRACT(MONTH FROM Checkout.checkout_time)) AS missed
FROM Checkout
WHERE EXTRACT(YEAR FROM Checkout.checkout_time) = 2019
GROUP BY Checkout.patron
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM Checkout.checkout_time)) > 4 AND 
    COUNT(DISTINCT EXTRACT(MONTH FROM Checkout.checkout_time)) < 12;

--- Patrons who actually checked out something in 2018 (patronID, month, number_checkouts)
CREATE VIEW patron_2020_false AS
SELECT Checkout.patron AS patronID
FROM Checkout
WHERE EXTRACT(YEAR FROM Checkout.checkout_time) = 2020
GROUP BY Checkout.patron
HAVING COUNT(Checkout.checkout_time) > 0;

--- Patrons who checked out some months in 2019 (patronID, month, number_checkouts)
CREATE VIEW patron_2020 AS
SELECT card_number AS patronID
FROM Patron
EXCEPT
SELECT patron_2020_false.patronID AS patronID
FROM patron_2020_false;

--- Find all valid users and their required information
CREATE VIEW valid_users AS 
SELECT valid_patron.patronID AS patronID, COUNT(DISTINCT Checkout.holding) AS usage
FROM ((SELECT patronID FROM patron_2020 INTERSECT 
    SELECT patronID FROM patron_2019) INTERSECT
    SELECT patronID FROM patron_2018) AS valid_patron, Checkout
WHERE valid_patron.patronID = Checkout.patron
GROUP BY valid_patron.patronID;

-- Combine all information (email adress needs to be modified)
CREATE VIEW all_information AS
SELECT valid_users.patronID AS patronID, 
    Patron.email AS email,
    valid_users.usage AS usage,
    patron_2018.total_holdings - patron_2019.total_holdings AS decline,
    patron_2019.missed AS missed
FROM valid_users, patron_2018, patron_2019, Patron
WHERE valid_users.patronID = patron_2018.patronID AND valid_users.patronID = patron_2019.patronID
    AND Patron.card_number = valid_users.patronID;
-- Your query that answers the question goes below the "insert into" line:

insert into q5 
SELECT * FROM all_information;
