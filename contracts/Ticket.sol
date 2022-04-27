// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Ticket {

    enum TicketStatus {BOOKED, PAID, CANCELLED, CLAIMED}
    enum FlightStatus {SCHEDULED, ONTIME, DELAYED, CANCELLED}

    string public _flight_name;
    address public _customer_address;
    address public _airline_address;
    TicketStatus public _status;
    uint public _no_of_seats;
    uint public _seat_price;
    uint public _total_amount_payable;
    uint8 _flight_delay_penalty_percentage = 30;
    uint8 _ticket_cancellation_penalty_percentage = 40;

    modifier validate_payment() {
        require(_status == TicketStatus.BOOKED, "Ticket has already been paid.");
        _;
    }

    modifier validate_cancellation() {
        require(_status != TicketStatus.BOOKED, "Ticket has not been paid for yet.");
        require(_status != TicketStatus.CANCELLED, "Ticket has already been cancelled.");
        require(_status != TicketStatus.CLAIMED, "Ticket has been claimed, and can't be cancelled now.");
        _;
    }

    modifier validate_claim(uint8 _flight_status) {
        FlightStatus flight_status = FlightStatus(_flight_status);
        require(_status != TicketStatus.BOOKED, "Ticket has not been paid for yet.");
        require(_status != TicketStatus.CLAIMED, "Ticket has already been claimed.");
        require(_status != TicketStatus.CANCELLED, "Ticket has been cancelled, and can't be claimed now.");
        require( flight_status != FlightStatus.ONTIME, "Nothing to claim.");
        _;
    }

    event TicketCancel(address indexed _ticket, address indexed _airline, bool _airline_transfer_success, uint _airline_amount, address indexed _customer, bool _customer_transfer_success, uint _customer_amount);
    event TicketClaim(address indexed _ticket, address indexed _airline, bool _airline_transfer_success, uint _airline_amount, address indexed _customer, bool _customer_transfer_success, uint _customer_amount);

    constructor(string memory flight_name, address customer, address airline, uint no_of_seats, uint seat_price) {
        _flight_name = flight_name;
        _customer_address = customer;
        _airline_address = airline;
        _no_of_seats = no_of_seats;
        _seat_price = seat_price;
        _status = TicketStatus.BOOKED;
        _total_amount_payable = no_of_seats * _seat_price;
    }

    function pay() public payable validate_payment {
        _status = TicketStatus.PAID;
    }

    function cancellation() public payable validate_cancellation {
        uint _airline_amount = 0;
        uint _customer_amount = 0;
        bool _airline_transfer_success = true;
        bool _customer_transfer_success = true;

        _airline_amount = (_total_amount_payable * _ticket_cancellation_penalty_percentage) / 100;
        _customer_amount = _total_amount_payable - _airline_amount;
        (_airline_transfer_success, ) = _airline_address.call{value:_airline_amount}("");
        (_customer_transfer_success, ) = _customer_address.call{value:_customer_amount}("");

        emit TicketCancel(address(this), _airline_address, _airline_transfer_success, _airline_amount, _customer_address, _customer_transfer_success, _customer_amount);

        require(_airline_transfer_success == true && _customer_transfer_success == true,"Ticket cancel process incomplete/failed.");

        _status = TicketStatus.CANCELLED;

    }

    function claim(uint8 flight_status) public payable validate_claim(flight_status) {
        uint _airline_amount = 0;
        uint _customer_amount = 0;
        bool _airline_transfer_success = true;
        bool _customer_transfer_success = true;
        
        if (FlightStatus(flight_status) == FlightStatus.DELAYED) {
            _customer_amount = (_total_amount_payable * _flight_delay_penalty_percentage) / 100;
            _airline_amount  = _total_amount_payable - _customer_amount;
            (_airline_transfer_success, ) = _airline_address.call{value:_airline_amount}("");
            (_customer_transfer_success, ) = _customer_address.call{value:_customer_amount}("");
        }
        else {
            _customer_amount = _total_amount_payable;
            (_customer_transfer_success, ) = _customer_address.call{value:_customer_amount}("");
        }

        emit TicketClaim(address(this), _airline_address, _airline_transfer_success, _airline_amount, _customer_address, _customer_transfer_success, _customer_amount);

        require(_airline_transfer_success == true && _customer_transfer_success == true,"Ticket claim process incomplete/failed.");

        _status = TicketStatus.CLAIMED;

    }
}