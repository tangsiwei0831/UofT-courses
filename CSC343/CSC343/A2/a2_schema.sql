-- CSC343, Introduction to Databases
-- Department of Computer Science, University of Toronto

-- This code is provided solely for the personal and private use of
-- students taking the course CSC343 at the University of Toronto.
-- Copying for purposes other than this use is expressly prohibited.
-- All forms of distribution of this code, whether as given or with
-- any changes, are expressly prohibited.

-- Authors: Diane Horton and Marina Tawfik

-- All of the files in this directory and all subdirectories are:
-- Copyright (c) 2020 Diane Horton and Marina Tawfik



-- Schema for storing a subset of the Toronto Public Library data, with some
-- modifications.  The complete dataset is available at 
--		https://opendata.tpl.ca/ 
-- and is provided license free and free of charge under the Library's 
-- Open Data policy.
-- All data concerning patrons, checkouts, returns, reviews, room bookings 
-- and event signups is completely fictional.


DROP SCHEMA IF EXISTS Library CASCADE;
CREATE SCHEMA Library;
SET SEARCH_PATH TO Library;

CREATE TYPE Library.holding_type AS ENUM (
	'music', 'books', 'movies', 'audiobooks', 'magazines and newspapers'
);

CREATE TYPE Library.room_type AS ENUM (
	'auditorium', 'meeting', 'theatre'
);

CREATE TYPE Library.week_day AS ENUM (
	'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'
);

CREATE TYPE Library.age_group AS ENUM (
	'preschooler', 'children', 'teen', 'adults', 'seniors' 
);

-- An item owned by the library system. 
CREATE TABLE If NOT EXISTS Holding (
	id INT PRIMARY KEY,
	-- The title of the holding.
	title TEXT NOT NULL,
	-- The type of the holding. 
	htype holding_type NOT NULL,
	-- The name of the publishing company.
	publisher_name TEXT NOT NULL,
	-- The year in which this item was published.
	publication_year INT NOT NULL 
);

