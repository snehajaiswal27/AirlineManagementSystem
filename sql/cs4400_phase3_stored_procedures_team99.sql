-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] to [13] stored procedures

-- INSERTED IMPLEMENTATIONS

-- [1] add_airplane()
-- Creates a new airplane associated with a valid airline.
-- Must have a unique tail number for that airline, non-zero seat capacity and speed.
-- Inserts both the airplane and its new, unique location into the database.
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (
    in ip_airlineID varchar(50), in ip_tail_num varchar(50),
    in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50),
    in ip_neo boolean
)
sp_main: begin
        if ip_airlineID is null or ip_tail_num is null or ip_seat_capacity is null or ip_speed is null then
        leave sp_main;
    end if;
    if ip_seat_capacity <= 0 or ip_speed <= 0 then
        leave sp_main;
    end if;
    if not exists (select 1 from airline where airlineID = ip_airlineID) then
        leave sp_main;
    end if;
    if exists (select 1 from airplane where airlineID = ip_airlineID and tail_num = ip_tail_num) then
        leave sp_main;
    end if;
    if exists (select 1 from location where locationID is not NULL and locationID = ip_locationID) then
        leave sp_main;
    end if;

    insert into location(locationID) values (ip_locationID);
    insert into airplane(airlineID, tail_num, seat_capacity, speed, locationID, plane_type, maintenanced, model, neo)
    values (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, ip_maintenanced, ip_model, ip_neo);

end //
delimiter ;

-- [2] add_airport()
-- Creates a new airport with a unique airport ID and a new, unique location.
-- Includes full city, state, and country designation.
-- Adds both airport and location entries.
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (
    in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50)
)
sp_main: begin
    if ip_airportID is null or ip_locationID is null or ip_city is null or ip_state is null or ip_country is null then
        leave sp_main;
    end if;
    if exists (select 1 from airport where airportID = ip_airportID) then -- leave if airportID in use
        leave sp_main;
    end if;
    if exists (select 1 from location where locationID = ip_locationID) then -- leave if locationID in use
        leave sp_main;
    end if;
    insert into location(locationID) values (ip_locationID); -- check location table. 
		/*
		CREATE TABLE "airport" (
	  "airportID" char(3) NOT NULL,
	  "airport_name" varchar(200) DEFAULT NULL,
	  "city" varchar(100) NOT NULL,
	  "state" varchar(100) NOT NULL,
	  "country" char(3) NOT NULL,
	  "locationID" varchar(50) DEFAULT NULL,
	  PRIMARY KEY ("airportID"),
	  KEY "fk2" ("locationID"),
	  CONSTRAINT "fk2" FOREIGN KEY ("locationID") REFERENCES "location" ("locationID")
	)
		*/
    insert into airport(airportID, airport_name, city, state, country, locationID)
    values (ip_airportID, ip_airport_name, ip_city, ip_state, ip_country, ip_locationID);
end //
delimiter ;

