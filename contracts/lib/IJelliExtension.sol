pragma solidity^0.8.22;

import "./Helpers.sol";

interface IJelliExtension {
    function getSvg(
        SeedData calldata seed_data
    ) external view returns (string memory);

    function getMeta(
        SeedData calldata seed_data
    ) external view returns (string memory);

    function getJelliSeed(address userX) external view returns (SeedData memory seed);
    
}
