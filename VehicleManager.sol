/*
    reference:
    https://www.youtube.com/watch?v=ipwxYa-F1uY
    https://ethereum.stackexchange.com/questions/1527/how-to-delete-an-element-at-a-certain-index-in-an-array

    Test the code on https://remix.ethereum.org:
    Compile and set "Gas limit" to "30000000" for "Deployment".
*/

pragma solidity ^0.6.6;

contract VehicleManager {
    address payable vehicleManager;
    
    enum VehicleState {
        WORKING,
        BROKEN
    }
    
    struct Vehicle {
        address owner;
        // fixed priceInWei; // fixed not implemented yet
        uint256 priceInWei;
        string brand;
        VehicleState state;
        bool forSale;
        bool hasOwner;
    }
    
    struct VehicleOwner {
        address payable wallet;
        uint256 numberOfVehiclesOwned; // probably not necessary - alternatively: vehiclesById.length
        string[] vehiclesById; // not the optimal solution
        bool isRegistrated;
    }
    
    mapping(string => Vehicle) vehicles;
    
    mapping(address => VehicleOwner) vehicleOwner; // alternatively: mapping(address => VehicleOwnerships) vehicleOwnerships;
    
    constructor(address payable _vehicleManager) public {
        vehicleManager = _vehicleManager;
        
        vehicleOwner[vehicleManager].isRegistrated = true;
        vehicleOwner[vehicleManager].wallet = vehicleManager;
        vehicleOwner[vehicleManager].numberOfVehiclesOwned = 0;
        
        vehicles["a1"] = Vehicle(
            vehicleManager,
            1,
            "Funny Motors",
            VehicleState.WORKING,
            false,
            true
        );
        
        vehicleOwner[vehicleManager].numberOfVehiclesOwned++;
        vehicleOwner[vehicleManager].vehiclesById.push("a1");
        
        vehicles["a2"] = Vehicle(
            vehicleManager,
            2,
            "Elektrische Boliden",
            VehicleState.BROKEN,
            true,
            true
        );
        
        vehicleOwner[vehicleManager].numberOfVehiclesOwned++;
        vehicleOwner[vehicleManager].vehiclesById.push("a2");
        
        vehicles["b1"] = Vehicle(
            vehicleManager,
            4,
            "Nensho-Ki",
            VehicleState.WORKING,
            true,
            true
        );
        
        vehicleOwner[vehicleManager].numberOfVehiclesOwned++;
        vehicleOwner[vehicleManager].vehiclesById.push("b1");
    }
    
    // looking up msg.sender could cost gas
    
    function changeVehicleOwnership(
        string memory _vehicleId
    ) public payable returns(string memory) {
        if (
            vehicles[_vehicleId].hasOwner == true && // maybe not necessary
            vehicles[_vehicleId].forSale == true &&
            vehicles[_vehicleId].owner != msg.sender
            
        ) {
            if (msg.value == vehicles[_vehicleId].priceInWei) {
                vehicleOwner[vehicles[_vehicleId].owner].wallet.transfer(msg.value);
                
                // this part should be replaced by an internal function
                
                for (
                    uint256 i = 0;
                    i < (vehicleOwner[vehicles[_vehicleId].owner].numberOfVehiclesOwned - 1);
                    i++
                ) {
                    string memory _currentVehicleId = vehicleOwner[vehicles[_vehicleId].owner].vehiclesById[i];
                    
                    if (
                        keccak256(abi.encodePacked((_currentVehicleId))) ==
                        keccak256(abi.encodePacked((_vehicleId)))
                    ) {
                        vehicleOwner[vehicles[_vehicleId].owner].vehiclesById[i] = 
                            vehicleOwner[vehicles[_vehicleId].owner].vehiclesById[
                                vehicleOwner[vehicles[_vehicleId].owner].vehiclesById.length - 1
                            ]; // replace sold vehicle entry with last vehicle entry
                        
                        delete vehicleOwner[vehicles[_vehicleId].owner].vehiclesById[
                            vehicleOwner[vehicles[_vehicleId].owner].vehiclesById.length - 1
                        ];
                        
                        vehicleOwner[vehicles[_vehicleId].owner].vehiclesById.pop();
                        
                        i = vehicleOwner[vehicles[_vehicleId].owner].numberOfVehiclesOwned;
                    }
                }
                
                vehicleOwner[vehicles[_vehicleId].owner].numberOfVehiclesOwned--;
                
                vehicles[_vehicleId].owner = msg.sender;
                vehicles[_vehicleId].forSale = false;
                vehicleOwner[msg.sender].numberOfVehiclesOwned++;
                vehicleOwner[msg.sender].vehiclesById.push(_vehicleId);
                
                return "Transaction successful!";
            }
            else {
                return "Transaction failed - please transfer the correct amount of ether!";
            }
        }
        
        if (vehicles[_vehicleId].hasOwner != true) {
            return "Transaction failed - vehicle does not exist!";
        }
        
        if (vehicles[_vehicleId].forSale != true) {
            return "Transaction failed - vehicle is not for sale!";
        }
        
        if (vehicles[_vehicleId].forSale != true) {
            return "Transaction failed - vehicle is already in possession!";
        }
    }
    
    function registrateNewVehicle(
        address _vehicleOwner, 
        string memory _vehicleId, 
        uint256 _vehiclePriceInWei, 
        string memory _vehicleBrand,
        VehicleState _vehicleState,
        bool _vehicleForSale
    ) public returns(string memory) {
        if(
            msg.sender == vehicleManager &&
            vehicleOwner[_vehicleOwner].isRegistrated &&
            // check if vehicle by _vehicleId has no owner yet
            // alternatively: if(vehicles[_vehicleId].owner != false) to save resources
            vehicles[_vehicleId].hasOwner == false
        ) {
            vehicles[_vehicleId] = Vehicle(
                _vehicleOwner,
                _vehiclePriceInWei,
                _vehicleBrand,
                _vehicleState,
                _vehicleForSale,
                true
            );
            
            vehicleOwner[_vehicleOwner].numberOfVehiclesOwned++;
            vehicleOwner[_vehicleOwner].vehiclesById.push(_vehicleId);
            
            return "Registration successful!";
        }
        
        if(msg.sender != vehicleManager) {
            return "Permission denied - just the vehicle manager can registrate new vehicles!";
        }
        else if (vehicleOwner[_vehicleOwner].isRegistrated) {
            return "Registration failed - owner of the vehicle is not registrated yet!";
        }
        else if (vehicles[_vehicleId].hasOwner == true) {
            return "Registration failed - vehicle ID has already an owner!";
        }
    }
    
    function setVehiclePriceInWei(
        string memory _vehicleId,
        uint256 _vehiclePriceInWei
    ) public {
        if(vehicles[_vehicleId].owner == msg.sender) {
            vehicles[_vehicleId].priceInWei = _vehiclePriceInWei;
        }
    }
    
    function setVehicleState(
        string memory _vehicleId,
        VehicleState _vehicleState
    ) public {
        if(vehicles[_vehicleId].owner == msg.sender) {
            vehicles[_vehicleId].state = _vehicleState;
        }
    }
    
    function setVehicleForSale(
        string memory _vehicleId,
        bool _vehicleForSale
    ) public returns(string memory) {
        if(vehicles[_vehicleId].owner == msg.sender) {
            vehicles[_vehicleId].forSale = _vehicleForSale;
            
            if(_vehicleForSale) { 
                return "Vehicle set for Sale!";
            }
            else {
                return "Vehicle set not for Sale!";
            }
        }
        
        return "Permission denied - just the vehicle owner can set the vehicle for sale respectively not for sale!";
    }
    
    function registrateNewVehicleOwner(address payable _newVehicleOwner) public returns(string memory) {
        if(msg.sender == vehicleManager) {
            if(vehicleOwner[_newVehicleOwner].isRegistrated == false) {
                vehicleOwner[_newVehicleOwner].isRegistrated = true;
                vehicleOwner[_newVehicleOwner].wallet = _newVehicleOwner;
                vehicleOwner[_newVehicleOwner].numberOfVehiclesOwned = 0;
            
                return "Registration successful!";
            }
            else {
                return "Registration failed - vehicle owner is already registrated!";
            }
        }
        
        return "Permission denied - just the vehicle manager can registrate new vehicle owner!";
    }
    
    function getVehicleOwner(string memory _vehicleId) public view returns(address) {
        return vehicles[_vehicleId].owner;
    }
    
    function getVehiclePriceInWei(string memory _vehicleId) public view returns(uint256) {
        return vehicles[_vehicleId].priceInWei;
    }
    
    function getVehicleBrand(string memory _vehicleId) public view returns(string memory) {
        return vehicles[_vehicleId].brand;
    }
    
    function getVehicleState(string memory _vehicleId) public view returns(VehicleState) {
        return vehicles[_vehicleId].state;
    }
    
    function isVehicleForSale(string memory _vehicleId) public view returns(bool) {
        return vehicles[_vehicleId].forSale;
    }
    
    function getNumberOfVehiclesOwned() public view returns(uint256) {
        return vehicleOwner[msg.sender].numberOfVehiclesOwned;
    }
    
    function getVehicleIdByCountNumber(uint256 _countNumber) public view returns(string memory) {
        return vehicleOwner[msg.sender].vehiclesById[_countNumber - 1];
    }
    
    function isVehicleOwnerRegistrated() public view returns(bool) {
        return vehicleOwner[msg.sender].isRegistrated;
    }
}