-- [3] add_person()
-- Adds a new person to the system with a unique ID and valid location.
-- Requires first name and handles both pilot and passenger roles depending on attributes.
drop procedure if exists add_person;
delimiter //
create procedure add_person (
    in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer
)
sp_main: begin
    if ip_personID is null or ip_first_name is null or ip_locationID is null then
        leave sp_main;
    end if;
    if not exists (select 1 from location where locationID = ip_locationID) then -- leave if location not valid
        leave sp_main;
    end if;
    if exists (select 1 from person where personID = ip_personID) then -- leave if personID in use
        leave sp_main;
    end if;
    -- taxID CHAR(11) NOT NULL CHECK (taxID REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'),
    if ip_taxID is not null then
		if ip_taxID not REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$' then
			leave sp_main;
		elseif exists (select 1 from pilot where taxID = ip_taxID) then -- leave if pilot taxID in use.
			leave sp_main;
		end if;
        if ip_experience < 0 then
			leave sp_main;
		end if;
	end if;
    -- by the time we arrive here, we're ready to make EITHER a pilot or a passenger
    
		/*
		CREATE TABLE "person" (
	  "personID" varchar(50) NOT NULL,
	  "first_name" varchar(100) NOT NULL,
	  "last_name" varchar(100) DEFAULT NULL,
	  "locationID" varchar(50) NOT NULL,
	  PRIMARY KEY ("personID"),
	  KEY "fk8" ("locationID"),
	  CONSTRAINT "fk8" FOREIGN KEY ("locationID") REFERENCES "location" ("locationID")
	)
		*/
    -- we make a person that gets assigned in the next step
    insert into person values (ip_personID, ip_first_name, ip_last_name, ip_locationID);
    
    -- we check for either a pilot or passenger type and assign the above person as their fk --> person
    if ip_taxID is not null then
		insert into pilot values (ip_personID, ip_taxID, ip_experience, null);
    else
		insert into passenger values (ip_personID, ip_miles, ip_funds);
    end if;
    
    
end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- Toggles a pilot license: adds it if not present, removes it if already exists.
-- Used to manage pilot certification dynamically.
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license (
    in ip_personID varchar(50), in ip_license varchar(100)
)
sp_main: begin
    if ip_personID is null or ip_license is null then
        leave sp_main;
    end if;
    if not exists (select 1 from pilot where personID = ip_personID) then -- we check if this personID relates to a pilot
		leave sp_main;
	end if;
    if exists (select 1 from pilot_licenses where personID = ip_personID and license = ip_license) then
        delete from pilot_licenses where personID = ip_personID and license = ip_license; -- remove license if exists
    else
        insert into pilot_licenses(personID, license) values (ip_personID, ip_license);
    end if;
end //
delimiter ;

-- [5] offer_flight()
-- Creates a new flight with a valid route and (optionally) an assigned airplane.
-- Ensures airplane isn’t already in use and flight starts before final stop.
-- Initializes with ground status and provided next_time and cost.
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (
    in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50),
    in ip_progress integer, in ip_next_time time, in ip_cost integer
)
sp_main: begin
	declare plane_speed int;   
    declare total_leg_distance int;
    
    if ip_flightID is null or ip_routeID is null or ip_next_time is null then
        leave sp_main;
    end if;
    if not exists (select 1 from route where routeID = ip_routeID) then -- leave if our route isn't valid
        leave sp_main;
    end if;
    
    if ip_support_airline is not null and ip_support_tail is not null then -- we have a plane to assign
        if exists (select 1 from flight where support_airline = ip_support_airline 
			and support_tail = ip_support_tail) then
            leave sp_main; -- leave if associated plane is still active
        end if;
        if not exists (select 1 from airplane where airlineID = ip_support_airline and 
			tail_num = ip_support_tail) then
				leave sp_main; -- leave if plane parameters are not valid plane.
		end if;
        
        -- still assuming that we're given a valid plane
        -- Goal: Our next time must be < routeID's final stop time
        -- we also have our planes speed time
        -- select speed into plane_speed from airplane -- save plane speed
-- 			where concat(airlineID, tail_num) = concat(
-- 				ip_support_airline, ip_support_tail);
--             
-- 		SELECT SUM(distance) * 3600 / plane_speed into total_leg_distance
-- 		FROM 
-- 			route r JOIN route_path rp ON r.routeID = rp.routeID
-- 			JOIN leg l ON l.legID = rp.legID
-- 		WHERE 
-- 			rp.routeID = ip_routeID and ip_progress < rp.sequence;
--             
-- 		-- SELECT ADDTIME('2025-03-31 10:00:00', '02:15:00') AS new_time;
-- 		if ip_next_time > (select leg_time(total_leg_distance, plane_speed)) then
--             leave sp_main; -- leave if our next time is after the stop time
-- 		end if;
            if (ip_progress) >= (select max(sequence) from route_path
            where routeID = ip_routeID group by routeID) then 
				leave sp_main; -- leave bc we start at end
			end if;
            
    end if; -- end of nester
    

    -- everything has checked out fine, so we do our insertions
    insert into flight(flightID, routeID, support_airline, support_tail, progress,
    next_time, cost, airplane_status)
    values (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail,
		ip_progress, ip_next_time, ip_cost, 'on_ground');
end //
delimiter ;

