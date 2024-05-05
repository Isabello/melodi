// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Ownable.sol";
import "./MidiGenerator.sol";
import "./ArtGenerator.sol";                

contract Generator is Ownable {
    using LayersLib for uint;
    using RandLib for Rand;
    using RandLib for string[];
    using Converter for uint;
    using Converter for uint8;

    string website = "https://midi.blue";
    string description = "First Audio ERC-20i. Use website for maximum compatibility. $MIDI";

    MidiGenerator midiGenerator;
    ArtGenerator artGenerator;

    function setMidiGenerator(address _midiGenerator) external onlyOwner {
        midiGenerator = MidiGenerator(_midiGenerator);
    }

    function setArtGenerator(address _artGenerator) external onlyOwner {
        artGenerator = ArtGenerator(_artGenerator);
    }
    
    function getSvg(
        SeedData calldata seed_data
    ) external view returns (string memory) {
        Rand memory rnd = Rand(seed_data.seed, 0, seed_data.extra);
        MultiModalData memory data = this.getData(rnd); 
        string memory svg = artGenerator.melodyToSvg(data, rnd);

        return svg;
    }


    function getData(
        Rand memory rnd
    ) external view returns (MultiModalData memory) {        
        (Note[] memory melody, uint8 instrument, ScaleInfo memory scale) = midiGenerator.generateLoopableMelody(rnd);
        string memory midiBase64 = midiGenerator.generateMidiBase64(melody, instrument);
        (uint ticksPerQuarterNote, uint bpm) = midiGenerator.getParams();
        MultiModalData memory data = artGenerator.setMultiModalData(rnd, scale, melody, midiBase64, ticksPerQuarterNote, bpm, instrument);

        return data;
    }

    function getMeta(
        SeedData calldata seed_data
    ) external view returns (string memory) {        
        Rand memory rnd = Rand(seed_data.seed, 0, seed_data.extra);
        MultiModalData memory data = this.getData(rnd);        
        bytes memory lvl = abi.encodePacked('"level":', (data.lvl+1).toString());
        bytes memory scale = abi.encodePacked(',"scale":"',data.scale.name, '"');
        bytes memory duration = abi.encodePacked(',"duration":',data.totalDuration.toString());
        bytes memory durationMs = abi.encodePacked(',"durationMs":',data.totalDurationMs.toString());
        bytes memory colors = abi.encodePacked(
            ',"barColorTop":"',
            data.barColorTop,
            '","barColorBottom":"',
            data.barColorBottom,
            '"'
        );

        bytes memory backGround = abi.encodePacked(
            ',"hasBackground":',
            data.hasBackground ? "true" : "false",
            ',"hasSpecialBackground":',
            data.hasSpecialBackground.toString(),
            ',"backgroundColor":"',
            data.backgroundColor,
            '"',
            ',"backgroundIconId":',
            data.backgroundIconId.toString(),
            ',"backgroundIconColor":"',
            data.backgroundIconColor,
            '"'
        );

        bytes memory midiBase64 = abi.encodePacked(
            ',"bpm":',
            data.bpm.toString(),
            ',"ticksPerQuarterNote":',
            data.ticksPerQuarterNote.toString(),
            ',"instrument":',
            data.instrument.toString()            
        );

        // add website and description
        bytes memory websiteBytes = abi.encodePacked(',"website":"', website, '"');
        bytes memory descriptionBytes = abi.encodePacked(',"description":"', description, '"');

        return
            string(
                abi.encodePacked(
                    "{",
                    lvl,
                    scale,
                    duration,
                    durationMs,
                    colors,
                    backGround,
                    midiBase64,
                    websiteBytes,
                    descriptionBytes,
                    "}"
                )
            );
    }
}