-- An item that is part of a series.
CREATE TABLE If NOT EXISTS HoldingSeries (
	id INT PRIMARY KEY,
	-- The name of the series.
	series TEXT NOT NULL,
	FOREIGN KEY (id) REFERENCES Holding(id) 
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- The ISBN associated with the holding.
-- ISBN stand for "International Standard Book Number", which for the purposes 
-- of this assignment, uniquely identifies an item. An isbn can consist of 
-- 10 characters (if it is following "isbn10" format) or 13 (if it is 
-- following "isbn13" format).
CREATE TABLE If NOT EXISTS HoldingISBN (
	holding INT NOT NULL,
	isbn CHAR(13) NOT NULL,
	PRIMARY KEY(holding, isbn),
	UNIQUE(isbn), 
	FOREIGN KEY (holding) REFERENCES Holding(id) 
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- A Contributer, e.g. an author, an editor or an actor.
CREATE TABLE IF NOT EXISTS Contributor (
	id INT PRIMARY KEY,
	-- The contributor's first name. 
	-- It may also include the middle name or initial.
	given_names TEXT NOT NULL,
	last_name TEXT NOT NULL
);

-- A contributor to a holding.
CREATE TABLE IF NOT EXISTS HoldingContributor (
	holding INT NOT NULL,
	contributor INT NOT NULL,
	PRIMARY KEY(holding, contributor),
	FOREIGN KEY (holding) REFERENCES Holding(id) 
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (contributor) REFERENCES Contributor(id) 
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- A row in this table represents one of Toronto's 44 electoral
-- wards.
CREATE TABLE IF NOT EXISTS Ward (
	id INT PRIMARY KEY,
	name TEXT NOT NULL
);

-- A Library branch. 
CREATE TABLE IF NOT EXISTS LibraryBranch (
	code CHAR(5) PRIMARY KEY,
	-- The name of the library branch.
	name TEXT NOT NULL,
	-- The address of the library branch.
	address TEXT NOT NULL,
	-- The phone number of the library branch.
	phone CHAR(11) NOT NULL,
	-- True if the library branch has parking spaces.
	has_parking BOOLEAN NOT NULL,
	-- The ward, to which the library branch belongs.
	ward INT NOT NULL,
	FOREIGN KEY (ward) REFERENCES Ward(id) 
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- A room in the library.
CREATE TABLE IF NOT EXISTS LibraryRoom (
	id INT PRIMARY KEY,
	-- The library branch where the room exists.
	library CHAR(5) NOT NULL,
	-- The name of the room.
	name TEXT NOT NULL,
	-- The type of the room.
	rtype room_type NOT NULL,
	-- The maximum capacity of the room.
	max_capacity INT NOT NULL,
	FOREIGN KEY (library) REFERENCES LibraryBranch(code)
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- This library branch is open on this day of the week from
-- start_time to end_time.
CREATE TABLE IF NOT EXISTS LibraryHours ( 
	library CHAR(5) NOT NULL,
	-- The day of the week.
	day week_day NOT NULL,
	-- The time when the library branch opens.
	start_time TIME NOT NULL,
	-- The time when the library branch closes.
	end_time TIME NOT NULL,
	PRIMARY KEY (library, day),
	FOREIGN KEY (library) REFERENCES LibraryBranch(code)
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- This library branch owns one or more copies of this holding.
CREATE TABLE IF NOT EXISTS LibraryCatalogue (
	library CHAR(5) NOT NULL,
	holding INT NOT NULL,
	-- The location where the item is stored within the library.
	call_number TEXT NOT NULL,
	-- The number of copies that this library branch owns.
	num_holdings INT NOT NULL,
	-- The number of copies, currently available i.e. not checked out.
	copies_available INT NOT NULL,
	PRIMARY KEY (library, holding),
	FOREIGN KEY (library) REFERENCES LibraryBranch(code)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (holding) REFERENCES Holding(id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	CHECK (num_holdings >= copies_available)
);
bn
-- An event of this name is held in this room.
CREATE TABLE IF NOT EXISTS LibraryEvent ( 
	id INT PRIMARY KEY,
	-- The room where the event occurs.  (This implies a particular
	-- library branch.)
	room INT NOT NULL,
	-- The name of the event.
	name TEXT NOT NULL,
	-- Whether the event requires patrons to sign up. 
	-- Otherwise, it is a drop-in event
	require_sign_up BOOLEAN NOT NULL,
	FOREIGN KEY (room) REFERENCES LibraryRoom(id)
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- This event is geared towards this specific age group.
CREATE TABLE IF NOT EXISTS EventAgeGroup (
	event INT NOT NULL,
	-- The age group addressed by the library event.
	egroup age_group NOT NULL,
	PRIMARY KEY(event, egroup),
	FOREIGN KEY (event) REFERENCES LibraryEvent(id)
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- This event addresses this specific subject.
CREATE TABLE IF NOT EXISTS EventSubject (
	event INT NOT NULL,
	subject TEXT NOT NULL,
	PRIMARY KEY(event, subject),
	FOREIGN KEY (event) REFERENCES LibraryEvent(id)
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- This event has a session on this date between this start time
-- and this end time.
CREATE TABLE IF NOT EXISTS EventSchedule (
	event INT NOT NULL,
	-- The date on which this event will occur.
	edate DATE NOT NULL,
	-- The time at which the event is scheduled to start.
	start_time TIME NOT NULL,
	-- The time at which the event is scheduled to end.
	end_time TIME NOT NULL,
	PRIMARY KEY(event, edate),
	FOREIGN KEY (event) REFERENCES LibraryEvent(id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	CHECK (start_time < end_time)
);

-- A patron of the library.
CREATE TABLE IF NOT EXISTS Patron (
	card_number CHAR(20) PRIMARY KEY,
	-- The patron's first name.
	first_name TEXT NOT NULL,
	-- The patron's last name.
	last_name TEXT NOT NULL,
	-- The patron's email.
	email TEXT,
	-- The patron's address.
	address TEXT NOT NULL,
	-- The patron's telephone number.
	phone CHAR(11) NOT NULL,
	UNIQUE(email)
);

-- This patron checked out this holding from this library branch at this
-- checkout time.
CREATE TABLE IF NOT EXISTS Checkout ( 
	id INT PRIMARY KEY,
	patron CHAR(20) NOT NULL,
	holding INT NOT NULL,
	library CHAR(5) NOT NULL,
	-- The time at which the checkout occured.
	checkout_time TIMESTAMP NOT NULL,
	UNIQUE(patron, holding, library, checkout_time),
	FOREIGN KEY (patron) REFERENCES Patron(card_number)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (holding, library) 
		REFERENCES LibraryCatalogue(holding, library)
		ON DELETE CASCADE ON UPDATE CASCADE 
);

-- This checked out item was returned at this time.
CREATE TABLE IF NOT EXISTS Return (
	checkout INT PRIMARY KEY,
	-- The time at which the item was returned.
	return_time TIMESTAMP NOT NULL,
	FOREIGN KEY (checkout) REFERENCES Checkout(id)
		ON DELETE CASCADE ON UPDATE CASCADE
);

-- A review of a holding.
CREATE TABLE IF NOT EXISTS Review (
	patron CHAR(20) NOT NULL,
	holding INT NOT NULL,
	stars INT,
	review TEXT NOT NULL,
	PRIMARY KEY(patron, holding),
	FOREIGN KEY (patron) REFERENCES Patron(card_number)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (holding) REFERENCES Holding(id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	CHECK (stars > 0 AND stars <= 5)
);

-- A row in this table indicates that a patron has booked a room in the library.
CREATE TABLE IF NOT EXISTS RoomBooking (
	patron CHAR(20) NOT NULL,
	room INT NOT NULL,
	-- The date of the booking.
	booking_date DATE NOT NULL,
	-- The start time of the booking.
	start_time TIME NOT NULL,
	-- The end time of the booking.
	end_time TIME NOT NULL,
	PRIMARY KEY (patron, room, booking_date, start_time),
	FOREIGN KEY (patron) REFERENCES Patron(card_number)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (room) REFERENCES LibraryRoom(id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	CHECK (start_time < end_time)
);

-- A row in this table indicates that a patron has signed up for an event.
CREATE TABLE IF NOT EXISTS EventSignUp (
	patron CHAR(20) NOT NULL,
	event INT NOT NULL,
	PRIMARY KEY(patron, event),
	FOREIGN KEY (patron) REFERENCES Patron(card_number)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (event) REFERENCES LibraryEvent(id)  
		ON DELETE CASCADE ON UPDATE CASCADE
);
