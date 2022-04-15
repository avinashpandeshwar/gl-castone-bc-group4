// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Ticket {

    string _flight_name;
    address _customer_address;
    uint _amount_payable;

    constructor(string memory flight_name, address customer, uint amount_payable) {
        _flight_name = flight_name;
        _customer_address = customer;
        _amount_payable = amount_payable;
    }
}