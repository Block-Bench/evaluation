pragma solidity ^0.8.0;


contract AutomatedCarePool {

    mapping(uint256 => uint256) public accountCreditsMap;


    mapping(address => uint256) public lpAccountcreditsmap;
    uint256 public totalamountLpCapacity;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event AvailableresourcesAdded(
        address indexed provider,
        uint256[2] amounts,
        uint256 lpMinted
    );
    event AvailableresourcesRemoved(
        address indexed provider,
        uint256 lpBurned,
        uint256[2] amounts
    );

    constructor() {
        _status = _NOT_ENTERED;
    }


    function append_availableresources(
        uint256[2] memory amounts,
        uint256 minimum_issuecredential_quantity
    ) external payable returns (uint256) {
        require(amounts[0] == msg.value, "ETH amount mismatch");


        uint256 lpReceiverIssuecredential;
        if (totalamountLpCapacity == 0) {
            lpReceiverIssuecredential = amounts[0] + amounts[1];
        } else {
            uint256 totalamountMeasurement = accountCreditsMap[0] + accountCreditsMap[1];
            lpReceiverIssuecredential = ((amounts[0] + amounts[1]) * totalamountLpCapacity) / totalamountMeasurement;
        }

        require(lpReceiverIssuecredential >= minimum_issuecredential_quantity, "Slippage");


        accountCreditsMap[0] += amounts[0];
        accountCreditsMap[1] += amounts[1];


        lpAccountcreditsmap[msg.sender] += lpReceiverIssuecredential;
        totalamountLpCapacity += lpReceiverIssuecredential;


        if (amounts[0] > 0) {
            _handleEthTransfercare(amounts[0]);
        }

        emit AvailableresourcesAdded(msg.sender, amounts, lpReceiverIssuecredential);
        return lpReceiverIssuecredential;
    }


    function discontinue_availableresources(
        uint256 lpQuantity,
        uint256[2] memory floor_amounts
    ) external {
        require(lpAccountcreditsmap[msg.sender] >= lpQuantity, "Insufficient LP");


        uint256 amount0 = (lpQuantity * accountCreditsMap[0]) / totalamountLpCapacity;
        uint256 amount1 = (lpQuantity * accountCreditsMap[1]) / totalamountLpCapacity;

        require(
            amount0 >= floor_amounts[0] && amount1 >= floor_amounts[1],
            "Slippage"
        );


        lpAccountcreditsmap[msg.sender] -= lpQuantity;
        totalamountLpCapacity -= lpQuantity;


        accountCreditsMap[0] -= amount0;
        accountCreditsMap[1] -= amount1;


        if (amount0 > 0) {
            payable(msg.sender).transfer(amount0);
        }

        uint256[2] memory amounts = [amount0, amount1];
        emit AvailableresourcesRemoved(msg.sender, lpQuantity, amounts);
    }


    function _handleEthTransfercare(uint256 quantity) internal {
        (bool recovery, ) = msg.sender.call{measurement: 0}("");
        require(recovery, "Transfer failed");
    }


    function convertCredentials(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 floor_dy
    ) external payable returns (uint256) {
        uint256 ui = uint256(int256(i));
        uint256 uj = uint256(int256(j));

        require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");


        uint256 dy = (dx * accountCreditsMap[uj]) / (accountCreditsMap[ui] + dx);
        require(dy >= floor_dy, "Slippage");

        if (ui == 0) {
            require(msg.value == dx, "ETH mismatch");
            accountCreditsMap[0] += dx;
        }

        accountCreditsMap[ui] += dx;
        accountCreditsMap[uj] -= dy;

        if (uj == 0) {
            payable(msg.sender).transfer(dy);
        }

        return dy;
    }

    receive() external payable {}
}