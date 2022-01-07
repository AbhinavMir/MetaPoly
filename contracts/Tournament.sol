//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITournament} from "./interfaces/ITournament.sol";

contract Tournament is  ITournament, ERC721URIStorage, Pausable, AccessControl {

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private _tokenIds;
    Counter.Counter private _playerMove;
    
    bytes32 public constant JAILED_USER = keccak256("JAILED_USER");
    bytes32 public constant BLACKLISTED_USER = keccak256("BLACKLISTED_USER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant PLAYER = keccak256("PLAYER");
    bytes32 public constant BANKER = keccak256("BANKER");

    string private _tournamentURI;
    bool terminated;

    address private _rewardToken;
    uint256 private _registrationFee;
    uint256 private _PrizeMoneyTracker;

    uint256 private _startTime;

    mapping(address => uint256) playerIDs;
    mapping(uint256 => Match) private matches;

    Prize[] prizes;

    Vault public registrationVault;
    Vault public prizeVault;

    Counters.Counter _matchIds;
    Counters.Counter _teamIds;
    Counters.Counter _prizeIds;
    Counters.Counter _adminCounter;

    bool private _hasGroups;
    bool private _hasRounds;
    bool private _hasRequests;

    constructor(
        string memory _URI,
        address _token,
        uint256 _fee,
        uint256 _start,
        uint256 _registrationClosesAt,
        address admin
    ) ERC721("Jinushi", "JNSHI") ERC721URIStorage() {
        if (_fee > 0) {
            _registrationFee = _fee;
            registrationVault = new Vault(_token, address(this));
        }
        prizeVault = new Vault(_token, address(this));

        _tournamentURI = _URI;
        _rewardToken = _token;
        _startTime = _start;
        _registrationClosingTime = _registrationClosesAt;

        _isPrivate = true;

        _setupRole(BANKER, msg.sender);
    }
