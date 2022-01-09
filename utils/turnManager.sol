// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)
pragma solidity ^0.8.0;
// modified version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol

library DiceRoll {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            if(counter._value =< 4){
                counter._value += 1;
            }

            else{
                reset(counter);
            }
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
