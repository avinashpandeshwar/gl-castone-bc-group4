// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ticket.sol";

contract Airline {

    enum FlightStatus {SCHEDULED, ONTIME, DELAYED, CANCELLED}

    struct FlightData {
        uint estimated_departure;
        uint actual_departure;
        uint no_of_seats;
        uint seat_price;
        FlightStatus status;
    }

    struct TicketData {
        string flight_name;
        uint no_of_seats;
    }

    mapping(address => TicketData) internal _tickets;

    address private admin;
    string[] internal _flights;
    mapping(string => FlightData) internal _flight_info;

    modifier is_admin() {
        require(msg.sender == admin, "Action not permitted for non-Admin users.");
        _;
    }

    modifier valid_booking_inputs(address _addr, string memory _flight_name, uint _no_of_seats) {
        require(_addr != admin, "Seat booking not permitted for Admin users.");
        require(_flight_info[_flight_name].estimated_departure != 0, "Invalid flight name.");
        require(_no_of_seats > 0, "Can not book 0 seats.");
        require(_flight_info[_flight_name].no_of_seats >= _no_of_seats,"Specified number of seats not available.");
        _;
    }

    modifier valid_ticket(address _addr) {
        require(_tickets[_addr].no_of_seats > 0, "Specified ticket address does not exist.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function add_flight(string memory _flight_name, uint _estimated_departure, uint _no_of_seats, uint _seat_price) public is_admin {
        
        FlightData memory _flight_data = FlightData({
            estimated_departure: _estimated_departure,
            actual_departure: 0,
            no_of_seats: _no_of_seats,
            seat_price: _seat_price,
            status: FlightStatus.SCHEDULED
        });

        _flight_info[_flight_name] = _flight_data;
        _flights.push(_flight_name);
    }

    function update_flight_departure(string memory _flight_name, uint _actual_departure, FlightStatus _status) public is_admin {
        _flight_info[_flight_name].actual_departure = _actual_departure;
        _flight_info[_flight_name].status = _status;
    }

    function increment_flight_seats(string memory _flight_name, uint value) internal {
        _flight_info[_flight_name].no_of_seats = _flight_info[_flight_name].no_of_seats + value;
    }

    function decrement_flight_seats(string memory _flight_name, uint value) internal {
        _flight_info[_flight_name].no_of_seats = _flight_info[_flight_name].no_of_seats - value;
    }

    function get_flights() external view returns(string[] memory) {
        return _flights;
    }

    function get_flight_info(string memory _flight_name) external view returns(FlightData memory) {
        return _flight_info[_flight_name];
    }

    function book_ticket(address _customer, string memory _flight_name, uint _no_of_seats) external valid_booking_inputs(_customer, _flight_name, _no_of_seats) returns(address) {
        
        // Calculate total price for ticket
        uint _amount_payable = _no_of_seats * _flight_info[_flight_name].seat_price;

        // Deploy Ticket contract
        address ticket_address = address(new Ticket(_flight_name, _customer, _amount_payable));

        // Build ticket properties
        TicketData memory ticket_data = TicketData({
            flight_name: _flight_name,
            no_of_seats: _no_of_seats
        });

        // Add ticket address + properties in local _tickets mapping
        _tickets[ticket_address] = ticket_data;

        // Reduce number of seats available for flight
        decrement_flight_seats(_flight_name, _no_of_seats);

        return ticket_address;
    }

    function cancel_booking(address _ticket) external valid_ticket(_ticket) {
        // Call cancel method for existing Ticket contract (using address)
        (bool _res,) = _ticket.call(abi.encodeWithSignature("cancel_ticket()"));

        if (_res) {

            // Getting ticket properties using ticket address
            string memory flight_name = _tickets[_ticket].flight_name;
            uint no_of_seats = _tickets[_ticket].no_of_seats;

            // Incrementing cancelled flight seats
            increment_flight_seats(flight_name, no_of_seats);

            // Remove ticket from local _tickets mapping
            delete _tickets[_ticket];

        }
    }
}