// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import {SeedData, Rect, FileData, RandLib, LayersLib, Converter, Rand} from "./lib/Helpers.sol";
import {IJelli} from "./lib/IJelli.sol";


uint constant levelsCount = 5;
uint constant bcgroundsCount = 6;
uint constant groundsCount = 1;
uint8 constant pixelsCount = 24;
uint constant seedLevel1 = 1000; // not actually used 
uint constant seedLevel2 = 21000; // 0.01%
uint constant seedLevel3 = 105000; // 0.05%
uint constant seedLevel4 = 420000; // 0.2%
uint constant seedLevel5 = 1050000; // 0.5%                         

struct MedusaData {
    uint lvl;
    string background;
    string background2;
    bool hasGround;
    uint ground;
    string groundColor;
    bool hasBubble;
    uint bubble;
    string bubbleColor;
    bool hasWeed;
    uint weed;
    string weedColor;
    uint mirrorTime;
    uint bobTime;
    uint tentacle;
    string tentacleColor;
    uint bell;
    string bellColor;
    // bool hasDots;
    // string dotsColor;
}



struct ColorsData {
    string[] lvl0;
    string[] lvl1;
    string[] lvl2;
    string[] lvl3;
    string[] lvl4;
}

library RectLib {
    using RectLib for Rect;
    using RandLib for Rand;
    using RandLib for string[];
    using Converter for uint8;

    function toSvg(
        Rect memory r,
        string memory color
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<rect x='",
                    r.x.toString(),
                    "' y='",
                    r.y.toString(),
                    "' width='",
                    r.width.toString(),
                    "' height='",
                    r.height.toString(),
                    "' fill='",
                    color,
                    "'/>"
                )
            );
    }

    function toSvg(
        Rect[] storage rects,
        string[] storage colors,
        Rand memory rnd
    ) internal view returns (string memory) {
        string memory res;
        for (uint i = 0; i < rects.length; ++i) {
            res = string(
                abi.encodePacked(res, rects[i].toSvg(colors.random(rnd)))
            );
        }
        return res;
    }

    function toSvg(
        Rect[] storage rects,
        string memory color
    ) internal view returns (string memory) {
        string memory res;
        for (uint i = 0; i < rects.length; ++i) {
            res = string(abi.encodePacked(res, rects[i].toSvg(color)));
        }
        return res;
    }
}

