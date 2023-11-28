-- Devoted Fans

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q6 cascade;

CREATE TABLE q6 (
    patronID Char(20),
    devotedness INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS valid_books CASCADE;
DROP VIEW IF EXISTS author_information CASCADE;
DROP VIEW IF EXISTS reader_information CASCADE;
DROP VIEW IF EXISTS devoted_readers CASCADE;
DROP VIEW IF EXISTS all_readers CASCADE;
-- Define views for your intermediate steps here:

-- Find all valid books 
CREATE VIEW valid_books AS
SELECT Holding.id AS holding_id, AVG(HoldingContributor.contributor) AS author_id
FROM Holding, HoldingContributor
WHERE Holding.htype = 'books' AND HoldingContributor.holding = Holding.id
GROUP BY Holding.id
HAVING COUNT(HoldingContributor.contributor) = 1;

-- Find all patrons and their checkedout books with auther and reviews  
CREATE VIEW author_information AS 
SELECT author_id AS author_id, COUNT(valid_books.holding_id) AS books_count
FROM valid_books
GROUP BY valid_books.author_id;

-- Find all patrons with authurs and total number of books and average review
CREATE VIEW reader_information AS
SELECT valid_books.author_id AS author_id, 
    Checkout.patron AS patron_id, COUNT(Checkout.holding) AS actual_books_count
FROM Checkout, Review, valid_books
WHERE Checkout.holding = valid_books.holding_id AND Review.holding = Checkout.holding
    AND Review.patron = Checkout.patron
GROUP BY valid_books.author_id, Checkout.patron
HAVING AVG(Review.stars) >= 4.0;

-- Join previous steps to find difference of books less than 1 and average review greater than 4.0
CREATE VIEW devoted_readers AS
SELECT reader_information.patron_id AS patronID,
    COUNT(author_information.author_id) AS devotedness
FROM reader_information, author_information
WHERE reader_information.author_id = author_information.author_id
    AND reader_information.actual_books_count > author_information.books_count - 2
GROUP BY reader_information.patron_id;

-- Join it with all partons
CREATE VIEW all_readers AS
SELECT Patron.card_number AS patronID, 
    (CASE WHEN devotedness is NULL THEN 0
    ELSE devotedness
    END) AS devotedness
FROM Patron
LEFT JOIN devoted_readers
ON Patron.card_number = devoted_readers.patronID;

-- Your query that answers the question goes below the "insert into" line:
insert into q6
SELECT * FROM all_readers;
