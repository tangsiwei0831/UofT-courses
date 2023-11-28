-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS closeSunday CASCADE;
DROP VIEW IF EXISTS alllib CASCADE;
DROP VIEW IF EXISTS notSunday CASCADE;
DROP VIEW IF EXISTS closeLate CASCADE;
DROP VIEW IF EXISTS suit CASCADE;
DROP VIEW IF EXISTS openThursday CASCADE;
DROP VIEW IF EXISTS openSunday CASCADE;
--all libraries that open on sunday
CREATE VIEW openSunday AS
select library from LibraryHours where day = 'sun';

-- all the libraries
CREATE VIEW allLib AS
select code as library from LibraryBranch;

--library that does not open on sunday
CREATE VIEW notSunday AS
select library from allLib
EXCEPT
select library from openSunday;

--all libraries that has weekday open past 6 pm
CREATE VIEW closeLate AS
select DISTINCT(library) from LibraryHours where LibraryHours.end_time > TIME '18:00:00';

--all libraries closed on Sunday and all weekdays closes before 6 pm.
CREATE VIEW suit AS
select library from notSunday
EXCEPT
select library from closeLate;

-- all libraries that opens on thursday
CREATE VIEW openThursday AS
select library from LibraryHours where day = 'thu';

--library that does not open on thursday
CREATE VIEW notThursday AS
select library from allLib
EXCEPT
select library from openThursday;

-- library that is closed on Sunday and is never open past 6 pm on a weeknight and is closed on Thursday
CREATE VIEW allSatisfied AS
select suit.library
from suit, notThursday where suit.library = notThursday.library;


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.
UPDATE LibraryHours
SET end_time = TIME '21:00:00'
from suit
WHERE LibraryHours.library = suit.library and LibraryHours.day = 'thu';

INSERT INTO LibraryHours
select LibraryHours.library, 'thu', TIME '18:00:00', TIME '21:00:00'
from allSatisfied, LibraryHours
WHERE LibraryHours.library = allSatisfied.library;
