// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Erc20.sol";
import "./PoolCreatableErc20i.sol";
import "./Generators/Generator.sol";

abstract contract Cassettes is PoolCreatableErc20i {
    using ExtraSeedLibrary for address;
    mapping(address owner => uint) _counts;
    mapping(address owner => mapping(uint index => SeedData seed_data)) _ownedTokens;
    mapping(address owner => mapping(uint tokenId => uint)) _ownedTokensIndex;
    mapping(address owner => mapping(uint => bool)) _owns;
    mapping(address owner => SeedData seed_data) _recordings;
    mapping(uint index => address user) _holderList;
    mapping(address user => uint index) _holderListIndexes;
    uint _cassettesTotalCount;
    uint _holdersCount;
    uint _recordingsTotalCount;
    uint blank1; // delete

    uint z = 2;

    event OnCassetteTransfer(
        address indexed from,
        address indexed to,
        SeedData seed_data
    );
    event OnRecordingsGrow(address indexed holder, SeedData seed_data);
    event OnRecordingsShrink(address indexed holder, SeedData seed_data);

    constructor() PoolCreatableErc20i("midi", "MIDI", msg.sender) {}

    modifier holder_calculate(address acc1, address acc2) {
        bool before1 = _isHolder(acc1);
        bool before2 = _isHolder(acc2);
        _;
        bool after1 = _isHolder(acc1);
        bool after2 = _isHolder(acc2);
        if (!before1 && after1) _addHolder(acc1);
        if (before1 && !after1) _removeHolder(acc1);
        if (!before2 && after2) _addHolder(acc2);
        if (before2 && !after2) _removeHolder(acc2);
    }

    function _isHolder(address account) private view returns (bool) {
        if (
            account == address(this) ||
            account == _pool ||
            account == address(0)
        ) return false;

        return (_recordings[account].seed + this.cassetteCount(account)) > 0;
    }

    function trySeedTransfer(
        address from,
        address to,
        uint amount
    ) internal holder_calculate(from, to) {
        if (from == address(this)) return;
        uint seed = amount / (10 ** decimals());

        if (seed > 0 && from != _pool && to != _pool) {
            // transfer growing cassette
            if (_recordings[from].seed == seed) {
                SeedData memory data = _recordings[from];
                _removeSeedCount(from, seed);
                _addTokenToOwnerEnumeration(to, data);
                emit OnCassetteTransfer(from, to, data);
                return;
            }

            // transfer collected cassette
            if (_owns[from][seed] && !_owns[to][seed]) {
                SeedData memory data = _ownedTokens[from][
                    _ownedTokensIndex[from][seed]
                ];
                _removeTokenFromOwnerEnumeration(from, seed);
                _addTokenToOwnerEnumeration(to, data);
                emit OnCassetteTransfer(from, to, data);
                return;
            }
        }

        // transfer recordings
        uint lastBalanceFromSeed = _balances[from] / (10 ** decimals());
        uint newBalanceFromSeed = (_balances[from] - amount) /
            (10 ** decimals());
        _removeSeedCount(from, lastBalanceFromSeed - newBalanceFromSeed);
        _addSeedCount(to, seed);
    }

    function _addHolder(address account) private {
        _holderList[_holdersCount] = account;
        _holderListIndexes[account] = _holdersCount;
        ++_holdersCount;
    }

    function _removeHolder(address account) private {
        if (_holdersCount == 0) return;
        --_holdersCount;
        uint removingIndex = _holderListIndexes[account];
        _holderList[removingIndex] = _holderList[_holdersCount];
        delete _holderList[_holdersCount];
        delete _holderListIndexes[account];
    }

    function getHolderByIndex(uint index) public view returns (address) {
        return _holderList[index];
    }

    function getHoldersList(
        uint startIndex,
        uint count
    ) public view returns (address[] memory) {
        address[] memory holders = new address[](count);
        for (uint i = 0; i < count; ++i)
            holders[i] = getHolderByIndex(startIndex + i);
        return holders;
    }

    function _addSeedCount(address account, uint seed) private {
        if (seed == 0) return;
        if (account == _pool) return;
        SeedData memory last = _recordings[account];

        _recordings[account].seed += seed;
        _recordings[account].extra = account.extra();

        if (last.seed == 0 && _recordings[account].seed > 0) ++_recordingsTotalCount;

        emit OnRecordingsGrow(account, _recordings[account]);
    }

    function _removeSeedCount(address account, uint seed) private {
        if (seed == 0) return;
        if (account == _pool) return;
        SeedData memory lastRecordings = _recordings[account];
        if (_recordings[account].seed >= seed) {
            _recordings[account].seed -= seed;
            if (lastRecordings.seed > 0 && _recordings[account].seed == 0)
                --_recordingsTotalCount;
            emit OnRecordingsShrink(account, _recordings[account]);
            return;
        }
        uint seedRemains = seed - _recordings[account].seed;
        _recordings[account].seed = 0;

        // remove cassettes
        uint count = _counts[account];
        uint removed;
        for (uint i = 0; i < count && removed < seedRemains; ++i) {
            removed += _removeFirstTokenFromOwner(account);
        }

        if (removed > seedRemains)
            _recordings[account].seed += removed - seedRemains;
        if (lastRecordings.seed > 0 && _recordings[account].seed == 0)
            --_recordingsTotalCount;
        if (lastRecordings.seed == 0 && _recordings[account].seed > 0)
            ++_recordingsTotalCount;      

        emit OnRecordingsShrink(account, _recordings[account]);
    }

    function _addTokenToOwnerEnumeration(
        address to,
        SeedData memory data
    ) private {
        if (to == _pool) return;
        ++_counts[to];
        ++_cassettesTotalCount;
        uint length = _counts[to] - 1;
        _ownedTokens[to][length] = data;
        _ownedTokensIndex[to][data.seed] = length;
        _owns[to][data.seed] = true;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint seed) private {
        if (from == _pool) return;
        --_counts[from];
        --_cassettesTotalCount;
        _owns[from][seed] = false;
        uint lastTokenIndex = _counts[from];
        uint tokenIndex = _ownedTokensIndex[from][seed];
        SeedData memory data = _ownedTokens[from][tokenIndex];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            SeedData memory lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[from][lastTokenId.seed] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[from][data.seed];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeFirstTokenFromOwner(address owner) private returns (uint) {
        uint count = _counts[owner];
        if (count == 0) return 0;
        uint seed = _ownedTokens[owner][0].seed;
        _removeTokenFromOwnerEnumeration(owner, seed);
        return seed;
    }

    function isOwnerOf(address owner, uint seed) external view returns (bool) {
        return _owns[owner][seed];
    }

    function recordingsDegree(
        address owner
    ) external view returns (SeedData memory data) {
        return _recordings[owner];
    }

    function cassetteCount(address owner) external view returns (uint) {
        return _counts[owner];
    }

    function cassetteOfOwnerByIndex(
        address owner,
        uint index
    ) external view returns (SeedData memory data) {
        return _ownedTokens[owner][index];
    }

    function cassettesTotalCount() external view returns (uint) {
        return _cassettesTotalCount;
    }

    function holdersCount() external view returns (uint) {
        return _holdersCount;
    }

    function recordingsTotalCount() external view returns (uint) {
        return _recordingsTotalCount;
    }
}

contract Midi is Cassettes, Generator, ReentrancyGuard {
    uint constant _startTotalSupply = 210e6 * (10 ** _decimals);
    uint constant _startMaxBuyCount = (_startTotalSupply * 3) / 1000;  
    uint constant _addMaxBuyPercentPerSec = 5; // 100%=_addMaxBuyPrecesion add 0.005%/second
    uint constant _addMaxBuyPrecesion = 100000;

    constructor() {
        _mint(msg.sender, _startTotalSupply);
    }

    modifier maxBuyLimit(uint256 amount) {
        require(amount <= maxBuy(), "max buy limit");
        // require(balanceOf(msg.sender) + amount <= maxBuy(), "max buy limit");
        _;
    }

    function maxBuy() public view returns (uint256) {
        if (!isStarted()) return _startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (_startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            _addMaxBuyPrecesion;
        if (count > _startTotalSupply) count = _startTotalSupply;
        return count;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isStarted()) {
            trySeedTransfer(from, to, amount);
        } else {
            require(from == _owner || to == _owner, "not started");
        }

        // allow burning
        if (to == address(0)) {
            _burn(from, amount);
            return;
        }

        // system transfers
        if (from == address(this)) {
            super._transfer(from, to, amount);
            return;
        }

        if (_feeLocked) {
            super._transfer(from, to, amount);
            return;
        } else {
            if (from == _pool && to != _owner) {
                buy(to, amount);
                return;
            }
        }

        super._transfer(from, to, amount);
    }

    function buy(
        address to,
        uint256 amount
    ) private maxBuyLimit(amount) lockFee {
        super._transfer(_pool, to, amount);
    }

    function burnCount() public view returns (uint256) {
        return _startTotalSupply - totalSupply();
    }
}
