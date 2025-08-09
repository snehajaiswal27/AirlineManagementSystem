-- CS4400: Introduction to Database Systems (Spring 2025)
-- Phase II: Create Table & Insert Statements [v0] Monday, February 3, 2025 @ 17:00 EST

-- Team 99
-- Lucas Zangari lzangari3
-- Adrian Kalisz aklaisz3
-- Nicholas Reed nreed36

-- Directions:
-- Please follow all instructions for Phase II as listed on Canvas.
-- Fill in the team number and names and GT usernames for all members above.
-- Create Table statements must be manually written, not taken from an SQL Dump file.
-- This file must run without error for credit.

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'airline_management';
drop database if exists airline_management;
create database if not exists airline_management;
use airline_management;

-- Define the database structures
/* You must enter your tables definitions, along with your primary, unique and foreign key
declarations, and data insertion statements here.  You may sequence them in any order that
works for you.  When executed, your statements must create a functional database that contains
all of the data, and supports as many of the constraints as reasonably possible. */

CREATE TABLE location (
    locID VARCHAR(50) PRIMARY KEY
);

CREATE TABLE airline (
    airlineID VARCHAR(50) PRIMARY KEY,
    revenue DOUBLE NOT NULL CHECK (revenue >= 0)
);

CREATE TABLE route (
    routeID VARCHAR(50) NOT NULL PRIMARY KEY,
    total_distance INT NOT NULL CHECK (total_distance >= 0)
);

CREATE TABLE airport (
    airportID CHAR(3) NOT NULL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country CHAR(3) NOT NULL CHECK (LENGTH(country) = 3),
    travelers INT NOT NULL CHECK (travelers >= 0),
    locID VARCHAR(50),
    
    FOREIGN KEY (locID) REFERENCES location(locID)
);

CREATE TABLE flight (
    flightID VARCHAR(50) NOT NULL PRIMARY KEY,
    cost INT NOT NULL CHECK (cost >= 0),
    routeID VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (routeID) REFERENCES route(routeID)
);

CREATE TABLE passenger (
    personID VARCHAR(50) PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100),
    miles INT CHECK (miles >= 0) DEFAULT 0,
    funds DOUBLE CHECK (funds >= 0) DEFAULT 0,
    locID VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (locID) REFERENCES location(locID)
);

CREATE TABLE vacation (
    sequence VARCHAR(50) NOT NULL,
    destination VARCHAR(50) NOT NULL,
    passengerID VARCHAR(50) NOT NULL,
    
    PRIMARY KEY (sequence, destination, passengerID),
    
    FOREIGN KEY (passengerID) REFERENCES passenger(personID)
);

CREATE TABLE pilot (
    personID VARCHAR(50) NOT NULL PRIMARY KEY,
    taxID CHAR(11) NOT NULL CHECK (taxID REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'),
    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100) NOT NULL,
    experience INT NOT NULL CHECK (experience >= 0),
    locID VARCHAR(50) NOT NULL,
    flightID VARCHAR(50),
    
    FOREIGN KEY (locID) REFERENCES location(locID),
    FOREIGN KEY (flightID) REFERENCES flight(flightID)
);

CREATE TABLE license (
    aircraft_name VARCHAR(50) NOT NULL,
    pilotID VARCHAR(50) NOT NULL,
    
    PRIMARY KEY (aircraft_name, pilotID),
    
    FOREIGN KEY (pilotID) REFERENCES pilot(personID)
);

CREATE TABLE airplane (
    tail_num VARCHAR(50) NOT NULL,
    airlineID VARCHAR(50) NOT NULL,
    speed INT NOT NULL CHECK (speed > 0),
    seat_cap INT NOT NULL CHECK (seat_cap > 0),
    filled INT NOT NULL CHECK (filled >= 0),
    locID VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (airlineID) REFERENCES airline(airlineID),
    FOREIGN KEY (locID) REFERENCES location(locID),
    PRIMARY KEY (tail_num, airlineID),
    
    -- Do this to avoid checking two diff columns error
    CONSTRAINT chk_filled_seat_cap CHECK (filled <= seat_cap)
);

CREATE TABLE boeing (
    tail_num VARCHAR(50) NOT NULL,
    airlineID VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    maintained BOOLEAN NOT NULL,
    
    FOREIGN KEY (tail_num, airlineID) REFERENCES airplane(tail_num, airlineID),
    PRIMARY KEY (tail_num, airlineID)
);

