-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS doHold CASCADE;
DROP VIEW IF EXISTS bookHold CASCADE;
DROP VIEW IF EXISTS suitPatron CASCADE;
DROP VIEW IF EXISTS notSuit CASCADE;
DROP VIEW IF EXISTS satis CASCADE;
DROP VIEW IF EXISTS bookSatisfied CASCADE;

-- Find library code for Downsview library
CREATE VIEW codes AS
select code
from LibraryBranch where name = 'Downsview';

-- Find all patrons and check out items at Downsview
CREATE VIEW doHold AS
select patron, holding
from Checkout, codes where Checkout.library = codes.code;

-- all books check out Downsview
CREATE VIEW bookHold AS
select doHold.patron, Holding.id
from Holding, doHold
Where Holding.id = doHold.holding AND htype = 'books';

--  Patron that check out books no more than 5
CREATE VIEW suitPatron AS
select patron from bookHold
group by patron
having count(id) <= 5;

--Patrons that have books overdue is more than 7 days
CREATE VIEW notSuit AS
select DISTINCT(bookHold.patron) from bookHold, Checkout
where bookHold.id = Checkout.holding
and Checkout.checkout_time + INTERVAL '31 day' <  CURRENT_DATE;


--find patron satisfy both condition
CREATE VIEW satis AS
select patron from suitPatron
EXCEPT
select patron from notSuit;

-- find all the books check out by satisfy patrons
CREATE VIEW bookSatisfied AS
select bookHold.id
from satis, bookHold where satis.patron = bookHold.patron;

-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.
UPDATE Checkout
SET checkout_time = checkout_time + INTERVAL '14 day'
from bookSatisfied
where Checkout.holding = bookSatisfied.id;
