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
        address customer_address;
        string flight_name;
        uint no_of_seats;
    }

    address private _admin;
    string[] internal _flights;
    address[] internal _tickets;
    mapping(string => FlightData) internal _flight_info;
    mapping(address => TicketData) internal _ticket_info;

    // Auth Validation Modifiers

    modifier is_admin() {
        require(msg.sender == _admin, "Action not permitted for non-Admin users.");
        _;
    }

    modifier is_not_admin() {
        require(msg.sender != _admin, "User is not a customer.");
        _;
    }

    modifier is_ticket_owner(address _addr) {
        require(msg.sender == _ticket_info[_addr].customer_address, "Action not permitted for current user. Must be ticket owner.");
        _;
    }

    // Input Validation Modifiers

    modifier valid_add_flight_inputs(string memory _flight_name, uint _estimated_departure, uint _no_of_seats, uint _seat_price) {
        require(_flight_info[_flight_name].estimated_departure == 0, "Flights Already Exists.");
        require(_estimated_departure > 0, "Invalid estimated departure time.");
        require(_no_of_seats > 0, "Number of seats can't be zero.");
        require(_seat_price > 0, "Seat price can't be zero.");
        _;
    }

    modifier valid_flight_name(string memory _flight_name) {
        require(_flight_info[_flight_name].estimated_departure != 0, "Invalid flight name.");
        _;
    }

    modifier valid_booking_inputs(string memory _flight_name, uint _no_of_seats) {
        require(_no_of_seats > 0, "Can not book 0 seats.");
        require(_flight_info[_flight_name].no_of_seats >= _no_of_seats,"Specified number of seats not available.");
        require(msg.value == (_no_of_seats * _flight_info[_flight_name].seat_price), "Amount paid does not match the total payable amount.");
        _;
    }

    modifier valid_ticket(address _addr) {
        require(_ticket_info[_addr].no_of_seats > 0, "Specified ticket does not exist.");
        _;
    }

    // State Validation Modifiers

    modifier valid_flight_state_for_booking(string memory flight_name) {
        require(_flight_info[flight_name].status == FlightStatus.SCHEDULED, "Ticket can't be booked for this flight now.");
        _;
    }

    // Time Validation Modifiers

    modifier request_2_hours_before_departure(address _addr) {

        string memory _flight_name = _ticket_info[_addr].flight_name;
        int time_diff = int(_flight_info[_flight_name].estimated_departure) - int(block.timestamp);
        require(time_diff / 3600 >= 2, "Request can only be made before 2 hours of flight departure time.");
        _;
    }

    modifier request_24_hours_after_departure(address _addr) {

        string memory _flight_name = _ticket_info[_addr].flight_name;
        FlightStatus _flight_status = _flight_info[_flight_name].status;
        int time_diff = 0;

        // Consider estimated departure time if flight did not actually depart (scheduled or cancelled)
        if (_flight_status == FlightStatus.SCHEDULED || _flight_status == FlightStatus.CANCELLED) {
            time_diff = int(block.timestamp) - int(_flight_info[_flight_name].estimated_departure);
        }

        // Consider actual departure time if flight actually departed (ontime or delayed)
        if (_flight_status == FlightStatus.ONTIME || _flight_status == FlightStatus.DELAYED) {
            time_diff = int(block.timestamp) - int(_flight_info[_flight_name].actual_departure);
        }

        require(time_diff / 3600 >= 24, "Request can't be made until 24 hours after flight departure time. Try later.");
        _;
    }

    constructor() {
        _admin = msg.sender;
    }

    function add_flight(string memory _flight_name, uint _estimated_departure, uint _no_of_seats, uint _seat_price) public is_admin valid_add_flight_inputs(_flight_name, _estimated_departure, _no_of_seats, _seat_price) {
        
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

    function update_flight_seats(string memory _flight_name, int value) internal valid_flight_name(_flight_name) {
        _flight_info[_flight_name].no_of_seats = uint(int(_flight_info[_flight_name].no_of_seats) + value);
    }

    function get_flights() public view returns(string[] memory) {
        return _flights;
    }

    function get_tickets() public view returns(address[] memory) {
        return _tickets;
    }

    function get_flight_info(string memory _flight_name) external view returns(FlightData memory) {
        return _flight_info[_flight_name];
    }

    function book_ticket(string memory _flight_name, uint _no_of_seats) external payable is_not_admin valid_flight_name(_flight_name) valid_flight_state_for_booking(_flight_name) valid_booking_inputs(_flight_name, _no_of_seats) returns(address) {

        // Deploy Ticket contract
        address ticket_address = address(new Ticket(_flight_name, msg.sender, _admin, _no_of_seats, _flight_info[_flight_name].seat_price));

        (bool _res,) = ticket_address.call{value:msg.value}(abi.encodeWithSignature("pay()"));

        if (_res) {

            // Build ticket properties
            TicketData memory ticket_data = TicketData({
                customer_address: msg.sender,
                flight_name: _flight_name,
                no_of_seats: _no_of_seats
            });

            // Add ticket address + properties in local _ticket_info mapping
            _ticket_info[ticket_address] = ticket_data;

            _tickets.push(ticket_address);

            // Reduce number of seats available for flight
            update_flight_seats(_flight_name, -1 * int(_no_of_seats));

        }

        return ticket_address;
    }

    function cancel_ticket(address _ticket) external valid_ticket(_ticket) is_ticket_owner(_ticket) request_2_hours_before_departure(_ticket) {
        // Call cancel method for existing Ticket contract (using address)
        (bool _res,) = _ticket.call(abi.encodeWithSignature("cancellation()"));

        if (_res) {

            // Getting ticket properties using ticket address
            string memory flight_name = _ticket_info[_ticket].flight_name;
            int no_of_seats = int(_ticket_info[_ticket].no_of_seats);

            // Incrementing cancelled flight seats
            update_flight_seats(flight_name, no_of_seats);

        }
    }

    function claim_ticket(address _ticket) external valid_ticket(_ticket) is_ticket_owner(_ticket) request_24_hours_after_departure(_ticket) {

        // Get flight status
        string memory _flight_name = _ticket_info[_ticket].flight_name;
        FlightStatus _status = _flight_info[_flight_name].status;

        // Call claim method for existing Ticket contract (using address)
        Ticket t = Ticket(_ticket);
        t.claim(uint8(_status));

    }

}
