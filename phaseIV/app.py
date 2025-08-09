from flask import Flask, render_template, request, redirect, url_for
from db_utils import query_view, call_procedure
import os

app = Flask(__name__, template_folder='templates')

@app.route("/")
def index():
    return render_template("index.html")

# Renders static pages
@app.route('/page/<page_name>')
def render_static_page(page_name):

    # First, try to render as a procedure
    procedure_path = os.path.join('procedures', f"{page_name}.html")
    if os.path.exists(os.path.join(app.template_folder or 'templates', procedure_path)):
        print("debug: trying to load", os.path.join(app.template_folder, 'procedures', f"{page_name}.html"))
        return render_template(procedure_path)

    # Otherwise, try to render as a view
    view_path = os.path.join('views', f"{page_name}.html")
    if os.path.exists(os.path.join(app.template_folder or 'templates', view_path)):
        return render_template(view_path)

    # If neither exists, return 404
    return f"<h2>Page '{page_name}' Not Found</h2>", 404

### 
# 
# Here are all of the methods for submitting
# 
### 

# Add Airplane Procedure
@app.route("/submit_add_airplane", methods=['POST'])
def submit_add_airplane():
    try:
        speed = request.form['speed']
        maintained = request.form['maintained'] or None
        airlineId = request.form['airlineId']
        neo = 1 if 'neo' in request.form else 0
        tailNum = request.form['tailNum']
        locationId = request.form['locationId']
        model = request.form['model'] or None
        seatCap = request.form['seatCap']
        planeType = request.form['planeType']

        call_procedure('add_airplane', [
            speed, maintained, airlineId, neo,
            tailNum, locationId, model, seatCap, planeType
        ])

        return redirect(url_for('index'))

    except Exception as e:
        return render_template('procedures/add_airplane.html', error=str(e))

# Add Person Procedure
@app.route("/submit_add_person", methods=['POST'])
def submit_add_person():
    try:
        # Read form fields exactly as named
        locationId = request.form['locationId']
        miles = request.form['miles']
        personId = request.form['personId']
        firstName = request.form['firstName']
        taxId = request.form['taxId']
        funds = request.form['funds']
        lastName = request.form['lastName']
        experience = request.form['experience']

        # Call your stored procedure
        call_procedure('add_person', [
            locationId, miles, personId, firstName,
            taxId, funds, lastName, experience
        ])

        # Redirect to home page after successful submit
        return redirect(url_for('index'))

    except Exception as e:
        # If an error happens, show the error on the form page
        return render_template('procedures/add_person.html', error=str(e))

# Assign Pilot Procedure
@app.route("/submit_assign_pilot", methods=['POST'])
def submit_assign_pilot():
    try:
        personId = request.form['personId']
        pilotType = request.form['pilotType']
        certificationLevel = request.form['certificationLevel']
        certificationExpiration = request.form['certificationExpiration']

        call_procedure('assign_pilot', [
            personId, pilotType, certificationLevel, certificationExpiration
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/assign_pilot.html', error=str(e))

# Flight Landing Procedure
@app.route("/submit_flight_landing", methods=['POST'])
def submit_flight_landing():
    try:
        flightId = request.form['flightId']
        arrivingAirportId = request.form['arrivingAirportId']

        call_procedure('flight_landing', [
            flightId, arrivingAirportId
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/flight_landing.html', error=str(e))

# Flight Takeoff Procedure
@app.route("/submit_flight_takeoff", methods=['POST'])
def submit_flight_takeoff():
    try:
        flightId = request.form['flightId']
        departingAirportId = request.form['departingAirportId']

        call_procedure('flight_takeoff', [
            flightId, departingAirportId
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/flight_takeoff.html', error=str(e))

# Grant or revoke pilot license Procedure
@app.route("/submit_grant_revoke_pilot", methods=['POST'])
def submit_grant_revoke_pilot():
    try:
        personId = request.form['personId']
        grantOrRevoke = request.form['grantOrRevoke']

        call_procedure('grant_or_revoke_pilot_license', [
            personId, grantOrRevoke
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/grant_or_revoke_pilot_license.html', error=str(e))

# offer flight Procedure
@app.route("/submit_offer_flight", methods=['POST'])
def submit_offer_flight():
    try:
        airlineId = request.form['airlineId']
        flightNumber = request.form['flightNumber']
        departureLocationId = request.form['departureLocationId']
        arrivalLocationId = request.form['arrivalLocationId']
        scheduledDepartureTime = request.form['scheduledDepartureTime']
        scheduledArrivalTime = request.form['scheduledArrivalTime']
        flightDurationMinutes = request.form['flightDurationMinutes']
        flightStatus = request.form['flightStatus']
        seatPrice = request.form['seatPrice']

        call_procedure('offer_flight', [
            airlineId, flightNumber, departureLocationId, arrivalLocationId,
            scheduledDepartureTime, scheduledArrivalTime,
            flightDurationMinutes, flightStatus, seatPrice
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/offer_flight.html', error=str(e))

# passengers board Procedure
@app.route("/submit_passengers_board", methods=['POST'])
def submit_passengers_board():
    try:
        flightId = request.form['flightId']
        passengerId = request.form['passengerId']

        call_procedure('passengers_board', [
            flightId, passengerId
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/passengers_board.html', error=str(e))

# passengers disembark Procedure
@app.route("/submit_passengers_disembark", methods=['POST'])
def submit_passengers_disembark():
    try:
        flightId = request.form['flightId']
        passengerId = request.form['passengerId']

        call_procedure('passengers_disembark', [
            flightId, passengerId
        ])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/passengers_disembark.html', error=str(e))

# recycle crew Procedure
@app.route("/submit_recycle_crew", methods=['POST'])
def submit_recycle_crew():
    try:
        flightId = request.form['flightId']

        call_procedure('recycle_crew', [flightId])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/recycle_crew.html', error=str(e))

# retire flight Procedure
@app.route("/submit_retire_flight", methods=['POST'])
def submit_retire_flight():
    try:
        flightId = request.form['flightId']

        call_procedure('retire_flight', [flightId])

        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/retire_flight.html', error=str(e))

# simulation cycle Procedure
@app.route("/submit_simulation_cycle", methods=['POST'])
def submit_simulation_cycle():
    try:
        call_procedure('simulation_cycle', [])
        return redirect(url_for('index'))
    except Exception as e:
        return render_template('procedures/simulation_cycle.html', error=str(e))

### 
# 
# The Views will be down here 
# 
###

# To-Do:
# - Properly format the JSON files so that they can be 

@app.route('/view/flights-in-air')
def flights_in_air():
    return query_view("flights_in_the_air")

@app.route('/view/flights-on-ground')
def flights_on_the_ground():
    return query_view("flights_on_the_ground")

@app.route('/view/people-in-air')
def people_in_the_air():
    return query_view("people_in_the_air")

@app.route('/view/people-on-ground')
def people_on_the_ground():
    return query_view("people_on_the_ground")

@app.route('/view/route-summary')
def route_summary():
    return query_view("route_summary")

@app.route('/view/alternative-airports')
def alternative_airports():
    return query_view("alternative_airports")