CREATE TABLE airbus (
    tail_num VARCHAR(50) NOT NULL,
    airlineID VARCHAR(50) NOT NULL,
    variant VARCHAR(50) NOT NULL,
    
    PRIMARY KEY (tail_num, airlineID),
    
    FOREIGN KEY (tail_num, airlineID) REFERENCES airplane(tail_num, airlineID)
);

CREATE TABLE supports (
    progress INT NOT NULL CHECK (progress >= 0),
    flight_status VARCHAR(100) NOT NULL,
    next_time TIME NOT NULL,
    flightID VARCHAR(50) NOT NULL PRIMARY KEY,
    tail_num VARCHAR(50) NOT NULL,
    airlineID VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (flightID) REFERENCES flight(flightID),
    FOREIGN KEY (tail_num, airlineID) REFERENCES airplane(tail_num, airlineID)
);

CREATE TABLE leg (
    legID VARCHAR(50) NOT NULL PRIMARY KEY,
    distance INT NOT NULL CHECK (distance >= 0),
    departing_airportID VARCHAR(50) NOT NULL,
    arriving_airportID VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (departing_airportID) REFERENCES airport(airportID),
    FOREIGN KEY (arriving_airportID) REFERENCES airport(airportID)
);

CREATE TABLE route_contains_legs (
    routeID VARCHAR(50) NOT NULL,
    legID VARCHAR(50) NOT NULL,
    sequence VARCHAR(100) NOT NULL,
    
    PRIMARY KEY (routeID, legID),
    
    FOREIGN KEY (routeID) REFERENCES route(routeID),
    FOREIGN KEY (legID) REFERENCES leg(legID)
);

INSERT INTO location (locID) VALUES
('port_1'), ('port_2'), ('port_3'), ('port_4'), ('port_6'), ('port_7'), ('port_10'),
 ('port_11'), ('port_12'), ('port_13'), ('port_14'), ('port_15'), ('port_16'), ('port_17'),
 ('port_18'), ('port_20'), ('port_21'), ('port_22'), ('port_23'), ('port_24'), ('port_25'),
 ('plane_1'), ('plane_2'), ('plane_3'), ('plane_4'), ('plane_5'), ('plane_6'), ('plane_7'),
 ('plane_8'), ('plane_10'), ('plane_13'), ('plane_18'), ('plane_20');
 
INSERT INTO airline (airlineID, revenue) VALUES
('Delta', 53000),
('United', 48000),
('British Airways', 24000),
('Lufthansa', 35000),
('Air_France', 29000),
('KLM', 29000),
('Ryanair', 10000),
('Japan Airlines', 9000),
('China Southern Airlines', 14000),
('Korean Air Lines', 10000),
('American', 52000);

INSERT INTO route (routeID, total_distance) VALUES
('americas_one', 3900),
('americas_three', 3700),
('americas_two', 3700),
('big_europe_loop', 2000),
('euro_north', 600),
('euro_south', 800),
('germany_local', 300),
('pacific_rim_tour', 6400),
('americas_hub_exchange', 600),
('texas_local', 600),
('korea_direct', 6800);

