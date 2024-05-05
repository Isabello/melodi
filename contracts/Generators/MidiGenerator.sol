// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @title MidiGenerator
 * @dev A contract to generate MIDI melodies based on predefined musical scales and user levels.
 */
 import "@openzeppelin/contracts/utils/Base64.sol";

import "../lib/Helpers.sol";
// import "forge-std/console.sol";


contract MidiGenerator {
    using Converter for uint256;
    using Converter for uint8;
    using RandLib for Rand;
    using LayersLib for uint;

    string r = "a";

    mapping(uint => ScaleInfo[]) public levelScales;
    mapping(address => Note[]) public lastMelodies; 
    uint[] private durations = [30, 60];
    mapping(address => uint) public balances;

    uint constant ticksPerQuarterNote = 120;
    uint constant bpm = 120;

    constructor() {
        levelScales[0].push(ScaleInfo("Major Pentatonic", new uint8[](5)));
        levelScales[0].push(ScaleInfo("Minor Pentatonic", new uint8[](5)));
        levelScales[0].push(ScaleInfo("Major Scale", new uint8[](7)));
        levelScales[0].push(ScaleInfo("Natural Minor Scale", new uint8[](7)));
        levelScales[0].push(ScaleInfo("Harmonic Major", new uint8[](7)));
        levelScales[0].push(ScaleInfo("Six Tone Symmetrical", new uint8[](6)));
        levelScales[0].push(ScaleInfo("Dorian Mode", new uint8[](7)));

        levelScales[0][0].notes = [60, 62, 64, 67, 69];
        levelScales[0][1].notes = [60, 63, 65, 67, 70];
        levelScales[0][2].notes = [60, 62, 64, 65, 67, 69, 71];
        levelScales[0][3].notes = [60, 62, 63, 65, 67, 68, 70];
        levelScales[0][4].notes = [60, 62, 64, 65, 67, 68, 71];
        levelScales[0][5].notes = [60, 62, 64, 66, 68, 70];
        levelScales[0][6].notes = [60, 62, 63, 65, 67, 69, 70];

        // Level 2 Scales
        levelScales[1].push(ScaleInfo("Ionian Pentatonic", new uint8[](5)));
        levelScales[1].push(ScaleInfo("Mixolydian Pentatonic", new uint8[](5)));
        levelScales[1].push(ScaleInfo("Egyptian", new uint8[](5)));
        levelScales[1].push(ScaleInfo("Neopolitan Major Pentatonic", new uint8[](5)));
        levelScales[1].push(ScaleInfo("Pelog", new uint8[](5)));
        levelScales[1].push(ScaleInfo("Dorian b2", new uint8[](7)));
        levelScales[1].push(ScaleInfo("Mixolydian b6", new uint8[](7)));
        levelScales[1].push(ScaleInfo("Lydian #5", new uint8[](7)));
        levelScales[1].push(ScaleInfo("Phrygian Dominant", new uint8[](7)));
        levelScales[1].push(ScaleInfo("Aeolian b5", new uint8[](7)));

        levelScales[1][0].notes = [60, 62, 64, 65, 67];
        levelScales[1][1].notes = [60, 62, 64, 67, 71];
        levelScales[1][2].notes = [60, 62, 63, 67, 70];
        levelScales[1][3].notes = [60, 62, 64, 67, 70];
        levelScales[1][4].notes = [60, 62, 65, 67, 70];
        levelScales[1][5].notes = [60, 61, 63, 65, 67, 69, 70];
        levelScales[1][6].notes = [60, 62, 64, 65, 67, 68, 71];
        levelScales[1][7].notes = [60, 62, 64, 66, 68, 69, 71];
        levelScales[1][8].notes = [60, 62, 64, 66, 67, 68, 70];
        levelScales[1][9].notes = [60, 62, 63, 65, 66, 68, 70];

        // Level 3 Scales
        levelScales[2].push(ScaleInfo("Lydian Pentatonic", new uint8[](5)));
        levelScales[2].push(ScaleInfo("Locrian Pentatonic", new uint8[](5)));
        levelScales[2].push(ScaleInfo("Scriabin", new uint8[](5)));
        levelScales[2].push(ScaleInfo("Hirajoshi", new uint8[](5)));
        levelScales[2].push(ScaleInfo("Iwato", new uint8[](5)));
        levelScales[2].push(ScaleInfo("Super Locrian", new uint8[](7)));
        levelScales[2].push(ScaleInfo("Hungarian Major", new uint8[](7)));
        levelScales[2].push(ScaleInfo("Romanian Minor", new uint8[](7)));
        levelScales[2].push(ScaleInfo("Double Harmonic Minor", new uint8[](7)));
        levelScales[2].push(ScaleInfo("Altered Dorian", new uint8[](7)));

        levelScales[2][0].notes = [60, 62, 65, 67, 68];
        levelScales[2][1].notes = [60, 61, 63, 66, 68];
        levelScales[2][2].notes = [60, 61, 64, 66, 68];
        levelScales[2][3].notes = [60, 61, 65, 68, 70];
        levelScales[2][4].notes = [60, 61, 65, 67, 70];
        levelScales[2][5].notes = [60, 61, 63, 64, 66, 68, 69];
        levelScales[2][6].notes = [60, 63, 64, 66, 67, 69, 70];
        levelScales[2][7].notes = [60, 62, 63, 66, 67, 69, 70];
        levelScales[2][8].notes = [60, 61, 64, 65, 67, 68, 71];
        levelScales[2][9].notes = [60, 62, 63, 66, 67, 69, 71];

        // Level 4 Scales
        levelScales[3].push(ScaleInfo("Harmonic Minor", new uint8[](7)));
        levelScales[3].push(ScaleInfo("Double Harmonic Major", new uint8[](7)));
        levelScales[3].push(ScaleInfo("Hungarian Minor", new uint8[](7)));
        levelScales[3].push(ScaleInfo("Flamenco", new uint8[](7)));
        levelScales[3].push(ScaleInfo("Prometheus Scale", new uint8[](6)));
        levelScales[3].push(ScaleInfo("Istrian Scale", new uint8[](5)));
        levelScales[3].push(ScaleInfo("Augmented Scale", new uint8[](6)));
        levelScales[3].push(ScaleInfo("Byzantine Scale", new uint8[](7)));
        levelScales[3].push(ScaleInfo("Spanish Gypsy", new uint8[](7)));

        levelScales[3][0].notes = [60, 62, 63, 65, 67, 69, 71];
        levelScales[3][1].notes = [60, 61, 64, 65, 67, 69, 70];
        levelScales[3][2].notes = [60, 61, 64, 66, 68, 70, 71];
        levelScales[3][3].notes = [60, 61, 63, 65, 67, 69, 72];
        levelScales[3][4].notes = [60, 62, 64, 66, 69, 70];
        levelScales[3][5].notes = [60, 61, 63, 64, 66];
        levelScales[3][6].notes = [60, 63, 64, 67, 68, 71];
        levelScales[3][7].notes = [60, 61, 64, 65, 67, 68, 71];
        levelScales[3][8].notes = [60, 61, 64, 65, 67, 70, 71];

        // Level 5 Scales
        levelScales[4].push(ScaleInfo("Lydian Augmented", new uint8[](8)));
        levelScales[4].push(ScaleInfo("Melodic Minor", new uint8[](8)));
        levelScales[4].push(ScaleInfo("Lydian Dominant", new uint8[](8)));
        levelScales[4].push(ScaleInfo("Enigmatic", new uint8[](8)));
        levelScales[4].push(ScaleInfo("Persian", new uint8[](8)));
        levelScales[4].push(ScaleInfo("Nine Tone Scale", new uint8[](9)));
        levelScales[4].push(ScaleInfo("Enigmatic Minor", new uint8[](7)));
        levelScales[4].push(ScaleInfo("Composite Blues", new uint8[](9)));
        levelScales[4].push(ScaleInfo("Lydian #2 #6", new uint8[](7)));
        levelScales[4].push(ScaleInfo("Artificial Scale", new uint8[](7)));

        levelScales[4][0].notes = [60, 62, 64, 66, 67, 69, 71, 73];
        levelScales[4][1].notes = [60, 62, 63, 65, 67, 68, 70, 72];
        levelScales[4][2].notes = [60, 62, 64, 65, 67, 69, 70, 72];
        levelScales[4][3].notes = [60, 61, 63, 65, 67, 69, 71, 73];
        levelScales[4][4].notes = [60, 62, 63, 65, 66, 68, 70, 72];
        levelScales[4][5].notes = [60, 61, 63, 64, 66, 67, 69, 70, 72];
        levelScales[4][6].notes = [60, 61, 64, 66, 67, 70, 71];
        levelScales[4][7].notes = [60, 62, 63, 64, 67, 68, 69, 70, 71];
        levelScales[4][8].notes = [60, 63, 64, 66, 67, 70, 71];
        levelScales[4][9].notes = [60, 62, 65, 67, 69, 72, 74];
    }

    function getParams() public pure returns (uint, uint) {
        return (ticksPerQuarterNote, bpm);
    }

    function getRandomScale(Rand memory rnd) internal view returns (ScaleInfo memory) {
        uint level = rnd.lvl().to_lvl_1();
        uint totalScaleCount = 0;
        for (uint l = 0; l <= level; l++) {
            totalScaleCount += levelScales[l].length;
        }

        uint scaleIndex = rnd.next() % totalScaleCount;
        uint currentScaleIndex = 0;

        for (uint l = 0; l <= level; l++) {
            if (scaleIndex < currentScaleIndex + levelScales[l].length) {
                return levelScales[l][scaleIndex - currentScaleIndex];
            }
            currentScaleIndex += levelScales[l].length;
        }

        revert("Invalid scale index. "); 
    }


    function generateLoopableMelody(Rand memory rnd) public view returns (Note[] memory, uint8 instrument, ScaleInfo memory) {
        uint level = rnd.lvl().to_lvl_1();        

        ScaleInfo memory scale = getRandomScale(rnd);

        uint numNotes = 2 + (level) + rnd.next() % (level + 2);
        uint minUniqueNotes = level; 

        Note[] memory melody = new Note[](numNotes);
        bool[] memory usedNotes = new bool[](scale.notes.length); 
        uint uniqueCount = 0;
        uint lastStartTime = 0;
        uint i = 0;

        uint quantizationInterval = 30; 
        uint swingFraction = 1; 

        // Select a random instrument for the melody
        instrument = uint8(rnd.next() % 127); // Random instrument selection from 0 to 127

        while (i < numNotes) {
            uint noteIndex = rnd.next() % scale.notes.length;
            if (!usedNotes[noteIndex]) {
                usedNotes[noteIndex] = true;
                uniqueCount++;
            }

            uint durationIndex = rnd.next() % durations.length;
            uint duration = durations[durationIndex];

            // Calculate the initial start time based on the quantization grid
            uint startTime = lastStartTime + quantizationInterval;

            // Apply swing to alternate notes
            if (i % 2 == 1) {
                startTime += quantizationInterval * swingFraction / 2;
            }

            // Quantize the start time
            startTime = (startTime + quantizationInterval / 2) / quantizationInterval * quantizationInterval;

            // Adjust duration to end on the next quantization interval boundary
            duration = (duration + quantizationInterval - 1) / quantizationInterval * quantizationInterval;

            melody[i] = Note({
                note: scale.notes[noteIndex],
                velocity: 64 + uint8(noteIndex % 32),
                startTime: startTime, //don't divide by 10 here, most likely the reason for speed
                duration: duration //same here 
            });

            lastStartTime = startTime;
            i++;

            if (uniqueCount >= minUniqueNotes && i >= numNotes) {
                break;
            }
        }

        return (melody, instrument, scale);
    }


    function generateMidiBase64(Note[] memory notes, uint8 instrument) public pure returns (string memory) {        
        uint8[] memory midiNotes = new uint8[](notes.length);
        uint8[] memory velocities = new uint8[](notes.length);
        uint256[] memory noteStartTimes = new uint256[](notes.length);
        uint256[] memory noteDurations = new uint256[](notes.length);  // Renamed to noteDurations

        for (uint i = 0; i < notes.length; i++) {
            midiNotes[i] = notes[i].note;
            velocities[i] = notes[i].velocity;
            noteStartTimes[i] = notes[i].startTime;
            noteDurations[i] = notes[i].duration;  // Use the renamed variable
        }

        return generateMidiData(midiNotes, velocities, noteStartTimes, noteDurations, instrument);
    }


    struct NoteCommand {
        uint256 time;
        bool command;
        uint8 note;
        uint8 velocity;        
        bool used;
    }

    function generateMidiData(
        uint8[] memory notes,
        uint8[] memory velocities,
        uint256[] memory startTimes,
        uint256[] memory noteDurations,  
        uint8 instrument  
    ) internal pure returns (string memory) {
        require(notes.length == velocities.length && notes.length == startTimes.length && notes.length == noteDurations.length, "Array lengths must match");
        require(instrument < 128, "Instrument must be between 0 and 127");

        uint cmdLength = notes.length * 2;

        bytes memory headerChunk;
        bytes memory trackChunk;

        // Header Chunk
        {
            bytes4 chunkType = hex"4d546864"; // 'MThd'
            bytes2 format = hex"0001";        // MIDI format 1
            bytes2 ntrks = hex"0001";         // Number of tracks
            bytes2 division = hex"0078";     // 120 ticks per quarter note
            // bytes2 division = hex"000c";     // 12 ticks per quarter note
            bytes memory header = abi.encodePacked(format, ntrks, division);
            headerChunk = abi.encodePacked(chunkType, bytes4(uint32(header.length)), header);
        }
        // Track Chunk
        {
            bytes4 chunkType = hex"4d54726b"; // 'MTrk'
            bytes memory trackData;

            bytes memory programChange = abi.encodePacked(_encodeVarLen(0), hex"C0", instrument);
            trackData = abi.encodePacked(programChange);  

            NoteCommand[] memory noteCommands = new NoteCommand[](cmdLength);

            // create an unsorted array  of commands
            for (uint i = 0; i < cmdLength/2; i++) {
                uint8 note = notes[i];
                uint8 velocity = velocities[i];
                uint256 onTime = startTimes[i];
                uint256 duration = noteDurations[i];  
                uint256 offTime = onTime + duration;

                noteCommands[2*i] = NoteCommand(onTime, true, note, velocity, false);
                noteCommands[2*i+1] = NoteCommand(offTime, false, note, 0, false);
            }

            NoteCommand[] memory sortedCommands = new NoteCommand[](cmdLength);

            // create a sorted array of commands
            uint lastCommandTime = 0;            
            for (uint i = 0; i < cmdLength; i++) {
                uint earliestTimeAfterLast = 10**10;
                uint indexPosition = 0;
                for (uint j = 0; j < noteCommands.length; j++) {
                    if  (
                            noteCommands[j].time < earliestTimeAfterLast && 
                            noteCommands[j].time >= lastCommandTime &&
                            !noteCommands[j].used
                        ) {
                        earliestTimeAfterLast = noteCommands[j].time;
                        indexPosition = j;
                    }
                }
                sortedCommands[i] = noteCommands[indexPosition];
                lastCommandTime = earliestTimeAfterLast;   
                noteCommands[indexPosition].used = true;             
            }

            // create the track data
            uint midiTime = 0;
            for (uint i = 0; i < cmdLength; i++) {
                NoteCommand memory cmd = sortedCommands[i];
                uint deltaTime = cmd.time - midiTime;                
                bytes memory cmdBytes;

                if (cmd.command) {
                    cmdBytes = abi.encodePacked(_encodeVarLen(deltaTime), hex"90", cmd.note, cmd.velocity);
                } else {
                    cmdBytes = abi.encodePacked(_encodeVarLen(deltaTime), hex"80", cmd.note, uint8(0));                     
                }

                trackData = abi.encodePacked(trackData, cmdBytes);

                midiTime = sortedCommands[i].time;
            }

            bytes3 endOfTrack = hex"FF2F00"; 
            trackData = abi.encodePacked(trackData, _encodeVarLen(0), endOfTrack);

            trackChunk = abi.encodePacked(chunkType, bytes4(uint32(trackData.length)), trackData);
        }

        bytes memory midiFile = abi.encodePacked(headerChunk, trackChunk);
        return string(abi.encodePacked("data:audio/midi;base64,", Base64.encode(midiFile)));
    }

    function _encodeVarLen(uint256 value) private pure returns (bytes memory) {
        bytes memory varLenBytes = new bytes(4);  
        uint length = 0;
        do {
            varLenBytes[length++] = bytes1(uint8(128 | (value & 127))); // Set the MSB to 1
            value >>= 7;
        } while (value != 0);
        varLenBytes[length-1] &= 0x7F; 

        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = varLenBytes[i];
        }
        return result;
    }

    function getNoteTimingsInMilliseconds(Note [] memory melody) public pure returns (uint[] memory startTimesMs, uint[] memory durationsMs) {
        uint ticksToMs = 60000 / (bpm * ticksPerQuarterNote);
        startTimesMs = new uint[](melody.length);
        durationsMs = new uint[](melody.length);

        for (uint i = 0; i < melody.length; i++) {
            startTimesMs[i] = melody[i].startTime * ticksToMs;
            durationsMs[i] = melody[i].duration * ticksToMs;
        }

        return (startTimesMs, durationsMs);
    }    
}
