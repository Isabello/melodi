// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/math/Math.sol";
// import "forge-std/console.sol";
// import "./MidiGenerator.sol";
import "../lib/Helpers.sol";
import {IJelliExtension} from "../lib/IJelliExtension.sol";
import {IFungi} from "../lib/IFungi.sol";
import "../Ownable.sol";

contract ArtGenerator is Ownable {
    using LayersLib for uint;    

    using RandLib for Rand;
    using Converter for uint;
    using Converter for uint8;

    IJelliExtension jelliExtension;
    IFungi iFungi;

    string website = "https://midi.blue";
    string description = "First Audio ERC-20i. Use website for maximum compatibility. $MIDI ";
    string r = "a";


    uint256 private number;

    uint private gridStrokeWidth = 4;
    uint private halfStrokeWidth = 2;
    uint private height = 288;
    uint private width = 288;
    uint private gridSpacingY = 12;
    uint private gridSpacingX = 32;
    
    uint private BarMaskBaseOffsetYChunks = (256-40) * height /256  / gridSpacingY;
    uint private BarMaskBaseOffsetY = BarMaskBaseOffsetYChunks * gridSpacingY;

    // how much to extend the normalisedNote past the end of the normalisedNote
    uint private overlap100 = 0;//0.02 * 100;

    uint private movementRangeChunks = 145 * height /256;
    uint private movementRange = (movementRangeChunks / gridSpacingY) * gridSpacingY;

    string[][] private level1BarColors = [
        ["#333333","#333333"],
        ["#250352","#250352"],
        ["#63425F","#63425F"],
        ["#483D8B","#483D8B"],
        ["#7E6F21","#7E6F21"],
        ["#800000","#800000"],
        ["#36454F","#36454F"],
        ["#3E2723","#3E2723"],
        ["#81421C","#81421C"],
        ["#13451D","#13451D"]
    ];


    string[][] private level2BarColors = [
        ["#470890","#470890"],
        ["#8B5075","#8B5075"],
        ["#516FA7","#516FA7"],
        ["#B6AB45","#B6AB45"],
        ["#8D608C","#8D608C"],
        ["#008B8B","#008B8B"],
        ["#4682B4","#4682B4"],
        ["#B24935","#B24935"],
        ["#823136","#823136"],
        ["#648585","#648585"]
    ];


    string[][] private level3BarColors = [
        ["#3A007D","#DB2FCD"],
        ["#1C2852","#00FDFD"],
        ["#000000","#7F007F"],
        ["#7E0120","#F90000"],
        ["#003B00","#31CB31"],
        ["#02118D","#80C4E6"],
        ["#3F2407","#F7D000"],
        ["#3E2723","#BFAE7E"],
        ["#C3000F","#C3000F"],
        ["#CAA502","#CAA502"]        
    ];


    string[][] private level4BarColors = [
        ["#800080", "#FD00FD"],
        ["#008080", "#00EEEE"],
        ["#808000", "#FCFC00"],
        ["#4B0082", "#0100FE"],
        ["#8B4513", "#FAA101"],
        ["#8E0707", "#FD6146"],
        ["#191970", "#01B9FA"],
        ["#158DCC", "#D7BDE2"],
        ["#EAAC22", "#316CDA"],
        ['#D71424', '#F86482']
    ];


    string[][] private level5BarColors = [
        ["#7DF7FF", "#7DF7FF"],
        ["#39FF14", "#40E1CB"],
        ["#FF69B4", "#BE56D1"],
        ["#8A2BE2", "#F3058A"],
        ["#F3058A", "#FFFD00"],
        ["#E1E1E1", "#1FFFFF"],
        ["#31C831", "#238D23"],
        ["#FF2400", "#FA9E01"],
        ["#7DF9FF", "#F947AE"],
        ["#FF008F", "#F947AE"]
        
    ];

    string[][][] private levelBarColors = [
        level1BarColors,
        level2BarColors,
        level3BarColors,
        level4BarColors,
        level5BarColors
    ];

    string[] level1BackgroundIconColors;
    string[] level2BackgroundIconColors;

    string[] level3BackgroundIconColors = [
        "#FFA07A",
        "#CDDC39",
        "#DB7093",
        "#FFDEAD",
        "#843D48",
        "#FFFFE0",
        "#68B57B",
        "#F6BB07",
        "#9C27B0",
        "#3F51B5"
    ];

    string[] level4BackgroundIconColors = [
        "#7DCEA0",
        "#F5B041",
        "#85C1E9",
        "#F7DC6F",
        "#D6EAF8",
        "#DC77D1",
        "#EB674E",
        "#58D68D",
        "#5C52C2",
        "#8E44AD"
    ];

    string[] level5BackgroundIconColors = [
        "#905640",
        "#7C1D41",
        "#2D732D",
        "#571D62",
        "#0D4646",
        "#828282",
        "#1A2566",
        "#713F41",
        "#649464"
    ];    

    string[][] backgroundIconColors = [
        level1BackgroundIconColors,
        level2BackgroundIconColors,
        level3BackgroundIconColors,
        level4BackgroundIconColors,
        level5BackgroundIconColors
    ];

    string[] lvl1BackgroundColors;
    string[] lvl2BackgroundColors;

    string[] lvl3BackgroundColors = [
        "#3D3D3D"
    ];

    string[] lvl4BackgroundColors = [ 
        "#FADBD8",
        "#FDEBD0",
        "#AED6F1",
        "#C8DE80",
        "#5499C7",
        "#A3E4D7",
        "#FAD7A0",
        "#ABEBC6",
        "#CC759A",
        "#D7BDE2"
    ];

    string[] lvl5BackgroundColors = [
        "#0B0D33",
        "#10391B",
        "#290D3F",
        "#1E1A2C",
        "#1F1F1F",
        "#122536",
        "#5F5424",
        "#381B1C",
        "#460D0D",
        "#3B222C"
    ];

    string[][] backgroundColors = [
        lvl1BackgroundColors,
        lvl2BackgroundColors,
        lvl3BackgroundColors,
        lvl4BackgroundColors,
        lvl5BackgroundColors
    ];


    string[][] private level1BackgroundIcons;
    string[][] private level2BackgroundIcons;
    string[][] private level3BackgroundIcons;
    string[][] private level4BackgroundIcons;
    string[][] private level5BackgroundIcons;

    string[][][] private levelBackgroundIcons = [                
        level1BackgroundIcons,
        level2BackgroundIcons,
        level3BackgroundIcons,
        level4BackgroundIcons,
        level5BackgroundIcons
    ];

    constructor () {
    }

    function setFungi(address _fungi) external onlyOwner() {
        iFungi = IFungi(_fungi);
    }

    function setJelliExtension(address _jelliExtension) external onlyOwner {        
        jelliExtension = IJelliExtension(_jelliExtension);
    }

    function getBackgroundIcons(uint level) public view returns (string[][] memory) {
        return levelBackgroundIcons[level];
    }

    function insertBackgroundIcon(
        string[] memory colorSplitParts, 
        uint8 level
    ) external onlyOwner {
        levelBackgroundIcons[level].push(colorSplitParts);
    }

    function setMultiModalData(
        Rand memory rnd,
        ScaleInfo memory scale,
        Note[] memory melody,
        string memory midiBase64, 
        uint ticksPerQuarterNote, 
        uint bpm,   
        uint8 instrument
    ) public view returns (MultiModalData memory){
        MultiModalData memory data;
        data.lvl = rnd.lvl().to_lvl_1();
        data.uuid = rnd.getUuid();                
        data.bpm = bpm;
        data.ticksPerQuarterNote = ticksPerQuarterNote;
        data.instrument = instrument;
        data.scale = scale;
        data.melody = melody;
        data.midiBase64 = midiBase64;
        data.totalDuration = getTotalDuration(melody);
        data.totalDurationMs = data.totalDuration * 60000 / (bpm*ticksPerQuarterNote);
        setBarColors(rnd, data);
        setBackground(rnd, data);
        return data;
    }

    function setBarColors(
        Rand memory rnd,
        MultiModalData memory data
    ) private view {        
        uint barColorId = rnd.next() % levelBarColors[data.lvl].length;
        data.barColorTop = levelBarColors[data.lvl][barColorId][0];
        data.barColorBottom = levelBarColors[data.lvl][barColorId][1];        
    }

    function setBackground(
        Rand memory rnd,
        MultiModalData memory data
    ) private view {
        data.backgroundColor = "#050505";
        if (data.lvl > 1){
            data.hasBackground = true;    

            data.backgroundIconId = rnd.next() % levelBackgroundIcons[data.lvl].length;
            uint backgroundIconColorId = rnd.next() % backgroundIconColors[data.lvl].length;
            data.backgroundIconColor = backgroundIconColors[data.lvl][backgroundIconColorId];
            
            if (data.lvl > 2) {
                uint backgroundColorId = rnd.next() % backgroundColors[data.lvl].length;
                data.backgroundColor = backgroundColors[data.lvl][backgroundColorId];
            }
        }

        if (rnd.next() % 10 == 0) { // 10% chance
            if ((rnd.next() % 3) > 0) {
                data.hasSpecialBackground = 1; // jelli
                data.backgroundIconId = 0;
                data.backgroundIconColor = "";
            } else {
                data.hasSpecialBackground = 2; // iFungi
                data.backgroundIconId = 0;
                data.backgroundIconColor = "";
            }                  
        }
    }
    

    function getTotalDuration(Note[] memory melody) private pure returns (uint256) {
        Note memory lastNote = melody[melody.length-1];
        return lastNote.startTime + lastNote.duration;
    }

    function getScalePosition(uint256 note, ScaleInfo memory scale) public pure returns (uint8) {
        for (uint8 i = 0; i < scale.notes.length; i++) {
            if (scale.notes[i] == note) {
                return i;
            }
        }        
        revert("dNote not found in scale");
    }

    struct oneKeyCommands {
        NormalisedNote[] normalisedNotes;
        uint8 normalisedNoteN;
        string[] normalisedNoteStyles;
        string[] normalisedNoteWrappers;   
        string jitterStyle;     
    }

    function melodyToNormalisedNotes(MultiModalData memory data) public pure returns (oneKeyCommands[] memory){ 
        oneKeyCommands[] memory allKeyCommands = new oneKeyCommands[](data.scale.notes.length);
        // oneKeyCommands[] memory allKeyCommands;

        for (uint256 i = 0; i < data.melody.length; i++) {
            NormalisedNote memory normalisedNote;
            normalisedNote.startFraction10e6 = data.melody[i].startTime * 1_000_000 / data.totalDuration;
            normalisedNote.durationFraction10e6 = data.melody[i].duration * 1_000_000 / data.totalDuration;
            normalisedNote.velocity = data.melody[i].velocity;
            
            uint8 position = getScalePosition(data.melody[i].note, data.scale);

            if(allKeyCommands[position].normalisedNotes.length == 0) {
                allKeyCommands[position].normalisedNotes = new NormalisedNote[](32);  // Initialize with max repeated normalisedNotes of one type possible                
                allKeyCommands[position].normalisedNoteN = 0;
            }

            uint normalisedNoteIndex = allKeyCommands[position].normalisedNoteN;
            allKeyCommands[position].normalisedNotes[normalisedNoteIndex] = normalisedNote;

            allKeyCommands[position].normalisedNoteN = allKeyCommands[position].normalisedNoteN + 1;
        }

        return allKeyCommands;
    }

    function generateNormalisedNoteStyle(
        uint8 normalisedNoteN, 
        uint8 normalisedNotePos, 
        NormalisedNote memory normalisedNote, 
        MultiModalData memory data
    ) public view returns (string memory) {
        uint256 scaledVelocity = (uint256)(Math.max(32, Math.min(128, normalisedNote.velocity)) * (movementRange) / (128 - 32));
        scaledVelocity = scaledVelocity / gridSpacingY;
        scaledVelocity = scaledVelocity * gridSpacingY;

        uint256 steps = scaledVelocity / gridSpacingY;
        uint256 startPercent = normalisedNote.startFraction10e6 * 100 / 1_000_000;      
        uint256 endPercent = Math.min(
            (
                normalisedNote.startFraction10e6 * 100 / 1_000_000 + 
                normalisedNote.durationFraction10e6 * 100 / 1_000_000
            ) + overlap100/100, 
            100
        );

        string memory normalisedNoteName = string(abi.encodePacked(normalisedNoteN.toString(), '_', normalisedNotePos.toString(), '_', data.uuid));        

        string memory result = string(abi.encodePacked(
            "@keyframes normalisedNote", normalisedNoteName, " {\n",
            "    0%, ", startPercent.toString(), "%, ", endPercent.toString(), "%, 100% { transform: translateY(-0px); }\n",
            "    ", startPercent.toString(), ".1% { transform: translateY(-", scaledVelocity.toString(), "px); animation-timing-function: steps(", steps.toString(), "); }\n",
            "}\n",
            ".moving-bar", normalisedNoteName, " {",
            "    animation: normalisedNote", normalisedNoteName, " ", data.totalDurationMs.toString(), "ms steps(", steps.toString(), ") 1;",
            "}"
        ));

        return result;
    }

    function generateNormalisedNoteStyles(
        oneKeyCommands[] memory allKeyCommands, 
        MultiModalData memory data
    ) public view returns (oneKeyCommands[] memory) {        
        for (uint8 i = 0; i < allKeyCommands.length; i++) {
            uint normalisedNoteN = allKeyCommands[i].normalisedNoteN;
            string[] memory currentNoteStyles = new string[](normalisedNoteN);
            string[] memory currentNoteWrappers = new string[](normalisedNoteN);
            for (uint8 j = 0; j < normalisedNoteN; j++) {
                currentNoteStyles[j] = generateNormalisedNoteStyle(i, j, allKeyCommands[i].normalisedNotes[j], data);
                currentNoteWrappers[j] = string(abi.encodePacked("moving-bar", i.toString(), "_", j.toString(), '_', data.uuid));
            }
            allKeyCommands[i].normalisedNoteStyles = currentNoteStyles;
            allKeyCommands[i].normalisedNoteWrappers = currentNoteWrappers;
        }
        return allKeyCommands;
    }    

    function generateJitterStyle(
        uint8 normalisedNoteN, 
        string memory uuid, 
        Rand memory rnd
    ) public view returns (string memory) {
        uint256 jitterDuration = (rnd.next() % 6 + 6) * 100; 
        uint256 jitterSteps = rnd.next() % 2+1; 
        uint jitterAmplitude = jitterSteps * gridSpacingY;

        string memory result = string(abi.encodePacked(
            "@keyframes jitter", normalisedNoteN.toString(), '_', uuid, " {\n",
            "    0%, 100% { transform: translateY(0px); }\n",
            "    50% { transform: translateY(-", jitterAmplitude.toString(), "px); }\n",
            "\n}\n",
            ".jitter-bar_", normalisedNoteN.toString(), '_', uuid, " {",
            "    animation: jitter", normalisedNoteN.toString(), '_', uuid, " ", jitterDuration.toString(), "ms steps(", jitterSteps.toString(), ") infinite;",
            "}"
        ));

        return result;
    }

    function generateJitterStyles(
        oneKeyCommands[] memory allKeyCommands, 
        MultiModalData memory data, 
        Rand memory rnd
    ) public view returns (oneKeyCommands[] memory) {
        for (uint8 i = 0; i < allKeyCommands.length; i++) {
            allKeyCommands[i].jitterStyle = generateJitterStyle(i, data.uuid, rnd);
        }
        return allKeyCommands;
    }

    function generateWrappedBarMasks (oneKeyCommands[] memory allKeyCommands, string memory uuid) public view returns (string[] memory) {
        uint nBars = allKeyCommands.length;
        uint width1000 = width * 1000 / nBars;
        string[] memory wrappedBarMasks = new string[](nBars);

        for (uint i = 0; i < nBars; i++) {
            string memory wrappedBarMask = string(abi.encodePacked(
                '<g class="jitter-bar_', i.toString(), '_', uuid, '">'
            ));

            for (uint j = 0; j < allKeyCommands[i].normalisedNoteWrappers.length; j++) {
                wrappedBarMask = string(abi.encodePacked(
                    wrappedBarMask, 
                    '<g class="', allKeyCommands[i].normalisedNoteWrappers[j], '">'
                ));
            }

            uint x = i*width1000/1000+halfStrokeWidth;
            uint y = BarMaskBaseOffsetY+halfStrokeWidth;
            wrappedBarMask = string(abi.encodePacked(
                wrappedBarMask, 
                '<rect x="', x.toString(), 'px" y="', y.toString(), 
                'px" width="', (width1000/1000).toString(), 'px" height="', ((height+gridStrokeWidth)*10).toString(), 
                'px" class="cover-bar" />'
            ));

            for (uint j = 0; j < allKeyCommands[i].normalisedNoteWrappers.length; j++) {
                wrappedBarMask = string(abi.encodePacked(wrappedBarMask, '</g>'));
            }

            wrappedBarMask = string(abi.encodePacked(wrappedBarMask, '</g>'));
            wrappedBarMasks[i] = wrappedBarMask;
        }

        return wrappedBarMasks;
    }

    function generateVerticalGridlines(uint nBars) public view returns (string memory) {
        string memory verticalGridlines;
        uint width1000 = width * 1000 / nBars;
        uint y2 = height+gridStrokeWidth;
        for (uint i = 0; i < nBars; i++) {
            uint x = i*width1000/1000 + halfStrokeWidth;                  
            verticalGridlines = string(abi.encodePacked(verticalGridlines,generateLine(x, 0, x, y2)));
        }
        verticalGridlines = string(abi.encodePacked(verticalGridlines,generateLine(width+halfStrokeWidth, 0, width+halfStrokeWidth, y2)));
        return verticalGridlines;
    }

    function generateLine(uint x1, uint y1, uint x2, uint y2) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<line x1="', x1.toString(), 'px" y1="', y1.toString(), 'px" x2="', x2.toString(), 'px" y2="', y2.toString(), 'px" class="grid-line" />'
        ));
    }

    function generateHorizontalGridlines() public view returns (string memory) {
        string memory result = "";
        uint currentY = 0;
        while (currentY <= (height+gridStrokeWidth - gridSpacingY/2)) {
            uint y1 = currentY+halfStrokeWidth;
            uint x2 = width+gridStrokeWidth;
            uint y2 = currentY+halfStrokeWidth;
            result = string(abi.encodePacked(
                result, 
                generateLine(0, y1, x2, y2)
            ));
            currentY += gridSpacingY;
        }
        result = string(abi.encodePacked(
            result, 
            generateLine(0, (height+gridStrokeWidth), width+gridStrokeWidth, (height+gridStrokeWidth))
        ));

        return result;
    }

    function generateSvgStart(MultiModalData memory data) public view returns (string memory) {
        uint total_width = width + gridStrokeWidth;
        uint total_height = height + gridStrokeWidth;
        string memory prefix = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" ',
            'viewBox="0 0 ', total_width.toString(), ' ', total_height.toString(), '" preserveAspectRatio="xMidYMid meet"',
            '>',
            '<metadata>',
                '<site> ',website,' </site>',
                '<description>',description,'</description>',
                '<interactive>',
                    '<el>',
                        '<midi>',
                            '<base64>',
                                data.midiBase64,
                            '</base64>',
                            '<not-supported-class>midi-not-supported</not-supported-class>',
                        '</midi>',
                        '<animation>',
                            '<classPrefix>',
                                'moving-bar',
                            '</classPrefix>',
                        '</animation>',
                        '<uuid>',
                            data.uuid,
                        '</uuid>',
                    '</el>',
                '</interactive>',
            '</metadata>',
            '<defs>',
            '<linearGradient id="gradient',data.uuid,'" x1="0%" y1="30%" x2="0%" y2="100%">',
            '<stop offset="0%" style="stop-color:', data.barColorTop, ';stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:', data.barColorBottom, ';stop-opacity:1" />',
            '</linearGradient>',
            '<style>',
            '[class^="moving-bar"] {',
                'animation-iteration-count: infinite !important;',
            '}',            
            '.grid-line {',
            '   stroke: black;',
            '   stroke-width: ', gridStrokeWidth.toString(), ';',
            '}',
            '.cover-bar {',
            '   fill: white;',
            '}'
        ));
        return prefix;
    }

    function generateBackgroundRect(MultiModalData memory data) public view returns (string memory) {

        string memory backgroundGradient = string(abi.encodePacked(
            '<rect x="', (halfStrokeWidth).toString(), 
                '" y="', (halfStrokeWidth).toString(), 
                '" width="', width.toString(), 
                '" height="', height.toString(), 
                '" fill="', data.backgroundColor,'" />'
            ));
        return backgroundGradient;
    }   

    function generateSvgMiddle(MultiModalData memory data) public view returns (string memory) {
        string memory backgroundRect = generateBackgroundRect(data);
        string memory middle = string(abi.encodePacked('    </style></defs>', backgroundRect));
        return middle;
    } 

    function getBackgroundIcon(MultiModalData memory data, Rand memory rnd) public view returns (string memory){
        string memory  fullShape = '';
        
        if (data.hasSpecialBackground > 0) {                        
            if(rnd.seed > 0){
                SeedData memory seed = SeedData(rnd.seed, rnd.extra);   
                if (data.hasSpecialBackground == 1){
                    fullShape = jelliExtension.getSvg(seed);                 
                } else if (data.hasSpecialBackground == 2){
                    fullShape = iFungi.getSvg(seed);
                }                
            }
        }  else if (data.hasBackground) {            
            string[] memory svg_parts = levelBackgroundIcons[data.lvl][data.backgroundIconId]; 
            for (uint i = 0; i < svg_parts.length; i++) {
                if (i == 0) {
                    fullShape = string(abi.encodePacked(fullShape, svg_parts[i]));   
                } else {
                    fullShape = string(abi.encodePacked(fullShape, data.backgroundIconColor, svg_parts[i]));
                }
            }          
        }        

        fullShape = string(abi.encodePacked(
            '<svg x="', (halfStrokeWidth).toString(), 
                '" y="', (halfStrokeWidth).toString(), 
                '" width="', width.toString(), 
                '" height="', height.toString(), 
                '">', 
                fullShape, 
            '</svg>'    
        ));    
        return fullShape;
    }

    function generateGradientRect(MultiModalData memory data) public view returns (string memory) {
        string memory backgroundGradient = string(abi.encodePacked(
            '<rect x="', (halfStrokeWidth).toString(), '" y="', (halfStrokeWidth).toString(), 
            '" width="', width.toString(), '" height="', width.toString(), 
            '" fill="url(#gradient', data.uuid, ')" mask="url(#cover-bar-mask_', data.uuid, ')"/>'
            ));
        return backgroundGradient;
    }    

    function generateIncompatibleElement() public pure returns (string memory) {
        return string(abi.encodePacked(
            '<line class="midi-not-supported" x1="228" x2="308" y1="-20" y2="60" stroke-width="38" stroke="#0001"/>',
            '<svg class="midi-not-supported" height="28" width="28" y="7" x="255" fill="#ffffff66" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512">',
            '<!--!Font Awesome Free 6.5.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.-->',
            '<path d="M301.1 34.8C312.6 40 320 51.4 320 64V448c0 12.6-7.4 24-18.9 29.2s-25 3.1-34.4-5.3L131.8 352H64c-35.3 0-64-28.7-64-64V224c0-35.3 28.7-64 64-64h67.8L266.7 40.1c9.4-8.4 22.9-10.4 34.4-5.3zM425 167l55 55 55-55c9.4-9.4 24.6-9.4 33.9 0s9.4 24.6 0 33.9l-55 55 55 55c9.4 9.4 9.4 24.6 0 33.9s-24.6 9.4-33.9 0l-55-55-55 55c-9.4 9.4-24.6 9.4-33.9 0s-9.4-24.6 0-33.9l55-55-55-55c-9.4-9.4-9.4-24.6 0-33.9s24.6-9.4 33.9 0z"/>',
            '</svg>'
        ));
    }

    function combineSvgParts(
        string memory prefix, 
        oneKeyCommands[] memory allKeyCommands,
        string memory middle, 
        string memory backgroundIconId, 
        string memory backgroundGradient, 
        string[] memory wrappedBarMasks, 
        string memory horizontalGridlines, 
        string memory verticalGridlines,
        string memory incompatibleElement,
        MultiModalData memory data
    ) public pure returns (string memory) {

        string memory result = prefix;

        for (uint i = 0; i < allKeyCommands.length; i++) {
            for (uint j = 0; j < allKeyCommands[i].normalisedNoteStyles.length; j++) {
                result = string(abi.encodePacked(result, allKeyCommands[i].normalisedNoteStyles[j]));
            }
            result = string(abi.encodePacked(result, allKeyCommands[i].jitterStyle));
        }

        result = string(abi.encodePacked(result, 
                                         middle,
                                         backgroundIconId,
                                         backgroundGradient,
                                         '<mask id="cover-bar-mask_', data.uuid, '">'));
        for (uint i = 0; i < wrappedBarMasks.length; i++) {
            result = string(abi.encodePacked(result, wrappedBarMasks[i]));
        }
        result = string(abi.encodePacked(result, '</mask>',
                                         horizontalGridlines,
                                         verticalGridlines,
                                         incompatibleElement,
                                         '</svg>'));
        return result;
    }

    function melodyToSvg( MultiModalData memory data, Rand memory rnd ) public view returns (string memory){             
        oneKeyCommands[] memory allKeyCommands = melodyToNormalisedNotes(data);
        allKeyCommands = generateNormalisedNoteStyles(allKeyCommands, data);
        allKeyCommands = generateJitterStyles(allKeyCommands, data, rnd);

        string[] memory wrappedBarMasks = generateWrappedBarMasks(allKeyCommands, data.uuid);        

        string memory verticalGridlines = generateVerticalGridlines(allKeyCommands.length);
        string memory horizontal_gridlines = generateHorizontalGridlines();
        
        string memory svgStart = generateSvgStart(data);
        string memory svgMiddle = generateSvgMiddle(data);

        string memory backgroundIcon = getBackgroundIcon(data, rnd);
        string memory barGradient = generateGradientRect(data);

        string memory incompatibleElement = generateIncompatibleElement();

        return combineSvgParts(
            svgStart, 
            allKeyCommands, 
            svgMiddle, 
            backgroundIcon, 
            barGradient, 
            wrappedBarMasks, 
            horizontal_gridlines, 
            verticalGridlines,
            incompatibleElement,
            data
        );
    }
}