INSERT INTO airport (airportID, name, city, state, country, travelers, locID) VALUES
('ATL', 'Atlanta Hartsfield_Jackson International', 'Atlanta', 'Georgia', 'USA', 0, 'port_1'),
('DXB', 'Dubai International', 'Dubai', 'Al Garhoud', 'UAE', 0, 'port_2'),
('HND', 'Tokyo International Haneda', 'Ota City', 'Tokyo', 'JPN', 0, 'port_3'),
('LHR', 'London Heathrow', 'London', 'England', 'GBR', 0, 'port_4'),
('IST', 'Istanbul International', 'Arnavutkoy', 'Istanbul', 'TUR', 0, NULL),
('DFW', 'Dallas_Fort Worth International', 'Dallas', 'Texas', 'USA', 0, 'port_6'),
('CAN', 'Guangzhou International', 'Guangzhou', 'Guangdong', 'CHN', 0, 'port_7'),
('DEN', 'Denver International', 'Denver', 'Colorado', 'USA', 0, NULL),
('LAX', 'Los Angeles International', 'Los Angeles', 'California', 'USA', 0, NULL),
('ORD', 'O_Hare International', 'Chicago', 'Illinois', 'USA', 0, 'port_10'),
('AMS', 'Amsterdam Schipol International', 'Amsterdam', 'Haarlemmermeer', 'NLD', 0, 'port_11'),
('CDG', 'Paris Charles de Gaulle', 'Roissy_en_France', 'Paris', 'FRA', 0, 'port_12'),
('FRA', 'Frankfurt International', 'Frankfurt', 'Frankfurt_Rhine_Main', 'DEU', 0, 'port_13'),
('MAD', 'Madrid Adolfo Suarez_Barajas', 'Madrid', 'Barajas', 'ESP', 0, 'port_14'),
('BCN', 'Barcelona International', 'Barcelona', 'Catalonia', 'ESP', 0, 'port_15'),
('FCO', 'Rome Fiumicino', 'Flumicino', 'Lazio', 'ITA', 0, 'port_16'),
('LGW', 'London Gatwick', 'London', 'England', 'GBR', 0, 'port_17'),
('MUC', 'Munich International', 'Munich', 'Bavaria', 'DEU', 0, 'port_18'),
('MDW', 'Chicago Midway International', 'Chicago', 'Illinois', 'USA', 0, NULL),
('IAH', 'George Bush Intercontinental', 'Houston', 'Texas', 'USA', 0, 'port_20'),
('HOU', 'William P_Hobby International', 'Houston', 'Texas', 'USA', 0, 'port_21'),
('NRT', 'Narita International', 'Narita', 'Chiba', 'JPN', 0, 'port_22'),
('BER', 'Berlin Brandenburg Willy Brandt International', 'Berlin', 'Schonefeld', 'DEU', 0, 'port_23'),
('ICN', 'Incheon International Airport', 'Seoul', 'Jung_gu', 'KOR', 0, 'port_24'),
('PVG', 'Shanghai Pudong International Airport', 'Shanghai', 'Pudong', 'CHN', 0, 'port_25');

INSERT INTO flight (flightID, cost, routeID) VALUES
('dl_10', 200, 'americas_one'),
('un_38', 200, 'americas_three'),
('ba_61', 200, 'americas_two'),
('lf_20', 300, 'big_europe_loop'),
('km_16', 400, 'euro_north'),
('ja_35', 100, 'euro_south'),
('ry_34', 300, 'germany_local'),
('aa_12', 150, 'pacific_rim_tour'),
('dl_42', 220, 'americas_hub_exchange'),
('ke_64', 500, 'texas_local'),
('lf_67', 900, 'korea_direct');

