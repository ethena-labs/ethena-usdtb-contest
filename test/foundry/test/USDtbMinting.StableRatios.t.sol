// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../USDtbMinting.utils.sol";

contract USDtbMintingStableRatiosTest is USDtbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_stable_ratios_setup() public {
    uint128 stablesDeltaLimitZero = 0; // zero bps allowed (identical USDT and USDtb amounts)
    uint128 stablesDeltaLimitPositive = 577; // positive bps allowed

    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimitZero);

    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimitPositive);
  }

  function test_verify_stables_limit() external {
    vm.prank(benefactor);
    USDTToken.mint(25000 * 10 ** 6);

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usdtbAmount = 1000 * 10 ** 18; // 1,000 USDtb

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    address usdtAddress = address(USDTToken);

    assertEq(
      USDtbMintingContract.verifyStablesLimit(
        usdtAmountAtUpperLimit, usdtbAmount, usdtAddress, IUSDtbMinting.OrderType.MINT
      ),
      true
    );
    assertEq(
      USDtbMintingContract.verifyStablesLimit(
        usdtAmountAtLowerLimit, usdtbAmount, usdtAddress, IUSDtbMinting.OrderType.REDEEM
      ),
      true
    );
  }

  function test_stables_limit_minting_valid() public {
    vm.prank(benefactor);
    USDTToken.mint(2500 * 10 ** 6); // Ensuring there is enough USDT for testing

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usdtbAmount = 1000 * 10 ** 18; // 1,000 USDtb

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    (IUSDtbMinting.Order memory orderLow, IUSDtbMinting.Signature memory signatureLow, IUSDtbMinting.Route memory routeLow)
    = mint_setup(usdtbAmount, usdtAmountAtLowerLimit, USDTToken, 1, true);
    vm.prank(minter);
    USDtbMintingContract.mint(orderLow, routeLow, signatureLow);

    (
      IUSDtbMinting.Order memory orderHigh,
      IUSDtbMinting.Signature memory signatureHigh,
      IUSDtbMinting.Route memory routeHigh
    ) = mint_setup(usdtbAmount, usdtAmountAtUpperLimit, USDTToken, 2, true);
    vm.prank(minter);
    USDtbMintingContract.mint(orderHigh, routeHigh, signatureHigh);

    assertEq(USDTToken.balanceOf(benefactor), 2500 * 10 ** 6 - usdtAmountAtLowerLimit - usdtAmountAtUpperLimit);
    assertEq(USDTToken.balanceOf(address(USDtbMintingContract)), usdtAmountAtLowerLimit + usdtAmountAtUpperLimit);
  }

  function test_stable_ratios_minting_invalid() public {
    vm.prank(benefactor);
    USDTToken.mint(2500 * 10 ** 18);

    uint128 stablesDeltaLimit = 100; // 100 bps
    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usdtbAmount = 1000 * 10 ** 18; // 1,000 USDtb
    uint128 collateralGreaterBreachStableLimit = 1011 * 10 ** 6;
    (IUSDtbMinting.Order memory aOrder, IUSDtbMinting.Signature memory aTakerSignature, IUSDtbMinting.Route memory aRoute)
    = mint_setup(usdtbAmount, collateralGreaterBreachStableLimit, USDTToken, 1, true);

    vm.prank(minter);
    USDtbMintingContract.mint(aOrder, aRoute, aTakerSignature);

    uint128 collateralLessThanBreachesStableLimit = 989 * 10 ** 6;
    (IUSDtbMinting.Order memory bOrder, IUSDtbMinting.Signature memory bTakerSignature, IUSDtbMinting.Route memory bRoute)
    = mint_setup(usdtbAmount, collateralLessThanBreachesStableLimit, USDTToken, 2, true);

    vm.expectRevert(InvalidStablePrice);
    vm.prank(minter);
    USDtbMintingContract.mint(bOrder, bRoute, bTakerSignature);
  }

  function test_stables_limit_redeem_valid() public {
    vm.prank(address(USDtbMintingContract));
    usdtbToken.mint(beneficiary, 2500 * 10 ** 18);

    USDTToken.mint(2500 * 10 ** 6, benefactor); // initial mint

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usdtbAmount = 1000 * 10 ** 18; // 1,000 USDtb

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    (IUSDtbMinting.Order memory orderLow, IUSDtbMinting.Signature memory signatureLow) =
      redeem_setup(usdtbAmount, usdtAmountAtLowerLimit, USDTToken, 1, true);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(orderLow, signatureLow);

    (IUSDtbMinting.Order memory orderHigh, IUSDtbMinting.Signature memory signatureHigh) =
      redeem_setup(usdtbAmount, usdtAmountAtUpperLimit, USDTToken, 2, true);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(orderHigh, signatureHigh);

    assertEq(USDTToken.balanceOf(beneficiary), usdtAmountAtLowerLimit + usdtAmountAtUpperLimit);
    assertEq(USDTToken.balanceOf(address(USDtbMintingContract)), 0);
  }

  function test_stable_ratios_redeem_invalid() public {
    vm.prank(address(USDtbMintingContract));
    usdtbToken.mint(beneficiary, 2500 * 10 ** 18);

    USDTToken.mint(2500 * 10 ** 6, address(USDtbMintingContract));

    uint128 stablesDeltaLimit = 100; // 100 bps
    vm.prank(owner);
    USDtbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usdtbAmount = 1000 * 10 ** 18; // 1,000 USDtb

    address collateralAsset = address(USDTToken);

    // case 1
    uint128 collateralGreaterThanUSDtbAmount = 1011 * 10 ** 6; // 1011 USDT redeemed (greater than USDtb)
    IUSDtbMinting.Order memory redeemOrder2 = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 2,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: collateralAsset,
      usdtb_amount: usdtbAmount,
      collateral_amount: collateralGreaterThanUSDtbAmount
    });

    vm.startPrank(beneficiary);
    usdtbToken.approve(address(USDtbMintingContract), usdtbAmount);

    bytes32 digest2 = USDtbMintingContract.hashOrder(redeemOrder2);
    IUSDtbMinting.Signature memory takerSignature2 =
      signOrder(beneficiaryPrivateKey, digest2, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.expectRevert(InvalidStablePrice);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder2, takerSignature2);

    // case 2
    uint128 collateralLessThanUSDtbAmount = 989 * 10 ** 6; // 989 USDT redeemed (less than USDtb)
    IUSDtbMinting.Order memory redeemOrder1 = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 1,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: collateralAsset,
      usdtb_amount: usdtbAmount,
      collateral_amount: collateralLessThanUSDtbAmount
    });

    vm.startPrank(beneficiary);
    usdtbToken.approve(address(USDtbMintingContract), usdtbAmount);

    bytes32 digest1 = USDtbMintingContract.hashOrder(redeemOrder1);
    IUSDtbMinting.Signature memory takerSignature1 =
      signOrder(beneficiaryPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(owner);
    USDtbMintingContract.grantRole(redeemerRole, redeemer);
    vm.stopPrank();

    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder1, takerSignature1);
  }
}
