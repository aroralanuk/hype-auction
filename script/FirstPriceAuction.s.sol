// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC20PresetFixedSupply} from
    "lib/composable-cow/lib/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {ERC20Mock} from "lib/composable-cow/lib/@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {FirstPriceAuction} from "../src/FirstPriceAuction.sol";

contract DeployFirstPriceAuction is Script {
    address public composableCowAddress = 0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74;

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 bidderKey = vm.envUint("BIDDER_KEY");
        address owner = vm.addr(deployerKey);
        address bidderSafe = 0xf37b1b17A417Ee350b6C7dF0497bE8aB184aE02f;
        address vaultRelayer = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
        vm.startBroadcast(deployerKey);

        ERC20PresetFixedSupply hype = new ERC20PresetFixedSupply("Hype Token", "HYPE", 1000e18, owner);
        hype.transfer(bidderSafe, 1000e18);
        console.log("Hype Token deployed to:", address(hype));

        ERC20Mock syntheticToken = new ERC20Mock();
        console.log("Synthetic Token deployed to:", address(syntheticToken));

        FirstPriceAuction firstPriceAuction =
            new FirstPriceAuction(composableCowAddress, address(hype), address(syntheticToken), 600); // 10 minutes
        console.log("FirstPriceAuction deployed to:", address(firstPriceAuction));

        syntheticToken.mint(address(firstPriceAuction), 1000e18);
        firstPriceAuction.approveSyntheticToken(vaultRelayer, 1000e18);

        vm.stopBroadcast();
    }
}