INSERT INTO passenger (personID, fname, lname, miles, funds, locID) VALUES
('p1', 'Jeanne', 'Nelson', 771, 700.00, 'port_1'),
('p2', 'Roxanne', 'Byrd', 374, 200.00, 'port_1'),
('p11', 'Sandra', 'Cruz', 414, 400.00, 'port_3'),
('p13', 'Bryant', 'Figueroa', 292, 500.00, 'port_3'),
('p14', 'Dana', 'Perry', 390, 300.00, 'port_3'),
('p15', 'Matt', 'Hunt', 302, 600.00, 'port_10'),
('p16', 'Edna', 'Brown', 470, 400.00, 'port_10'),
('p12', 'Dan', 'Ball', 208, 400.00, 'port_3'),
('p17', 'Ruby', 'Burgess', 292, 700.00, 'plane_3'),
('p18', 'Esther', 'Pittman', 686, 500.00, 'plane_10'),
('p19', 'Doug', 'Fowler', 547, 400.00, 'port_17'),
('p8', 'Bennie', 'Palmer', 257, 500.00, 'port_2'),
('p20', 'Thomas', 'Olson', 564, 600.00, 'port_17'),
('p21', 'Mona', 'Harrison', 211, 200.00, 'plane_1'),
('p22', 'Arlene', 'Massey', 233, 500.00, 'plane_1'),
('p23', 'Judith', 'Patrick', 293, 400.00, 'plane_1'),
('p24', 'Reginald', 'Rhodes', 552, 700.00, 'plane_5'),
('p25', 'Vincent', 'Garcia', 812, 300.00, 'plane_5'),
('p26', 'Cheryl', 'Moore', 541, 400.00, 'plane_5'),
('p27', 'Michael', 'Rivera', 441, 500.00, 'plane_8'),
('p28', 'Luther', 'Matthews', 875, 500.00, 'plane_8'),
('p29', 'Moses', 'Parks', 691, 300.00, 'plane_13'),
('p3', 'Tanya', 'Nguyen', 572, 500.00, 'port_1'),
('p30', 'Ora', 'Steele', 572, NULL, 'plane_13'),
('p31', 'Antonio', 'Flores', 663, NULL, 'plane_13'),
('p32', 'Glenn', 'Ross', 690, NULL, 'plane_13'),
('p33', 'Irma', 'Thomas', NULL, NULL, 'plane_20'),
('p34', 'Ann', 'Maldonado', NULL, NULL, 'plane_20'),
('p35', 'Jeffrey', 'Cruz', NULL, NULL, 'port_12'),
('p36', 'Sonya', 'Price', NULL, NULL, 'port_12'),
('p37', 'Tracy', 'Hale', NULL, NULL, 'port_12'),
('p38', 'Albert', 'Simmons', NULL, NULL, 'port_14'),
('p39', 'Karen', 'Terry', NULL, NULL, 'port_15'),
('p4', 'Kendra', 'Jacobs', NULL, NULL, 'port_1'),
('p40', 'Glen', 'Kelley', NULL, NULL, 'port_20'),
('p41', 'Brooke', 'Little', NULL, NULL, 'port_3'),
('p42', 'Daryl', 'Nguyen', NULL, NULL, 'port_4'),
('p43', 'Judy', 'Willis', NULL, NULL, 'port_14'),
('p44', 'Marco', 'Klein', NULL, NULL, 'port_15'),
('p45', 'Angelica', 'Hampton', NULL, NULL, 'port_16'),
('p5', 'Jeff', 'Burton', NULL, NULL, 'port_1'),
('p6', 'Randal', 'Parks', NULL, NULL, 'port_1'),
('p10', 'Lawrence', 'Morgan', NULL, NULL, 'port_3'),
('p7', 'Sonya', 'Warner', NULL, NULL, 'port_2'),
('p9', 'Marlene', 'White', NULL, NULL, 'port_3'),
('p46', 'Janice', NULL, NULL, NULL, 'plane_10');

INSERT INTO vacation (sequence, destination, passengerID) VALUES
('1', 'AMS', 'p1'),
('2', 'AMS', 'p2'),
('1', 'BER', 'p11'),
('1', 'MUC', 'p13'),
('2', 'CDG', 'p13'),
('1', 'MUC', 'p14'),
('1', 'BER', 'p15'),
('1', 'LGW', 'p16'),
('1', 'FCO', 'p17'),
('2', 'LHR', 'p17'),
('1', 'FCO', 'p18'),
('2', 'MAD', 'p18'),
('1', 'FCO', 'p19'),
('1', 'CAN', 'p20'),
('1', 'HND', 'p21'),
('1', 'LGW', 'p22'),
('1', 'FCO', 'p23'),
('1', 'FCO', 'p24'),
('2', 'LGW', 'p24'),
('3', 'CDG', 'p24'),
('1', 'MUC', 'p25'),
('1', 'MUC', 'p26'),
('1', 'HND', 'p27');

