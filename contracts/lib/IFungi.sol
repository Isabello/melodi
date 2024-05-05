pragma solidity ^0.8.22;

import {FileData, SeedData} from "./Helpers.sol";

interface IFungi {
    function setCaps(FileData[] memory _caps) external;
    function setStems(FileData[] memory _stems) external;
    function setSpores(FileData[] memory _spores) external;
    function setDots(FileData[] memory _dots) external;
    
    function getSvg(SeedData memory _seed) external view returns (string memory);
    function getMeta(SeedData memory _seed) external view returns (string memory);
}