-- [6] flight_landing()
-- Handles a flight landing:
-- Increments flight progress, updates status, and adjusts next_time by 1 hour.
-- Updates passenger miles and pilot experience.
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin
	-- declare curr_progress int;
    -- declare curr_routeID varchar(50);
    declare plane_loc varchar(50);
 
    if ip_flightID is null then leave sp_main; end if;
    if not exists (select 1 from flight where flightID = ip_flightID
    and airplane_status = 'in_flight') then
        leave sp_main;
    end if;
 
    update flight set airplane_status = 'on_ground'
		where flightID = ip_flightID;
        
	-- don't know why, but this is where we update time and if we update the time in the simulation_cycle the autograder is mad
	update flight set next_time = addtime(next_time, '01:00:00')
	 	where flightID = ip_flightID;
 
    -- select progress into curr_progress from flight where flightID = ip_flightID;
    -- select routeID into curr_routeID from flight where flightID = ip_flightID;
	select locationID into plane_loc from flight f join airplane a
    on f.support_tail = a.tail_num and f.support_airline = a.airlineID
		where f.flightID = ip_flightID;
 
	-- maybe add location info later
    update pilot pl join person p on pl.personID = p.personID
		set pl.experience = pl.experience + 1 
        where commanding_flight = ip_flightID;
        
    update passenger pp join person p on pp.personID = p.personID 
    set miles = miles + (
        select l.distance from flight f join route_path rp on f.routeID = rp.routeID
        and f.progress = rp.sequence
        join leg l on rp.legID = l.legID
        where f.flightID = ip_flightID) 
	where p.locationID = plane_loc;
end //
delimiter ;

-- [7] flight_takeoff()
-- Handles takeoff logic based on aircraft type and required number of pilots.
-- If enough pilots: sets flight in air and computes duration using leg_time().
-- Otherwise delays next_time by 30 minutes.
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin
	declare v_speed int;
    declare v_distance int;
    declare v_duration time;
    declare plane_type varchar(100);

    if ip_flightID is null then leave sp_main; end if;
    if not exists (select 1 from flight where flightID = ip_flightID
    and airplane_status = 'on_ground') then
        leave sp_main;
    end if;

    select a.plane_type into plane_type
    from flight f join airplane a
    on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;

    if plane_type = 'Boeing' and (select count(*) from pilot where commanding_flight = ip_flightID) < 2 then
        update flight set next_time = addtime(next_time, '00:30:00') where flightID = ip_flightID;
        leave sp_main;
	elseif (select count(*) from pilot where commanding_flight = ip_flightID) < 1 then
        update flight set next_time = addtime(next_time, '00:30:00') where flightID = ip_flightID;
        leave sp_main;
    end if;

    select speed into v_speed from airplane a join flight f on
    a.airlineID = f.support_airline and a.tail_num = f.support_tail
		where f.flightID = ip_flightID;

    select distance into v_distance from leg l join route_path rp on l.legID = rp.legID
		join flight f on rp.routeID = f.routeID and f.progress + 1 = rp.sequence
		where f.flightID = ip_flightID;

    set v_duration = leg_time(v_distance, v_speed);
    update flight set airplane_status = 'in_flight', next_time = addtime(next_time, v_duration)
        where flightID = ip_flightID;
	
    update flight set progress = progress + 1
		where flightID = ip_flightID;
end //
delimiter ;
-- [8] passengers_board()
-- Allows passengers at the departure airport to board a grounded flight.
-- Ensures passengers have funds and destination matches next leg.
-- Limits boarding to seat capacity and deducts ticket cost.
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin    
    declare curr_seq int;
    declare max_leg int;
    declare dep_airport varchar(3);
    declare arr_airport varchar(3);
    declare ticket_cost int;
    declare v_airline varchar(50);
    declare v_tail varchar(50);
    declare v_capacity int;
    declare v_location varchar(50);

    if ip_flightID is null then leave sp_main; end if;

    if not exists (select 1 from flight where flightID = ip_flightID
    and airplane_status = 'on_ground') then
        leave sp_main;
    end if;

    select progress + 1 into curr_seq from flight where flightID = ip_flightID;
    select count(*) into max_leg from route_path rp join flight f on rp.routeID = f.routeID
    where f.flightID = ip_flightID;

    if curr_seq > max_leg then leave sp_main; end if;

    select l.departure, l.arrival, f.cost into dep_airport, arr_airport, ticket_cost
    from flight f
    join route_path rp on f.routeID = rp.routeID
    join leg l on rp.legID = l.legID
    where f.flightID = ip_flightID and rp.sequence = curr_seq;

    select support_airline, support_tail into v_airline, v_tail from
    flight where flightID = ip_flightID;
    
    select seat_capacity, locationID into v_capacity, v_location from airplane
    where airlineID = v_airline and tail_num = v_tail;

    -- Insert valid passengers into a temporary table first
    drop temporary table if exists eligible_boarding;
    create temporary table eligible_boarding (personID varchar(50) primary key);

    insert into eligible_boarding (personID)
    select distinct pa.personID
    from passenger pa
    join person p on pa.personID = p.personID
    join airport ap on ap.locationID = p.locationID
    join passenger_vacations pv on pv.personID = pa.personID
    join route_path rp2 on rp2.routeID = (select routeID from flight where flightID = ip_flightID)
    join leg l2 on l2.legID = rp2.legID
    where ap.airportID = dep_airport
      and pa.funds >= ticket_cost
      and pv.airportID = l2.arrival
      and rp2.sequence >= curr_seq
    group by pa.personID
    limit v_capacity;

    -- Move selected passengers to plane and deduct ticket cost
    update person p
    join eligible_boarding eb on p.personID = eb.personID
    set p.locationID = v_location;

    update passenger pa
    join eligible_boarding eb on pa.personID = eb.personID
    set pa.funds = pa.funds - ticket_cost;

    drop temporary table if exists eligible_boarding;