INSERT INTO pilot (personID, taxID, fname, lname, experience, locID, flightID) VALUES
('p100', '330-12-6907', 'Jeanne', 'Nelson', 31, 'port_1', 'dl_10'),
('p101', '842-88-1257', 'Roxanne', 'Byrd', 9, 'port_1', 'dl_10'),
('p102', '369-22-9505', 'Sandra', 'Cruz', 22, 'port_3', 'km_16'),
('p103', '513-40-4168', 'Bryant', 'Figueroa', 24, 'port_3', 'km_16'),
('p104', '454-71-7847', 'Dana', 'Perry', 13, 'port_3', 'km_16'),
('p105', '153-47-8101', 'Matt', 'Hunt', 30, 'port_10', 'ja_35'),
('p106', '598-47-5172', 'Edna', 'Brown', 28, 'port_10', 'ja_35'),
('p107', '680-92-5329', 'Dan', 'Ball', 24, 'port_3', 'ry_34'),
('p108', '865-71-6800', 'Ruby', 'Burgess', 36, 'plane_3', 'dl_42'),
('p109', '250-86-2784', 'Esther', 'Pittman', 23, 'plane_10', 'lf_67'),
('p110', '386-39-7881', 'Doug', 'Fowler', 2, 'port_17', 'un_38'),
('p111', '701-38-2179', 'Bennie', 'Palmer', 12, 'port_2', 'un_38'),
('p112', '522-44-3098', 'Thomas', 'Olson', 28, 'port_17', 'ba_61'),
('p113', '750-24-7616', 'Mona', 'Harrison', 11, 'plane_1', 'ba_61'),
('p114', '776-21-8098', 'Arlene', 'Massey', 24, 'plane_1', 'lf_20'),
('p115', '933-93-2165', 'Judith', 'Patrick', 27, 'plane_1', 'lf_20'),
('p116', '707-84-4555', 'Reginald', 'Rhodes', 38, 'plane_5', 'lf_20'),
('p117', '769-60-1266', 'Vincent', 'Garcia', 15, 'plane_5', 'lf_20'),
('p118', '450-25-5617', 'Cheryl', 'Moore', 13, 'plane_5', 'lf_20'),
('p119', '936-44-6941', 'Michael', 'Rivera', 13, 'plane_8', 'lf_20'),
('p120', '707-84-4555', 'Luther', 'Matthews', 38, 'plane_8', 'lf_20'),
('p121', '707-84-4555', 'Moses', 'Parks', 38, 'plane_13', 'lf_20'),
('p122', '707-84-4555', 'Tanya', 'Nguyen', 38, 'port_1', 'lf_20'),
('p123', '707-84-4555', 'Ora', 'Steele', 38, 'plane_13', 'lf_20'),
('p124', '707-84-4555', 'Antonio', 'Flores', 38, 'plane_13', 'lf_20'),
('p125', '707-84-4555', 'Glenn', 'Ross', 38, 'plane_13', 'lf_20'),
('p126', '707-84-4555', 'Irma', 'Thomas', 38, 'plane_20', 'lf_20'),
('p127', '707-84-4555', 'Ann', 'Maldonado', 38, 'plane_20', 'lf_20'),
('p128', '707-84-4555', 'Jeffrey', 'Cruz', 38, 'port_12', 'lf_20'),
('p129', '707-84-4555', 'Sonya', 'Price', 38, 'port_12', 'lf_20'),
('p130', '707-84-4555', 'Tracy', 'Hale', 38, 'port_12', 'lf_20'),
('p131', '707-84-4555', 'Albert', 'Simmons', 38, 'port_14', 'lf_20'),
('p132', '707-84-4555', 'Karen', 'Terry', 38, 'port_15', 'lf_20'),
('p133', '707-84-4555', 'Kendra', 'Jacobs', 38, 'port_1', 'lf_20'),
('p134', '707-84-4555', 'Glen', 'Kelley', 38, 'port_20', 'lf_20'),
('p135', '707-84-4555', 'Brooke', 'Little', 38, 'port_3', 'lf_20'),
('p136', '707-84-4555', 'Daryl', 'Nguyen', 38, 'port_4', 'lf_20'),
('p137', '707-84-4555', 'Judy', 'Willis', 38, 'port_14', 'lf_20'),
('p138', '707-84-4555', 'Marco', 'Klein', 38, 'port_15', 'lf_20'),
('p139', '707-84-4555', 'Angelica', 'Hampton', 38, 'port_16', 'lf_20'),
('p140', '707-84-4555', 'Jeff', 'Burton', 38, 'port_1', 'lf_20'),
('p141', '707-84-4555', 'Randal', 'Parks', 38, 'port_1', 'lf_20'),
('p142', '707-84-4555', 'Lawrence', 'Morgan', 38, 'port_3', 'lf_20'),
('p143', '707-84-4555', 'Sonya', 'Warner', 38, 'port_2', 'lf_20'),
('p144', '707-84-4555', 'Marlene', 'White', 38, 'port_3', 'lf_20');