contract JelliExtension is Ownable {
    using LayersLib for mapping(uint => mapping(uint => Rect[]));
    using LayersLib for mapping(uint => string[]);
    using LayersLib for uint;
    using RectLib for Rect;
    using RectLib for Rect[];
    using RandLib for Rand;
    using RandLib for string[];
    using Converter for uint;

    // uint8 polyps_count = 7;
    uint8[levelsCount] weedLevelCounts = [7, 7, 7, 7, 7];
    uint8[levelsCount] bubbleLevelCounts = [8, 8, 8, 8, 8];
    uint8[levelsCount] tentacleLevelCounts = [5, 5, 5, 6, 10];
    uint8[levelsCount] bellLevelCounts = [7, 10, 10, 10, 10];    
    // uint8[levelsCount] dotLevelCounts = [5, 7, 10, 10, 10];

    // mapping(uint => Rect[]) polyps;
    mapping(uint => mapping(uint => Rect[])) weeds;
    mapping(uint => mapping(uint => Rect[])) bubbles;
    mapping(uint => mapping(uint => Rect[])) tentacles;
    mapping(uint => mapping(uint => Rect[])) bells;    
    // mapping(uint => mapping(uint => Rect[])) dots;
    mapping(uint => Rect[]) grounds;

    string[] private backgroundColors0 = [
        "#CC93B1",
        "#E0BCA3",
        "#DDAFB7",
        "#A9D8C5",
        "#72C7CC",
        "#DBC9C9",
        "#D6CAA0",
        "#9ED3CB",
        "#4876AF",
        "#95C4B7",
        "#BDC19E",
        "#50B6BF",
        "#D3BAD3"
    ];

    string[] private backgroundColors1 = [
        "#B0E8BE",
        "#76E2D0",
        "#D8CE8F",
        "#F7C5C5",
        "#DCEA96",
        "#BF8FD6",
        "#EABFB9",
        "#E0D6BA",
        "#8B96DD",
        "#C2EFDF",
        "#B1E0E0",
        "#B6D99B",
        "#FFD8DD"
    ];

    string[] private backgroundColors2 = [
        "#96D1CB",
        "#65CEC2",
        "#43CC93",
        "#59DBCD",
        "#86C0D8",
        "#958DD6",
        "#B0E8BE",
        "#D3B3CD",
        "#8AA8CC",
        "#77E5DA",
        "#7D91E0",
        "#E8BECD",
        "#BFDBB3"
    ];

    string[] private backgroundColors3 = [
        "#FFC300",
        "#FFCF99",
        "#FFBFC1",
        "#FFBCC8",
        "#6DC2CA",
        "#3AA3D3",
        "#D18188",
        "#D3A5D1",
        "#F6FFDD",
        "#FFE4C0",
        "#FFA0BB",
        "#BD97D8",
        "#2B2582",
        "#6DA4CA"
    ];

    string[] private backgroundColors4 = [
        "#FFB2EB",
        "#A3F7D5",
        "#3A85FF",
        "#FFC6F2",
        "#FFB26D",
        "#D000FF",
        "#FFFF21",
        "#FF7716",
        "#FF46CE",
        "#84FCFF",
        "#00FFCB",
        "#BDA5FF",
        "#4FC1FF",
        "#59B4FF",
        "#7FFF7F",
        "#A8FFF9",
        "#BFFFE6",
        "#71C692",
        "#854AC4",
        "#3C00C1",
        "#3C81C1",
        "#FF4473",
        "#D6B7FF",
        "#FFC4A5",
        "#8E7CFF"
    ];

    string[] private backgroundColors42 = [
        // "#FFB2EB",
        "#A3F7D5",
        "#3A85FF",
        "#FFC6F2",
        "#FFB26D",
        "#D000FF",
        "#FFFF21",
        "#FF7716",
        "#FF46CE",
        "#84FCFF",
        "#00FFCB",
        "#BDA5FF",
        "#4FC1FF",
        "#59B4FF",
        "#7FFF7F",
        "#A8FFF9",
        "#BFFFE6",
        "#71C692",
        "#854AC4",
        "#3C00C1",
        "#3C81C1",
        "#FF4473",
        "#D6B7FF",
        "#FFC4A5",
        "#8E7CFF"
    ];    

    string[] private bubbleColors = [
        "#A5FFF1",
        "#FFB26B",
        "#F3FFD6",
        "#D4D8C9",
        "#F5E0FF",
        "#9F9BA0",
        "#D1F1FF",
        "#E2F1FF",
        "#FFFFFF",
        "#FF77D6",
        "#C1FFC8",
        "#FFE595",
        "#E8FFE8",
        "#F5E0FF",
        "#FFE4A7",
        "#F5E0FF"
    ];

    string[] private groundColors0 = [
        "#9B5B71",
        "#5B9B7E",
        "#9E8640",
        "#DD8C7A",
        "#478C7A",
        "#CC9380",
        "#4CA188",
        "#B777A2",
        "#0077A2",
        "#AD9474",
        "#7CAFA5",
        "#A08063",
        "#6A5D77",
        "#436E7F",
        "#428255"
    ];

    string[] private groundColors1 = [
        "#CC8F7E",
        "#77531D",
        "#7BBC45",
        "#23756B",
        "#85A094",
        "#DBAF84",
        "#BC8D97",
        "#7CBA9A",
        "#5460A8",
        "#C65B86",
        "#CC94BC",
        "#C4BA00",
        "#436E7F",
        "#AB72C1"
    ];

    string[] private groundColors2 = [
        "#D7E29E",
        "#C3E074",
        "#C3E074",
        "#5267A8",
        "#90CCB4",
        "#C3E074",
        "#90CCB4",
        "#FFD477",
        "#CC6394",
        "#CCA75D",
        "#CCA7BA",
        "#CC694B",
        "#A59578",
        "#FFC47C",
        "#755D33",
        "#E8B534"
    ];

    string[] private groundColors3 = [
        "#E587A0",
        "#FF664F",
        "#EAA4CA",
        "#FFC47C",
        "#6D88CA",
        "#D8A488",
        "#632577",
        "#6F7552",
        "#2C7FB7",
        "#A85E88",
        "#ADA35A",
        "#77625F",
        "#E0AE8F",
        "#8CB773",
        "#D3B16E",
        "#11A062",
        "#83969E",
        "#B5833D",
        "#FFFFFF"
    ];

    string[] private medusaColors0 = [
        "#BC646B",
        "#BC646B",
        "#8D5BA3",
        "#D3CFA0",
        "#D170B1",
        "#50B2D8",
        "#90C46F",
        "#856ED3",
        "#C471B2",
        "#C4712F",
        "#BDC1BF",
        "#C67584",
        "#74AA78",
        "#A85291",
        "#BF96DD",
        "#DB7D81",
        "#E59B87",
        "#017CBF"
    ];

    string[] private medusaColors1 = [
        "#FF9B2F",
        "#5E33E0",
        "#7C3374",
        "#CEE25D",
        "#12A9CC",
        "#E29CA7",
        "#A67FE0",
        "#D86B65",
        "#5ABC79",
        "#6DA1BA",
        "#913E49",
        "#FF6D81",
        "#DBAF00",
        "#A8AEFF",
        "#E59B87",
        "#635158",
        "#D8505D",
        "#C33374"
    ];

    string[] private medusaColors2 = [
        "#7CFF83",
        "#0093FF",
        "#96FFF4",
        "#ECFFBF",
        "#F26979",
        "#FFE1DF",
        "#A793B2",
        "#F2E479",
        "#B1E0C9",
        "#D3FF66",
        "#36E2CE",
        "#E07CF0",
        "#5E33E0",
        "#FF77A4",
        "#8D80DD",
        "#AFCF93",
        "#A8AEFF"
    ];

    string[] private medusaColors3 = [
        "#FF71D3",
        "#D36DE5",
        "#3AE4EA",
        "#D1FFB7",
        "#FFF9D3",
        "#7FE8B9",
        "#FFFFB9",
        "#CC70C5",
        "#E09C84",
        "#AFCF93",
        "#3D64CE",
        "#CCCC39",
        "#0081B5",
        "#93E5CA",
        "#E2BBB7",
        "#DD9368",
        "#D8778F"
    ];

    string[] private medusaColors4 = [
        "#FFFF84",
        "#F9FFF7",
        "#00FFCB",
        "#D59BFF",
        "#00FFFF",
        "#FF888C",
        "#F3FF9B",
        "#FF9EA1",
        "#1EFF7C",
        "#21ECFF",
        "#B464E5",
        "#FFFFB5",
        "#B6FF00",
        "#14DBFF",
        "#FAFFE5",
        "#FF77A4",
        "#61B6FF",
        "#FA82FF",
        "#A8FFC0",
        "#FFD9FA"
    ];

    string[] private weedColors = [
        "#D3FF66",
        "#FF7CF5",
        "#C400AA",
        "#BCE25A",
        "#804E52",
        "#389942",
        "#635158",
        "#823B40",
        "#FF8E77",
        "#FF9075",
        "#FFCF93",
        "#E28A46",
        "#A793B2",
        "#FF77A4",
        "#A10063",
        "#FF005D",
        "#54CE5C",
        "#3B913F",
        "#E8EA83",
        "#FF5EF4",
        "#00D39B"
    ];

    constructor() {
        grounds[0].push(Rect(0, 20, 24, 4));
    }

    function backgroundColors(
        uint index
    ) private view returns (string[] storage) {
        if (index == 0) return backgroundColors0;
        if (index == 1) return backgroundColors1;
        if (index == 2) return backgroundColors2;
        if (index == 3) return backgroundColors3;
        if (index == 4) return backgroundColors4;
        return backgroundColors0;
    }

    function groundColors(uint index) private view returns (string[] storage) {
        if (index == 0) return groundColors0;
        if (index == 1) return groundColors1;
        if (index == 2) return groundColors2;
        if (index == 3) return groundColors3;
        // if (index == 4) return groundColors4;
        return groundColors0;
    }

    function medusaColors(
        uint index
    ) private view returns (string[] storage) {
        if (index == 0) return medusaColors0;
        if (index == 1) return medusaColors1;
        if (index == 2) return medusaColors2;
        if (index == 3) return medusaColors3;
        if (index == 4) return medusaColors4;
        return medusaColors0;
    }

    // function setPolyps(FileData[] calldata data) external onlyOwner {
    //     for (uint i = 0; i < data.length; ++i) {
    //         FileData memory file = data[i];
    //         Rect[] storage storageFile = polyps[file.file];
    //         for (uint j = 0; j < file.rects.length; ++j) {
    //             storageFile.push(file.rects[j]);
    //         }
    //     }
    // }

    address jelliAddress = 0xA1b9d812926a529D8B002E69FCd070c8275eC73c;

    function getJelliSeed(address userX) external view returns (SeedData memory seed) {
        IJelli jelli = IJelli(jelliAddress);    

        uint medusaCount = jelli.medusaCount(userX);

        if (medusaCount > 0){
            seed = jelli.medusaOfOwnerByIndex(userX, 0);
        } else {
            seed = jelli.polypsDegree(userX);
            if (seed.extra == 0){
                seed = SeedData(2774434,83486810202780782921694749769559261472144661932392090806184854452943580894682);                
            }
        }

        return seed;
    }       

    // function setWeeds(FileData[] calldata data) external onlyOwner {
    //     weeds.setLayers(data);
    // }

    function setBubbles(FileData[] calldata data) external onlyOwner {
        bubbles.setLayers(data);
    }

    function setTentacles(FileData[] calldata data) external onlyOwner {
        tentacles.setLayers(data);
    }

    function setBells(FileData[] calldata data) external onlyOwner {
        bells.setLayers(data);
    }

    // function setDots(FileData[] calldata data) external onlyOwner {
    //     dots.setLayers(data);
    // }

    function toString(uint value) private pure returns (string memory) {
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

    function setBcGround(
        MedusaData memory data,
        Rand memory rnd
    ) private view {
        data.background = backgroundColors(rnd.lvl().to_lvl_1()).random(rnd);        
        if (rnd.lvl().to_lvl_1() < 4) {
            data.background2 = data.background;
        } else {
            data.background2 = backgroundColors42.random(rnd);            
        }
    }

    function setGround(MedusaData memory data, Rand memory rnd) private view {
        if (rnd.lvl().to_lvl_1() < 4){
            data.hasGround = true;
            data.ground = rnd.next() % groundsCount;
            data.groundColor = groundColors(rnd.lvl().to_lvl_1()).random(rnd);
        }
    }

    // function setPolyps(MedusaData memory data, Rand memory rnd) private view {
    //     data.tentacle = rnd.next() % polyps_count;
    //     data.tentacleColor = medusaColors(rnd.lvl().to_lvl_1()).random(rnd);
    // }

    function setBubble(MedusaData memory data, Rand memory rnd) private view {
        data.hasBubble = rnd.next() % 4 < 3; // 0,1,2 = 75% chance
        if(data.hasBubble){
            data.bubble = rnd.next() % bubbleLevelCounts[rnd.lvl().to_lvl_1()];
            data.bubbleColor = bubbleColors.random(rnd);
        }        
    }  

    function setWeed(MedusaData memory data, Rand memory rnd) private view {
        if (rnd.lvl() < 4){ // no weed for biggest level
            data.hasWeed = rnd.next() % 4 < 3; // 0,1,2 = 75% chance
            if(data.hasWeed){
                data.weed = rnd.next() % weedLevelCounts[rnd.lvl().to_lvl_1()];
                data.weedColor = medusaColors(rnd.lvl().to_lvl_1()).random(rnd);
            }
        }
    }    

    function setAnimation(MedusaData memory data, Rand memory rnd) private view {
        data.mirrorTime = 3 + rnd.next() % 3;
        if (rnd.lvl().to_lvl_1() < 2){
            data.bobTime = 0;
        } else {
            data.bobTime = 8 + rnd.next() % 8;
        }        
    }
    

    function setTentacle(MedusaData memory data, Rand memory rnd) private view {
        data.tentacle = rnd.next() % tentacleLevelCounts[rnd.lvl().to_lvl_1()];
        data.tentacleColor = medusaColors(rnd.lvl().to_lvl_1()).random(rnd);
    }

    function setBell(MedusaData memory data, Rand memory rnd) private view {
        data.bell = rnd.next() % bellLevelCounts[rnd.lvl().to_lvl_1()];
        data.bellColor = medusaColors(rnd.lvl().to_lvl_1()).random(rnd);
        // data.hasDots = rnd.next() % 4 == 0;
        // if (data.hasDots) {
        //     data.dotsColor = medusaColors(rnd.lvl().to_lvl_1()).random(rnd);
        // }
    }

    function getMedusa(
        SeedData calldata seed_data
    ) external view returns (MedusaData memory) {
        Rand memory rnd = Rand(seed_data.seed, 0, seed_data.extra);
        MedusaData memory data;
        data.lvl = rnd.lvl();
        setBcGround(data, rnd);
        setBubble(data, rnd);
        setGround(data, rnd);        
        setWeed(data, rnd);
        setAnimation(data, rnd);
        setTentacle(data, rnd);
        setBell(data, rnd);
        return data;
    }

    function getUuid(
        SeedData calldata seed_data
    ) internal view returns (string memory) {
        return string(abi.encodePacked(seed_data.seed.toString(), seed_data.extra.toString()));
    }
    

    function getSvg(
        SeedData calldata seed_data
    ) external view returns (string memory) {
        string memory uuid = getUuid(seed_data);
        return toSvg(this.getMedusa(seed_data), uuid);
    }

    function getMeta(
        SeedData calldata seed_data
    ) external view returns (string memory) {
        MedusaData memory data = this.getMedusa(seed_data);
        bytes memory lvl = abi.encodePacked('"level":', data.lvl.toString());
        bytes memory background = abi.encodePacked(
            ',"background":"',
            data.background,
            '"',
            ',"background2":"',
            data.background2,
            '"'
        );
        bytes memory bubble = abi.encodePacked(
            ',"hasBubble":',
            data.hasBubble ? "true" : "false",
            ',"bubble":',
            data.bubble.toString(),
            ',"bubbleColor":"',
            data.bubbleColor,
            '"'
        );        
        bytes memory ground = abi.encodePacked(
            ',"hasGround":',
            data.hasGround ? "true" : "false",
            ',"groundColor":"',
            data.groundColor,
            '"'
        );
        bytes memory weed = abi.encodePacked(
            ',"hasWeed":',
            data.hasWeed ? "true" : "false",
            ',"weed":',
            data.weed.toString(),
            ',"weedColor":"',
            data.weedColor,
            '"'
        );         
        bytes memory animation = abi.encodePacked(
            ',"mirrorTime":',
            data.mirrorTime.toString(),
            ',"bobTime":',
            data.bobTime.toString()
        ); 
        bytes memory tentacle = abi.encodePacked(
            ',"tentacle":',
            data.tentacle.toString(),
            ',"tentacleColor":"',
            data.tentacleColor,
            '"'
        );       
        bytes memory bell = abi.encodePacked(
            ',"bell":',
            data.bell.toString(),
            ',"bellColor":"',
            data.bellColor,
            '"'
        );
        // bytes memory bellDots = abi.encodePacked(
        //     ',"hasDots":',
        //     data.hasDots ? "true" : "false",
        //     ',"dotsColor":"',
        //     data.dotsColor,
        //     '"'
        // );

        return
            string(
                abi.encodePacked(
                    "{",
                    lvl,
                    background,
                    ground,
                    weed, 
                    bubble,         
                    animation,          
                    tentacle,
                    bell,
                    "}"
                )
            );
    }

    function toSvg(
        MedusaData memory data,
        string memory uuid
    ) private view returns (string memory) {
        bytes memory svgStart = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0",
            " ",
            toString(pixelsCount),
            " ",
            toString(pixelsCount),
            "' shape-rendering='crispEdges'>",
            '<style>',
                '@keyframes mirrorK {',
                    '0%, 50% { transform: scaleX(1); }',
                    '50.1%, 100% { transform: scaleX(-1); }',
                '}',
                '.mirror', uuid, '  {',
                    'animation: mirrorK ',
                    toString(data.mirrorTime),
                    // toString(1),
                    's step-end infinite;',
                    'transform-origin: center center;',
                '}',
            '</style>'          
        );
        if (data.lvl.to_lvl_1() >= 2){
            return
                string(
                    abi.encodePacked(
                        svgStart,
                        // backgroundGradient(data),
                        // backgroundSvg(data, uuid),
                        bubbleSvg(data, uuid),
                        // groundSvg(data),                        
                        // weedSvg(data, uuid),                        
                        tentacleSvg(data, uuid),
                        bellSvg(data, uuid),
                        "</svg>"
                    )
                );
        } else if (data.lvl.to_lvl_1() == 1){
            return
                string(
                    abi.encodePacked(
                        svgStart,
                        // backgroundGradient(data),
                        // backgroundSvg(data, uuid),
                        bubbleSvg(data, uuid),
                        // groundSvg(data),                        
                        // weedSvg(data, uuid),                        
                        '<g transform="translate(0, -3)">',
                        tentacleSvg(data, uuid),
                        bellSvg(data, uuid),
                        '</g>',
                        "</svg>"
                    )
                );
        } else if (data.lvl.to_lvl_1() == 0){
            return
                string(
                    abi.encodePacked(
                        svgStart,
                        // backgroundGradient(data),
                        // backgroundSvg(data, uuid),
                        bubbleSvg(data, uuid),
                        // groundSvg(data),                        
                        // weedSvg(data, uuid),                        
                        '<g transform="translate(0, -5)">',
                        tentacleSvg(data, uuid),
                        bellSvg(data, uuid),
                        '</g>',
                        "</svg>"
                    )
                );
        }
    }

    // function backgroundSvg(
    //     MedusaData memory data,
    //     string memory uuid
    // ) private pure returns (string memory) {       
    //     return
    //         string(
    //             abi.encodePacked(
    //                 "<linearGradient id='Gradient", uuid, "' x1='0' x2='0' y1='0' y2='1'>",
    //                 "<stop offset='0%' stop-color='",
    //                 data.background,
    //                 "' />",
    //                 "<stop offset='100%' stop-color='",
    //                 data.background2,
    //                 "' />",
    //                 "</linearGradient>",
    //                 "<rect x='0' y='0' width='24' height='24' fill='url(#Gradient", uuid, ")'/>"                                        
    //             )
    //         );        
    // }

    function groundSvg(
        MedusaData memory data
    ) private view returns (string memory) {
        if (!data.hasGround) return "";
        return grounds[data.ground].toSvg(data.groundColor);
    }

    function weedSvg(
        MedusaData memory data,
        string memory uuid
    ) private view returns (string memory) {    
        if (!data.hasWeed) return "";
        string memory weedShape = weeds[data.lvl.to_lvl_1()][data.weed].toSvg(data.weedColor);
        return
            string(
                abi.encodePacked(
                    '<g class="swayWeed', uuid, '">',
                        weedShape,
                    '</g>'
                )
            );                
    }  

    function bubbleSvg(
        MedusaData memory data,
        string memory uuid
    ) private view returns (string memory) {    
        if (!data.hasBubble) return "";
        string memory bubbleShape = bubbles[data.lvl.to_lvl_1()][data.bubble].toSvg(data.bubbleColor);
        return
            string(
                abi.encodePacked(
                    "<g class='bubbleRise", uuid, "'>",
                        "<g class='bubbleSway'>",
                            bubbleShape,
                        "</g>",
                    "</g>"
                )
            );
    }       

    function tentacleSvg(
        MedusaData memory data,
        string memory uuid
    ) private view returns (string memory) {
        string memory tentacle = tentacles[data.lvl.to_lvl_1()][data.tentacle].toSvg(data.tentacleColor);
        // always miror
        // if under 2 don't bob pump or sway
        // if under 3 don't pump
        // above do all
        if (data.lvl.to_lvl_1() < 2){
            return
                string(
                    abi.encodePacked(
                        "<g class='mirror", uuid, "'>",
                            tentacle,
                        "</g>"
                    )
                );
        } else if (data.lvl.to_lvl_1() < 3){
            return
                string(
                    abi.encodePacked(                        
                        "<g class='bob", uuid, "'>",
                            "<g class='mirror", uuid, "'>",
                                tentacle,
                            "</g>",
                        "</g>"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(                        
                        "<g class='bob", uuid, "'>",
                            "<g class='pump", uuid, "'>",
                                "<g class='mirror", uuid, "'>",
                                    tentacle,
                                "</g>",
                            "</g>",
                        "</g>"
                    )
                );
        }

        return tentacle;
    } 

    function bellSvg(
        MedusaData memory data,
        string memory uuid
    ) private view returns (string memory) {
        string memory bell = bells[data.lvl.to_lvl_1()][data.bell].toSvg(data.bellColor);
        if (data.lvl.to_lvl_1() < 2){
            // only mirror
            return
                string(
                    abi.encodePacked(
                        "<g class='mirror",uuid,"'>",
                            bell,
                        "</g>"
                    )
                );
        // if under 3 mirror, bob, sway
        } else if (data.lvl.to_lvl_1() < 3){
            return
                string(
                    abi.encodePacked(                        
                        "<g class='bob",uuid,"'>",
                            "<g class='mirror",uuid,"'>",
                                bell,
                            "</g>",
                        "</g>"
                    )
                );
        // otherwise bob and sway don't miror
        } else {
            return
                string(
                    abi.encodePacked(
                        "<g class='bob",uuid,"'>",
                            bell,
                        "</g>"
                    )
                );
        }
    }
}