# Airlines Blockchain Project
## Contracts
### Airline
##### Variables:
**\_admin ::** Address of the Airline contract creator (Airline Admin).

**\_flights ::** List of created flight names.

**\_flight\_info ::** Mapping of flight name to flight details. Flight details is a struct containing estimated\_departure, actual\_departure, no\_of\_seats, seat\_price and status.

**\_tickets ::** Mapping of created ticket address to ticket details needed during cancellation. Ticket details is a struct containing flight\_name and no\_of\_seats.

##### Modifiers:
**is\_admin ::** Validates whether caller is the Airline admin.

**valid\_booking\_inputs ::** Validates inputs provided during ticket booking.
* Customer Address - Should not be airline admin
* Flight Name - Should be valid
* Number of Seats - Should be non-zero
* Number of Seats - Should be available for booking in the flight

**valid\_ticket ::** Validates whether ticket address provided for cancellation is valid (created before).

##### Methods:
**add\_flight ::** 
* Can be called by Admin only.
* Adds data to **\_flights** and **\_flight\_info**.

**update\_flight\_departure ::** 
* Can be called by Admin only.
* Updates **actual\_departure** and **status** in the **\_flight\_info** for a particular flight.

**increment\_flight\_seats ::**
* Internal function to increase the number of available seats in **\_flight\_info** for a particular flight (ticket cancellation case).

**decrement\_flight\_seats ::**
* Internal function to decrease the number of available seats in **\_flight\_info** for a particular flight (ticket creation case).

**get\_flights ::**
* Getter for the **\_flights** list.

**get\_flight\_info ::**
* Returns the **\_flight\_info** for a particular flight.
* Can be used by other contracts to get the flight status.

**book\_ticket ::**
* Deploys a **Ticket** contract.
* Stores the deployed ticket contract address, and information in **\_tickets**.
* Calls **decrement\_flight\_seats()** to reduce total available tickets from **\_flight\_info**.
* Returns the deployed ticket contract address.

**cancel\_ticket ::**
* Calls the **cancel\_ticket()** method in the deployed ticket contract.
* On success,
    *  Calls **increment\_flight\_seats()** to increase total available tickets from **\_flight\_info**.
    *  Delets the the ticket contract address, and information from **\_tickets**.

### Ticket
##### Variables:
##### Modifiers:
##### Methods: