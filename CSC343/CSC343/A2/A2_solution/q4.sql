-- Explorers Contest

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q4 cascade;

CREATE TABLE q4 (
    patronID CHAR(20)
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS actual_information CASCADE;
DROP VIEW IF EXISTS satisfied_patrons CASCADE;
-- Define views for your intermediate steps here:

-- Patrons that actually attend the events. (ward, year, patronID)
CREATE VIEW actual_information AS
SELECT Ward.id AS ward, EXTRACT(YEAR FROM EventSchedule.edate) AS year, 
    EventSignUp.patron AS patronID
FROM Ward, EventSignUp, LibraryRoom, LibraryBranch, EventSchedule, LibraryEvent
WHERE LibraryBranch.ward = Ward.id AND LibraryRoom.library = LibraryBranch.code
    AND LibraryRoom.id = LibraryEvent.room AND EventSchedule.event = EventSignUp.event;
 

-- Patron who does not satisfy requirement in some years. (patronID, year)
CREATE VIEW satisfied_patrons AS
SELECT patronID
FROM actual_information, ward 
GROUP BY patronID, year
HAVING COUNT(DISTINCT actual_information.ward) = COUNT(DISTINCT ward.id);

insert into q4
SELECT * FROM satisfied_patrons;