INSERT INTO license (aircraft_name, pilotID) VALUES
('airbus', 'p100'),
('airbus', 'p101'),
('boeing', 'p102'),
('airbus', 'p103'),
('boeing', 'p104'),
('airbus', 'p105'),
('boeing', 'p106'),
('airbus', 'p107'),
('boeing', 'p108'),
('airbus', 'p109'),
('boeing', 'p110'),
('airbus', 'p111'),
('boeing', 'p112'),
('airbus', 'p113'),
('boeing', 'p114'),
('airbus', 'p115'),
('boeing', 'p116'),
('airbus', 'p117'),
('boeing', 'p118'),
('airbus', 'p119'),
('boeing', 'p120'),
('airbus', 'p121'),
('boeing', 'p122'),
('airbus', 'p123'),
('boeing', 'p124'),
('airbus', 'p125'),
('boeing', 'p126'),
('airbus', 'p127'),
('boeing', 'p128'),
('airbus', 'p129'),
('boeing', 'p130'),
('airbus', 'p131'),
('boeing', 'p132'),
('airbus', 'p133'),
('boeing', 'p134'),
('airbus', 'p135'),
('boeing', 'p136'),
('airbus', 'p137'),
('boeing', 'p138'),
('airbus', 'p139'),
('boeing', 'p140'),
('airbus', 'p141'),
('boeing', 'p142'),
('airbus', 'p143'),
('boeing', 'p144');

INSERT INTO airplane (tail_num, airlineID, speed, seat_cap, filled, locID) VALUES
('n106js', 'Delta', 800, 4, 0, 'plane_1'),
('n110jn', 'Delta', 800, 5, 0, 'plane_2'),
('n127js', 'Delta', 600, 4, 0, 'plane_3'),
('n330ss', 'United', 800, 4, 0, 'plane_4'),
('n380sd', 'United', 400, 5, 0, 'plane_5'),
('n616lt', 'British Airways', 600, 7, 0, 'plane_6'),
('n517ly', 'British Airways', 600, 4, 0, 'plane_7'),
('n620la', 'Lufthansa', 800, 4, 0, 'plane_8'),
('n401fj', 'Lufthansa', 300, 4, 0, 'plane_10'),
('n653fk', 'Lufthansa', 600, 6, 0, 'plane_13'),
('n118fm', 'Air_France', 400, 4, 0, 'plane_18'),
('n815pw', 'Air_France', 400, 3, 0, 'plane_20'),
('n161fk', 'KLM', 600, 4, 0, 'plane_1'),
('n337as', 'KLM', 400, 5, 0, 'plane_2'),
('n256ap', 'KLM', 300, 4, 0, 'plane_3'),
('n156sq', 'Ryanair', 600, 8, 0, 'plane_4'),
('n451fi', 'Ryanair', 600, 5, 0, 'plane_5'),
('n341eb', 'Ryanair', 400, 4, 0, 'plane_6'),
('n353kz', 'Ryanair', 400, 4, 0, 'plane_7'),
('n305fv', 'Japan Airlines', 400, 6, 0, 'plane_8'),
('n443wu', 'Japan Airlines', 800, 4, 0, 'plane_10'),
('n454gq', 'China Southern Airlines', 400, 3, 0, 'plane_13'),
('n249yk', 'China Southern Airlines', 400, 4, 0, 'plane_18'),
('n180co', 'Korean Air Lines', 600, 5, 0, 'plane_20'),
('n448cs', 'American', 400, 4, 0, 'plane_1'),
('n225sb', 'American', 800, 8, 0, 'plane_2'),
('n553qn', 'American', 800, 5, 0, 'plane_3');

INSERT INTO boeing (tail_num, airlineID, model, maintained) VALUES
('n106js', 'Delta', '737', FALSE),
('n110jn', 'Delta', '737', TRUE),
('n127js', 'Delta', '787', FALSE),
('n330ss', 'United', '737', TRUE),
('n380sd', 'United', '787', FALSE);

INSERT INTO airbus (tail_num, airlineID, variant) VALUES
('n616lt', 'British Airways', 'A320'),
('n517ly', 'British Airways', 'A380'),
('n620la', 'Lufthansa', 'A320'),
('n401fj', 'Lufthansa', 'A380'),
('n653fk', 'Lufthansa', 'A320');

