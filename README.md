# Airlines Blockchain Project

## Contracts

### Airline

#### Variables:

`FlightStatus` :: Enum of Flight Status
* `SCHEDULED` = Default status when a new flight is added. This can change into one of 3 following status codes.
* `ONTIME` = Flight departed on time.
* `DELAYED` = Flight departed with delay.
* `CANCELLED` = Flight cancelled.

`FlightData` :: A grouping of information of a single flight.
* `estimated_departiure` = An EPOCH of when the flight is scheduled to depart. Defined during flight creation.
* `actual_departure` = Default 0. An EPOCH of when the flight actually departed. Updated when the flight status changes from SCHEDULED to any other status.
* `no_of_seats` = Number of seats available to book in the plane.
* `seat_price` = Price of each seat in the plane.
* `status` = The current `FlightStatus` value of the flight.

`TicketData` :: A grouping of Ticket information booked for a flight.
* `customer_address` = Address of the customer that booked the ticket.
* `flight_name` = Name of the flight the ticket is booked for.
* `no_of_seats` = Number of seats the customer booked.

`_admin` :: Address of the Airline Admin (contract creator).

`_flights` :: List of created flight names.

`_tickets` :: List of created ticket addresses.

`_flight_info` :: Mapping of the flight name to `FlightData` struct.

`_ticket_info` :: Mapping of created ticket address to `TicketData` struct.

#### Modifiers:

`is_admin` :: Validates whether caller is the Airline admin.

`is_not_admin` :: Validates whether caller is not the Airline admin.

`is_ticket_owner` :: Validates whether the caller is the owner of the ticket (Ticket contract creator).

`valid_add_flight_inputs` :: Validates inputs provided during flight creation.
* Flight Name - Should not already exist.
* Estimated Departure - Should be greater than zero.
* Number of Seats - Should be greater than zero.
* Seat Price - Should be greater than zero.

`valid_flight_name` :: Validates whether a flight name is pre-existing.

`valid_booking_inputs` :: Validates inputs provided during ticket booking.
* Number of Seats - Should be non-zero
* Number of Seats - Should be available for booking in the flight
* Amount Transfferred - Should match the required amount for purchasing the ticket.

`valid_ticket` :: Validates whether a ticket address is pre-existing.

`valid_flight_state_for_booking` :: Validates the flight being booked is in SCHEDULED state.

`request_2_hours_before_departure` :: Validates the request is happening 2 hours before the flight estimated departure time.

`request_24_hours_after_departure` :: Validates the request is happening 24 hours after the flight actual departure time. Estimated time is considered if acutal is not available (Cancelled flight or flight with unchanged scheduled status).

#### Methods:

`add_flight` ::
* Admin only access.
* Adds data to `_flights` and `_flight_info`.

`update_flight_departure` ::
* Admin only access.
* Updates `actual_departure` and `status` in the `_flight_info` of a particular flight.

`update_flight_seats` ::
* Admin only access.
* Internal function to increase/decrease the number of available seats in `_flight_info` for a particular flight during cancellation/booking respectively.

`get_flights` :: Getter for the `_flights` list.

`get_tickets` :: Getter for the `_tickets_` list.

`get_flight_info` :: Returns the `_flight_info` for a particular flight.

`book_ticket` ::
* Customer only access.
* Payable function, where customer provides a fee for booking flight tickets.
* Deploys a Ticket contract and transfers the ETH supplied by customer by calling the `pay` method within the deployed contract.
* Adds data to `_tickets` and `_ticket_info`.
* Calls `update_flight_seats` to reduce total available tickets from `_flight_info`.
* Returns the deployed ticket contract address.

`cancel_ticket` ::
* Customer only access.
* Calls the `cancellation` method in the deployed ticket contract.
* On success, calls `update_flight_seats` to increase total available tickets in `_flight_info`.

`claim_ticket` ::
* Customer only access.
* Calls the `claim` method in the deployed ticket contract, and passes the `FlightStatus` as an input.

### Ticket

#### Variables:

`TicketStatus` :: Enum of Ticket Status
* `BOOKED` = Ticket created bu customer. Default status when ticket contract is created.
* `PAID` = Ticket paid for by customer.
* `CANCELLED` = Ticket is cancelled by customer.
* `CLAIMED` = Ticket is claimed by customer.

`FlightStatus` :: Enum of Flight Status
* `SCHEDULED` = Default status when a new flight is added. This can change into one of 3 following status codes.
* `ONTIME` = Flight departed on time.
* `DELAYED` = Flight departed with delay.
* `CANCELLED` = Flight cancelled.

`_parent_contract` :: Address of the parent contract (contract creator).

`_flight_name` :: Name of the flight.

`_customer_address` :: Address of the customer.

`_airline_address` :: Address of the Airline Admin.

`_status` :: The current `TicketStatus` value of the ticket.

`_no_of_seats` :: Number of seats booked by the ticket.

`_seat_price` :: Price of each seat.

`_total_amount_payable` :: Total price payable by customer ( `_no_of_seats` x `_seat_price` ).

`_flight_delay_penalty_percentage` :: Percentage of penalty to the airline in case of flight delay. This percentage of paid amount can be claimed by the customer.

`_ticket_cancellation_penalty_percentage` :: Percentage of penalty to the customer in case they cancel their ticket. This percentage of paid amount goes to the airline, when the customer gets the rest.

#### Modifiers:

`is_parent_contract` :: Validates if the requestor is the `_parent_contract`.

`validate_payment` :: Validates if ticket has not been paid for yet.

`validate_cancellation` :: Validates inputs provided during ticket cancellation.

`validate_claim` :: Validates inputs provided during ticket claim.

#### Methods:

`pay` :: Transitions the ticket status to PAID.

`cancellation` ::
* Transfers part of the amount to the airline, as specified by the `_ticket_cancellation_penalty_percentage` setting.
* Remaining amount is transferred to the customer as refund.
* Transitions the ticket status to CANCELLED.

`claim` ::
* If flight is DELAYED, transfers part of the amount to the customer, as specified by the `_flight_delay_penalty_percentage` setting. Remaining amount goes to the airline.
* If flight is CANCELLED or still in SCHEDULED state (unchanged status by airline admin), the the whole amount is refunded to the customer.
* Transitions the ticket status to CLAIMED.
