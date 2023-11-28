-- You must not change the next 2 lines or the table definition.  
SET SEARCH_PATH TO Library, public;  
  
  
-- Do this for each of the views that define your intermediate steps.    
-- (But give them better names!) The IF EXISTS avoids generating an error   
-- the first time this file is imported.  
DROP VIEW IF EXISTS invalid_sessions_event CASCADE;  
DROP VIEW IF EXISTS valid_event CASCADE;  
DROP VIEW IF EXISTS invalid_event CASCADE;  
  
-- You might find this helpful for solving update 1:  
-- A mapping between the day of the week and its index  
DROP VIEW IF EXISTS day_of_week CASCADE;  
CREATE VIEW day_of_week (day, idx) AS  
SELECT * FROM (  
    VALUES ('sun', 0), ('mon', 1), ('tue', 2), ('wed', 3),  
           ('thu', 4), ('fri', 5), ('sat', 6)  
) AS d(day, idx);  
  
-- Get all sessions of events with their libraries (edate, event_id, start_time, end_time, branch, weekday)
CREATE VIEW invalid_sessions_event AS
SELECT EventSchedule.event AS event, EventSchedule.edate AS edate, 
	EventSchedule.start_time AS start_time, EventSchedule.end_time AS end_time
FROM LibraryHours, EventSchedule, LibraryEvent, LibraryRoom, LibraryBranch, day_of_week
WHERE LibraryEvent.id = EventSchedule.event AND LibraryEvent.room = LibraryRoom.id
	AND LibraryRoom.library = LibraryBranch.code 
	AND LibraryBranch.code = LibraryHours.library
	AND LibraryHours.day::TEXT = day_of_week.day 
	AND day_of_week.idx = EXTRACT(DOW FROM EventSchedule.edate)
	AND (LibraryHours.start_time > EventSchedule.start_time
	OR LibraryHours.end_time < EventSchedule.end_time);
-- Join it with library hours find bad eventsand only keep good events (edate, start_time, end_time, branch, weekday)

DELETE FROM EventSchedule
USING invalid_sessions_event 
WHERE invalid_sessions_event.event = EventSchedule.event AND invalid_sessions_event.edate = EventSchedule.edate;
-- Join it with libarary event to find unused events and only keep events with sessions

CREATE VIEW valid_event AS
SELECT DISTINCT EventSchedule.event AS event
FROM EventSchedule, LibraryEvent
WHERE EventSchedule.event = LibraryEvent.id;

CREATE VIEW invalid_event AS
SELECT DISTINCT id
FROM LibraryEvent
EXCEPT
SELECT event AS id
FROM valid_event; 

DELETE FROM LibraryEvent
USING invalid_event
WHERE LibraryEvent.id = invalid_event.id;