INSERT INTO supports (progress, flight_status, next_time, flightID, tail_num, airlineID) VALUES
(1, 'in_flight', '08:00:00', 'dl_10', 'n106js', 'Delta'),
(2, 'in_flight', '14:30:00', 'un_38', 'n380sd', 'United'),
(0, 'on_ground', '09:30:00', 'ba_61', 'n616lt', 'British Airways'),
(3, 'in_flight', '11:00:00', 'lf_20', 'n620la', 'Lufthansa'),
(6, 'in_flight', '14:00:00', 'km_16', 'n161fk', 'KLM'),
(0, 'on_ground', '11:30:00', 'ja_35', 'n305fv', 'Japan Airlines'),
(1, 'in_flight', '09:30:00', 'ry_34', 'n341eb', 'Ryanair'),
(0, 'on_ground', '15:00:00', 'aa_12', 'n553qn', 'American'),
(1, 'on_ground', '12:15:00', 'dl_42', 'n110jn', 'Delta'),
(0, 'on_ground', '13:45:00', 'ke_64', 'n180co', 'Korean Air Lines'),
(0, 'on_ground', '16:00:00', 'lf_67', 'n653fk', 'Lufthansa');

INSERT INTO leg (legID, distance, departing_airportID, arriving_airportID) VALUES
('leg_1', 400, 'AMS', 'BER'),
('leg_2', 3900, 'ATL', 'AMS'),
('leg_3', 3700, 'ATL', 'LHR'),
('leg_4', 600, 'ATL', 'ORD'),
('leg_5', 500, 'BCN', 'CDG'),
('leg_6', 300, 'BCN', 'MAD'),
('leg_7', 4700, 'BER', 'CAN'),
('leg_8', 600, 'BER', 'LGW'),
('leg_9', 300, 'BER', 'MUC'),
('leg_10', 1600, 'CAN', 'HND'),
('leg_11', 500, 'CDG', 'BCN'),
('leg_12', 500, 'CDG', 'FCO'),
('leg_13', 400, 'CDG', 'MUC'),
('leg_14', 400, 'CDG', 'MUC'),
('leg_15', 200, 'DFW', 'IAH'),
('leg_16', 800, 'FCO', 'MAD'),
('leg_17', 300, 'FRA', 'BER'),
('leg_18', 100, 'HND', 'NRT'),
('leg_19', 300, 'HOU', 'DFW'),
('leg_20', 100, 'IAH', 'HOU'),
('leg_21', 600, 'LGW', 'BER'),
('leg_22', 600, 'LHR', 'BER'),
('leg_23', 500, 'LHR', 'MUC'),
('leg_24', 300, 'MAD', 'BCN'),
('leg_25', 800, 'MAD', 'FCO'),
('leg_26', 800, 'MAD', 'FCO'),
('leg_27', 300, 'MUC', 'BER'),
('leg_28', 400, 'MUC', 'CDG'),
('leg_29', 400, 'MUC', 'FCO'),
('leg_30', 200, 'MUC', 'FRA'),
('leg_31', 3700, 'ORD', 'CDG'),
('leg_32', 6800, 'DFW', 'ICN'),
('leg_33', 4400, 'ICN', 'LHR'),
('leg_34', 5900, 'ICN', 'LAX'),
('leg_35', 3700, 'CDG', 'ORD'),
('leg_36', 100, 'NRT', 'HND'),
('leg_37', 500, 'PVG', 'ICN'),
('leg_38', 6500, 'LAX', 'PVG');

INSERT INTO route_contains_legs (routeID, legID, sequence) VALUES
('americas_one', 'leg_4', '1'),
('americas_one', 'leg_2', '2'),
('americas_three', 'leg_31', '1'),
('americas_three', 'leg_14', '2'),
('americas_two', 'leg_3', '1'),
('americas_two', 'leg_22', '2'),
('big_europe_loop', 'leg_23', '1'),
('big_europe_loop', 'leg_29', '2'),
('big_europe_loop', 'leg_16', '3'),
('euro_north', 'leg_21', '1'),
('euro_north', 'leg_9', '2'),
('euro_north', 'leg_28', '3'),
('euro_south', 'leg_16', '1'),
('euro_south', 'leg_24', '2'),
('euro_south', 'leg_5', '3'),
('germany_local', 'leg_9', '1'),
('germany_local', 'leg_30', '2'),
('germany_local', 'leg_17', '3'),
('pacific_rim_tour', 'leg_7', '1'),
('pacific_rim_tour', 'leg_10', '2'),
('pacific_rim_tour', 'leg_18', '3'),
('americas_hub_exchange', 'leg_15', '1'),
('americas_hub_exchange', 'leg_20', '2'),
('americas_hub_exchange', 'leg_19', '3'),
('texas_local', 'leg_15', '1'),
('texas_local', 'leg_20', '2'),
('texas_local', 'leg_19', '3'),
('korea_direct', 'leg_32', '1');