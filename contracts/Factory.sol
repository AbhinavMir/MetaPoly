// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.11;

import "./Tournament.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Factory is UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => Tournament) public activeTournaments;

    constructor() {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    event NewTournament(address _tournament, address owner);
    event TournamentDeleted(address _tournament);

    function newTournament(
        string memory _baseURI,
        uint256 _registrationFee,
        uint256 _startTime,
        uint256 _TTL,
        uint256 _maxPlayers,
        bytes32 _salt,
        mapping(address => Player) memory _players
    ) external returns (address) {
        Tournament tournament = new Tournament{salt: _salt}(
            _baseURI,
            _registrationFee,
            _startTime,
            _TTL,
            _maxPlayers,
            _players
        );
        activeTournaments[address(tournament)] = tournament;
        emit NewTournament(address(tournament), msg.sender);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(abi.encodePacked(_baseURI, _registrationFee, _startTime, _TTL, _maxPlayers, _players))));
        return address(tournament);
    }

    function deleteTournament(address _tournamentAddress) external onlyOwner {
        delete activeTournaments[_tournamentAddress];
        emit TournamentDeleted(_tournamentAddress);
    }

    // ------------ View Functions ------------ //

    function getTournament(uint256 _id) external view returns (address) {
        return tournaments[_id];
    }
}
