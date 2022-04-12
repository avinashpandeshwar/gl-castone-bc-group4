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

    address private admin;
    string[] internal _flights;
    mapping(string => FlightData) internal _flight_info;

    modifier is_admin() {
        require(msg.sender == admin, "Action not permitted for non-Admin users.");
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

    // function book_ticket() external {

    // }
}