// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Note {
    uint8 note;        // MIDI note number
    uint8 velocity;    // MIDI note velocity
    uint startTime;    // Start time of the note in MIDI ticks
    uint duration;     // Duration of the note in MIDI ticks
}


struct Rect {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct FileData {
    uint lvl;
    uint file;
    Rect[] rects;
}

struct ScaleInfo {
    string name;
    uint8[] notes;
}


library ExtraSeedLibrary {
    function extra(address account) internal pure returns (uint256) {
        return uint(keccak256(abi.encode(account)));
    }

    function seed_data(
        address account,
        uint seed
    ) internal pure returns (SeedData memory) {
        return SeedData(seed, extra(account));
    }
}

struct NormalisedNote {
    uint256 startFraction10e6;
    uint256 durationFraction10e6;
    uint256 velocity;
}

struct MultiModalData {
    uint lvl; 
    string midiBase64;
    ScaleInfo scale;
    uint totalDuration;
    uint totalDurationMs;
    uint bpm;
    uint ticksPerQuarterNote;
    uint8 instrument;
    string uuid;
    string barColorTop;
    string barColorBottom;    
    Note[] melody;
    bool hasBackground;
    uint8 hasSpecialBackground;
    string backgroundColor;
    uint backgroundIconId;
    string backgroundIconColor;    
}


struct SeedData {
    uint seed;
    uint extra;
}

struct Rand {
    uint seed;
    uint nonce;
    uint extra;
}

uint constant seedLevel1 = 1000; // not actually used 
uint constant seedLevel2 = 21000; // 0.01%
uint constant seedLevel3 = 105000; // 0.05%
uint constant seedLevel4 = 420000; // 0.2%
uint constant seedLevel5 = 1050000; // 0.5%         

library RandLib {
    using Converter for uint;

    function next(Rand memory rnd) internal pure returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(rnd.seed + rnd.nonce++ - 1, rnd.extra)
                )
            );
    }

    function getUuid(
        SeedData calldata seed_data
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(seed_data.seed.toString(), '_', seed_data.extra.toString()));
    }

    function getUuid(
        Rand memory rnd
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(rnd.seed.toString(), rnd.extra.toString()));
    }    

    function lvl(Rand memory rnd) internal pure returns (uint) {
        if (rnd.seed < seedLevel1) return 0;
        if (rnd.seed < seedLevel2) return 1;
        if (rnd.seed < seedLevel3) return 2;
        if (rnd.seed < seedLevel4) return 3;
        if (rnd.seed < seedLevel5) return 4;
        return 5;
    }

    function random(
        string[] memory data,
        Rand memory rnd
    ) internal pure returns (string memory) {
        return data[randomIndex(data, rnd)];
    }

    function random(
        string[][] memory data,
        Rand memory rnd
    ) internal pure returns (string[] memory) {
        return data[randomIndex(data, rnd)];
    }

    function randomIndex(
        string[] memory data,
        Rand memory rnd
    ) internal pure returns (uint) {
        return next(rnd) % data.length;
    }

    function randomIndex(
        string[][] memory data,
        Rand memory rnd
    ) internal pure returns (uint) {
        return next(rnd) % data.length;
    }
}


library LayersLib {
    function setLayers(
        mapping(uint => mapping(uint => Rect[])) storage rects,
        FileData[] calldata data
    ) internal {
        for (uint i = 0; i < data.length; ++i) {
            setFile(rects, data[i]);
        }
    }

    function setFile(
        mapping(uint => mapping(uint => Rect[])) storage rects,
        FileData calldata input
    ) internal {
        Rect[] storage storageFile = rects[input.lvl][input.file];
        for (uint i = 0; i < input.rects.length; ++i) {
            storageFile.push(input.rects[i]);
        }
    }

    function getLvl(
        mapping(uint => mapping(uint => Rect[])) storage rects,
        uint lvl
    ) internal view returns (mapping(uint => Rect[]) storage) {
        return rects[lvl];
    }

    function to_lvl_1(uint l) internal pure returns (uint) {
        if (l > 0) --l;
        return l;
    }
}


library Converter {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;

            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            
            value /= 10;
        }
        return string(buffer);
    }
}