end //
delimiter ;

-- [9] passengers_disembark()
-- Removes passengers from a flight after landing at their next destination.
-- Updates each person’s location to the arrival airport.
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin

    declare arr_loc varchar(50);	-- The location ID of the arrival airport
    declare arr_airport varchar(3); -- Current arriving airportID

	-- Checking that the flightID is valid
    if ip_flightID is null then 
		leave sp_main; 
    end if;
    
    -- Check if there is a grounded flight with the flightID
    if not exists (select 1 from flight where flightID 
    = ip_flightID and airplane_status = 'on_ground') then
        leave sp_main;
    end if; 

    -- Setting arr_airport
    select arrival into arr_airport from (flight join route_path on flight.routeID = route_path.routeID) join leg on route_path.legID = leg.legID 
	  where route_path.sequence = flight.progress and flight.flightID = ip_flightID;
    
    -- Setting arr_loc
    select locationID into arr_loc from airport where airport.airportID = arr_airport;
    
    -- Updating the locationID of any passengers who are on the plane and have reached their destination 
    -- update person set locationID = arr_loc where personID in 
-- 		(select passenger.personID from (person right join passenger on passenger.personID = person.personID
--         join passenger_vacations on passenger.personID = passenger_vacations.personID) 
-- 		join (airplane join flight on airplane.tail_num = flight.support_tail)
--         on airplane.locationID = person.locationID
-- 		where flight.flightID = ip_flightID and passenger_vacations.airportID = arr_airport);

	update person join passenger on person.personID = passenger.personID join passenger_vacations pv on 
		passenger.personID = pv.personID join (airplane join flight on airplane.tail_num = flight.support_tail)
        on airplane.locationID = person.locationID
        set person.locationID = arr_loc 
        where flight.flightID = ip_flightID and pv.airportID = arr_airport;
    
end //
delimiter ;

