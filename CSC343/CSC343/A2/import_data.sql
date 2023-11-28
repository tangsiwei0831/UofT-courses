SET SEARCH_PATH TO Library;

-- Import Data for Holding
\Copy Holding FROM './Holding.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for HoldingSeries
\Copy HoldingSeries FROM './HoldingSeries.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for HoldingISBN
\Copy HoldingISBN FROM './HoldingISBN.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Contributor
\Copy Contributor FROM './Contributor.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for HoldingContributor
\Copy HoldingContributor FROM './HoldingContributor.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Ward
\Copy Ward FROM './Ward.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryBranch
\Copy LibraryBranch FROM './LibraryBranch.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryRoom
\Copy LibraryRoom FROM './LibraryRoom.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryHours
\Copy LibraryHours FROM './LibraryHours.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryCatalogue
\Copy LibraryCatalogue FROM './LibraryCatalogue.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryEvent
\Copy LibraryEvent FROM './LibraryEvent.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventAgeGroup
\Copy EventAgeGroup FROM './EventAgeGroup.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSubject
\Copy EventSubject FROM './EventSubject.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSchedule
\Copy EventSchedule FROM './EventSchedule.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Patron
\Copy Patron FROM './Patron.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Checkout
\Copy Checkout FROM './Checkout.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Return
\Copy Return FROM './Return.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Review
\Copy Review FROM './Review.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for RoomBooking
\Copy RoomBooking FROM './RoomBooking.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSignUp
\Copy EventSignUp FROM './EventSignUp.csv' With CSV DELIMITER ',' HEADER;
