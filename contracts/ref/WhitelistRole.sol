
import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/Roles.sol";

pragma solidity ^0.6.0;

contract WhitelistRole is  Ownable {
    using Roles for Roles.Role;

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    Roles.Role private _whitelist;


     constructor() internal {
        _addWhitelist(address(0));
       
    }

    modifier onlyWhitelist() {
        require(isWhitelist(msg.sender), "WhitelistRole: caller does not have the Whitelist role");
        _;
    }

    function isWhitelist(address account) public view returns (bool) {
        return _whitelist.has(account);
    }

    function addWhitelist(address account) public onlyOwner {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) public onlyOwner {
        _removeWhitelist(account);
    }


    function _addWhitelist(address account) internal {
        _whitelist.add(account);
        emit WhitelistAdded(account);
    }

    function _removeWhitelist(address account) internal {
        _whitelist.remove(account);
        emit WhitelistRemoved(account);
    }
}

