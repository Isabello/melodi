import "./Helpers.sol";


interface IJelli {
    function medusaCount(address owner) external view returns (uint);

    function holdersCount() external view returns (uint);

    function getHolderByIndex(uint index) external view returns (address);

    function medusaOfOwnerByIndex(
        address owner,
        uint index
    ) external view returns (SeedData memory data);

    function polypsDegree(
        address owner
    ) external view returns (SeedData memory data);

    function transfer(
        address to,
        uint amount
    ) external;

    function getSvg(
        SeedData memory seedData
    ) external view returns (string memory);

    function getMeta(
        SeedData memory seedData
    ) external view returns (string memory);

    function getBalance(
        address owner
    ) external view returns (uint);
}