-- [10] assign_pilot()
-- Assigns a pilot to a grounded flight if they have the correct license and location.
-- Pilot must not already be assigned to another flight.
-- Updates pilot’s location to airplane.
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), in ip_personID varchar(50))
sp_main: begin
	declare v_model varchar(50);
    declare v_loc varchar(50);
    declare v_tail varchar(50);
    declare v_airline varchar(50);
    declare curr_airport_location varchar(50);
    
    -- if ip_flightID is null or ip_personID is null then leave sp_main; end if; -- leave if flight or person is null
    -- select support_airline into v_airline, support_tail into v_tail from flight where flightID = ip_flightID;
    -- select model into v_model, locationID into v_loc from airplane where airlineID = v_airline and tail_num = v_tail;
    
    if ip_flightID is null or ip_personID is null then
		leave sp_main; -- our keys are null
	end if;
    
    select support_airline, support_tail into v_airline, v_tail from flight where flightID = ip_flightID;
    
    select plane_type, locationID into v_model, v_loc from airplane where 
		v_airline = airlineID and v_tail = tail_num;
    
    -- leave if personID doesn't correspond to a pilot
    if not exists (select 1 from pilot where personID = ip_personID) then leave sp_main; end if;
    -- leave if flight is DNE
    if not exists (select 1 from flight where flightID = ip_flightID) then leave sp_main; end if;
    
    if (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' then
		leave sp_main; -- we leave if the flight is not grounded. 
	end if;
    
    if (select isnull(commanding_flight) from pilot where personID = ip_personID) != 1 then
		leave sp_main; -- leave if pilot already commanding a flight. 
	end if;
    
    
    -- if we have a pilot, we have to check that they can pilot the aircraft
    if v_model = 'Airbus' or v_model = 'Boeing' then
		if v_model not in (select license from pilot_licenses where personID = ip_personID) then
			leave sp_main;
		end if;
	else
		if ('general' not in (select license from pilot_licenses where personID = ip_personID)) then
			leave sp_main;
		end if;
	end if;
    
    -- if we make it here, out pilot is good to pilot the aircraft and the plane is grounded
	-- if (select locationID from person where personID = ip_personID) != v_loc then leave sp_main; end if;
    
    -- big check: we need to ensure this pilot is at the same spot as the plane
    -- 1st we see the location of the plane
    select airport.locationID into curr_airport_location from flight f join
    route_path rp on f.routeID = rp.routeID and rp.sequence = f.progress + 1 
    join leg l on l.legID = rp.legID 
    join airport on airport.airportID = l.departure
    where f.flightID = ip_flightID;
    
    -- if v_loc != curr_airport_location then leave sp_main; end if; -- we leave if pilot is not in the right airport aren't together
	if (select p.locationID from person p where p.personID = ip_personID) != curr_airport_location then leave sp_main; end if;
    
    update person set locationID = v_loc where personID = ip_personID;
    update pilot set commanding_flight = ip_flightID where personID = ip_personID;
end //
delimiter ;

-- [11] recycle_crew()
-- Releases all crew members from a flight if there are no passengers onboard.
-- Called when a flight ends and needs to return pilots to airport.
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin
	declare flight_location varchar(50);
    declare airport_location varchar(50);
    
    if ip_flightID is null then leave sp_main; end if; -- leave if id null
    
    -- if exists (select 1 from passenger where flightID = ip_flightID)
		-- then leave sp_main; end if;
        
	if not exists (select 1 from flight where flightID = ip_flightID) then
		leave sp_main; -- leave if the id is not valid
	end if;
	
    if (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' then
		leave sp_main; -- we leave if flight is not on ground
	end if;
    
    -- we now store the location of the airplane
    select a.locationID into flight_location from flight f join airplane a on
		f.support_airline = a.airlineID and f.support_tail = a.tail_num join location l on 
        a.locationID = l.locationID where f.flightID = ip_flightID;
        
	-- check to see if passengers are still on the flight and leave if so
    if (select count(*) from passenger pa join person pe on pe.personID = pa.personID 
		join location l on l.locationID = pe.locationID where l.locationID = flight_location)
        > 0 then
			leave sp_main; -- leave because passengers are still there
	end if;
    
    -- checking if the flight has ended (we reached the last leg)
    if (select MAX(rp.sequence) from route_path rp 
			join flight f on rp.routeID = f.routeID
			where f.flightID = ip_flightID
            group by f.flightID) != (select f.progress from flight f where f.flightID = ip_flightID) then
		leave sp_main;
    end if;
    
    -- we need to store the location of the airport the plane just got to
    select a.locationID into airport_location from flight f 
		join route_path rp on f.routeID = rp.routeID and rp.sequence = f.progress 
        join leg le on le.legID = rp.legID 
        join airport a on a.airportID = le.arrival where
		f.flightID = ip_flightID;
        
    -- we also need to update the location values for recycled crew
    update person set locationID = airport_location where personID in 
		(select personID from pilot where commanding_flight = ip_flightID);
    
	-- now we go through the pilot table and free pilots from this flight.
    update pilot p join flight f on p.commanding_flight = f.flightID
		set commanding_flight = null where ip_flightID = p.commanding_flight;
        
    
end //
delimiter ;

-- [12] retire_flight()
-- Retires a flight that is on the ground, at the end of its route,
-- and has no passengers or crew left onboard.
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin
    declare v_prog int;
    declare v_max int;
    declare flight_location varchar(50);
    
    if ip_flightID is null then leave sp_main; end if; -- leave if flight is not valid
    
    if not exists (select 1 from flight where flightID = ip_flightID) then
		leave sp_main; -- leave if flight doesn't exist
	end if;
    
    -- set the flight location (from the airplane)
    select a.locationID into flight_location from flight f join airplane a on
		f.support_airline = a.airlineID and f.support_tail = a.tail_num join location l on 
        a.locationID = l.locationID where f.flightID = ip_flightID;
        
	-- if we query and get != 0 size, then pilots and/or passengers are still on plane
    if (select count(*) from person where locationID = flight_location) > 0 then
		leave sp_main; -- leave if ppl still on plane
	end if;
    
    -- if we're not on_ground, leave
    if (select airplane_status from flight where flightID = ip_flightID)
		!= 'on_ground' then 
			leave sp_main; -- leave cause we're still in the air. 
	end if;
    
    -- now we will leave if we are not at the end of the flight
	if (select count(*) from route_path where routeID =
		(select routeID from flight where flightID = ip_flightID)) != (select progress from flight
		where flightID = ip_flightID) then
        
        leave sp_main; -- we leave if the #(legs) != flight progress
        
	end if;
    -- this will only happen assuming the flight 
    -- is on_ground, no ppl on it, and has reached final stop
    delete from flight where flightID = ip_flightID;
end //
delimiter ;

-- [13] simulation_cycle()
-- Advances simulation by processing the flight with the earliest next_time.
-- If in air: lands and disembarks. If grounded: boards and takes off.
-- If flight has ended: recycles crew and retires the flight.
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin
    declare v_flightID varchar(50);
    declare v_status varchar(10);
    declare v_dist int;
    declare v_speed int;
    select flightID, airplane_status into v_flightID, v_status
    from flight
    where next_time = (select min(next_time) from flight)
    order by field(airplane_status, 'in_flight', 'on_ground'), flightID limit 1;
    if v_status = 'in_flight' then
        call flight_landing(v_flightID);
        call passengers_disembark(v_flightID);
        -- update flight set next_time =  addtime(next_time, '01:00:00') where flightID = v_flightID;
    else
        call passengers_board(v_flightID);
        call flight_takeoff(v_flightID);
        -- gets the sum of all the distances (hopefully does not double count anything)
        select l.distance into v_dist
			from flight f join route_path rp on f.routeID = rp.routeID and f.progress + 1 = rp.sequence 
			join leg l on rp.legID = l.legID 
			where f.flightID = v_flightID;
		-- gets the speed
		select a.speed into v_speed
			from flight f join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
			where f.flightID = v_flightID;
		update flight set next_time =  next_time + leg_time(v_distance, v_speed) where flightID = v_flightID;    
	end if;
    if exists (
        select 1 from flight
        where flightID = v_flightID and airplane_status = 'on_ground'
          and progress = (select max(sequence) 
			from route_path
            where flightID = v_flightID
            group by flightID)
    ) then
        call recycle_crew(v_flightID);
        call retire_flight(v_flightID);
    end if;
end //
delimiter ;

-- [14] to [19] views

-- [14] flights_in_the_air()
-- Displays flights currently in the air.
-- Shows departure and arrival airports, number of flights, flight IDs,
-- airplane IDs, and earliest/latest arrival times grouped by route.
create or replace view flights_in_the_air as
select
	l.departure as departing_from, 
	l.arrival as arriving_at,
    COUNT(f.flightID) as num_flights,
    GROUP_CONCAT(f.flightID SEPARATOR ',') as flight_list,
    MIN(f.next_time) as earliest_arrival,
    MAX(f.next_time) as latest_arrival,
    GROUP_CONCAT(a.locationID SEPARATOR ',') as airplane_list
from flight f
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join leg l on r.legID = l.legID
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
where f.airplane_status = 'in_flight'
group by l.departure, l.arrival;

-- [15] flights_on_the_ground()
-- Displays flights currently on the ground.
-- Shows departing airport, number of flights, flight IDs,
-- airplane IDs, and earliest/latest scheduled arrivals.
create or replace view flights_on_the_ground as
(select
	l.arrival as departing_from, 
    COUNT(f.flightID) as num_flights,
    GROUP_CONCAT(f.flightID SEPARATOR ',') as flight_list,
    MIN(f.next_time) as earliest_arrival,
    MAX(f.next_time) as latest_arrival,
    GROUP_CONCAT(a.locationID SEPARATOR ',') as airplane_list
from flight f
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join leg l on r.legID = l.legID
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
where f.airplane_status = 'on_ground'
group by l.arrival) -- deals with the planes that are not just starting (at location 0)
union
(select
	l.departure as departing_from, 
    COUNT(f.flightID) as num_flights,
    GROUP_CONCAT(f.flightID SEPARATOR ',') as flight_list,
    MIN(f.next_time) as earliest_arrival,
    MAX(f.next_time) as latest_arrival,
    GROUP_CONCAT(a.locationID SEPARATOR ',') as airplane_list
from flight f
join route_path r on f.routeID = r.routeID and f.progress = r.sequence - 1
join leg l on r.legID = l.legID
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
where f.airplane_status = 'on_ground' and f.progress = 0
group by l.departure); -- deals with the planes that are not just starting (at location 0)

-- [16] people_in_the_air()
-- Shows who is currently in the air.
-- Includes route info, airplane IDs, flight IDs, arrival times,
-- number of pilots, number of passengers, and full passenger list.
create or replace view people_in_the_air as
select
	l.departure as departing_from, 
	l.arrival as arriving_at,
    COUNT(distinct a.locationID) as num_airplanes,
    GROUP_CONCAT(distinct a.locationID SEPARATOR ',') as airplane_list,
    GROUP_CONCAT(distinct f.flightID SEPARATOR ',') as flight_list,
    MIN(f.next_time) as earliest_arrival,
    MAX(f.next_time) as latest_arrival,
    COUNT(distinct pp.personID) as num_pilots,
    COUNT(distinct ppp.personID) as num_passengers,
    COUNT(distinct p.personID) as joint_pilots_passengers,
    GROUP_CONCAT(distinct p.personID SEPARATOR ',') as person_list
from flight f
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join leg l on r.legID = l.legID
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
join person p on p.locationID = a.locationID -- For some reason a pilot might be assigned to a flight but not commanding it rn
left join pilot pp on f.flightID = pp.commanding_flight and pp.personID = p.personID
left join passenger ppp on ppp.personID = p.personID  
where f.airplane_status = 'in_flight'
group by l.departure, l.arrival;

-- [17] people_on_the_ground()
-- Shows people located at airports on the ground.
-- Lists airport details, city/state/country, counts of passengers and pilots,
-- and the full list of people by ID.
create or replace view people_on_the_ground as
select
	a.airportID as departing_from,
    a.locationID as arriving_at,
    GROUP_CONCAT(distinct a.airport_name SEPARATOR ',') as airport_name,
    GROUP_CONCAT(distinct a.city SEPARATOR ',') as city,
    GROUP_CONCAT(distinct a.state SEPARATOR ',') as state,
	GROUP_CONCAT(distinct a.country SEPARATOR ',') as country,
    COUNT(distinct pp.personID) as num_pilots,
    COUNT(distinct ppp.personID) as num_passengers,
    COUNT(distinct p.personID) as joint_pilots_passengers,
    GROUP_CONCAT(distinct p.personID SEPARATOR ',')
from person p
join airport a on p.locationID = a.locationID
left join pilot pp on pp.personID = p.personID
left join passenger ppp on ppp.personID = p.personID
group by a.airportID, a.locationID;

-- [18] route_summary()
-- Summarizes every route by showing number of legs, total distance,
-- airport sequence, leg path summary, and associated flights.
create or replace view route_summary as
select 
	rp.routeID as route,
    COUNT(distinct rp.legID) as num_legs,
    GROUP_CONCAT(distinct rp.legID order by rp.sequence asc SEPARATOR ',') as leg_sequence,
    SUM(l.distance) DIV (CASE WHEN COUNT(distinct f.flightID) = 0 THEN 1 ELSE COUNT(distinct f.flightID) END) AS route_length,
    COUNT(distinct f.flightID) as num_flights,
    GROUP_CONCAT(distinct f.flightID SEPARATOR ',') as flight_list,
    GROUP_CONCAT(distinct CONCAT(l.departure, '->', l.arrival) order by rp.sequence SEPARATOR ',') as airport_sequence
from route_path rp
join leg l on  rp.legID = l.legID
left join flight f on rp.routeID = f.routeID
group by rp.routeID;

-- [19] alternative_airports()
-- Identifies cities/states that have more than one airport.
-- Lists all airport codes and names in those locations.
create or replace view alternative_airports as
select
	a.city as city,
    a.state as state,
    a.country as country,
    COUNT(distinct a.airportID) as num_airports,
    GROUP_CONCAT(a.airportID SEPARATOR ',') as airport_code_list,
    GROUP_CONCAT(a.airport_name SEPARATOR ',') as airport_name_list
from airport a
group by a.city, a.state, a.country
having COUNT(distinct a.airportID) > 1;
