// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.11;

import "./Tournament.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Factory is UUPSUpgradeable, OwnableUpgradeable {

    address rewardToken;
    address[] public tournaments;
    address[] public auxTournaments;

    constructor() {}

    function initialize(address _rewardToken) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        rewardToken = _rewardToken;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    event NewTournament(address _tournament, address owner);
    event TournamentDeleted(address _tournament);

    function newTournament(string memory _baseURI, uint256 registrationFee, uint startTime) external returns (address)
    {
        Tournament _newTournament;
        
        _newTournament = new Tournament(
            _baseURI,
            rewardToken,
            registrationFee,
            startTime,
            registrationClosesAt,
            msg.sender
        );
        
        tournaments.push(address(_newTournament));

        emit NewTournament(address(_newTournament), msg.sender);
        return address(_newTournament);
    }


    function deleteTournament(address _tournamentAddress) external onlyOwner {
        for (uint i = 0; i < tournaments.length; i++){
            if(tournaments[i] != _tournamentAddress)
                {
                    auxTournaments.push(tournaments[i]);
            }}

        tournaments = auxTournaments;
        delete auxTournaments;
        emit TournamentDeleted(_tournamentAddress);
    }

    // ------------ View Functions ------------ //

    function getTournament(uint _id)
    external view returns(address)
    {
        return tournaments[_id];
    }
}