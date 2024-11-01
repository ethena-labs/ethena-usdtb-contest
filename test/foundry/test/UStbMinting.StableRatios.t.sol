// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UStbMinting.utils.sol";

contract UStbMintingStableRatiosTest is UStbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_stable_ratios_setup() public {
    uint128 stablesDeltaLimitZero = 0; // zero bps allowed (identical USDT and UStb amounts)
    uint128 stablesDeltaLimitPositive = 577; // positive bps allowed

    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimitZero);

    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimitPositive);
  }

  function test_verify_stables_limit() external {
    vm.prank(benefactor);
    USDTToken.mint(25000 * 10 ** 6);

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 ustbAmount = 1000 * 10 ** 18; // 1,000 UStb

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    address usdtAddress = address(USDTToken);

    assertEq(
      UStbMintingContract.verifyStablesLimit(
        usdtAmountAtUpperLimit, ustbAmount, usdtAddress, IUStbMinting.OrderType.MINT
      ),
      true
    );
    assertEq(
      UStbMintingContract.verifyStablesLimit(
        usdtAmountAtLowerLimit, ustbAmount, usdtAddress, IUStbMinting.OrderType.REDEEM
      ),
      true
    );
  }

  function test_stables_limit_minting_valid() public {
    vm.prank(benefactor);
    USDTToken.mint(2500 * 10 ** 6); // Ensuring there is enough USDT for testing

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 ustbAmount = 1000 * 10 ** 18; // 1,000 UStb

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    (IUStbMinting.Order memory orderLow, IUStbMinting.Signature memory signatureLow, IUStbMinting.Route memory routeLow)
    = mint_setup(ustbAmount, usdtAmountAtLowerLimit, USDTToken, 1, true);
    vm.prank(minter);
    UStbMintingContract.mint(orderLow, routeLow, signatureLow);

    (
      IUStbMinting.Order memory orderHigh,
      IUStbMinting.Signature memory signatureHigh,
      IUStbMinting.Route memory routeHigh
    ) = mint_setup(ustbAmount, usdtAmountAtUpperLimit, USDTToken, 2, true);
    vm.prank(minter);
    UStbMintingContract.mint(orderHigh, routeHigh, signatureHigh);

    assertEq(USDTToken.balanceOf(benefactor), 2500 * 10 ** 6 - usdtAmountAtLowerLimit - usdtAmountAtUpperLimit);
    assertEq(USDTToken.balanceOf(address(UStbMintingContract)), usdtAmountAtLowerLimit + usdtAmountAtUpperLimit);
  }

  function test_stable_ratios_minting_invalid() public {
    vm.prank(benefactor);
    USDTToken.mint(2500 * 10 ** 18);

    uint128 stablesDeltaLimit = 100; // 100 bps
    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 ustbAmount = 1000 * 10 ** 18; // 1,000 UStb
    uint128 collateralGreaterBreachStableLimit = 1011 * 10 ** 6;
    (IUStbMinting.Order memory aOrder, IUStbMinting.Signature memory aTakerSignature, IUStbMinting.Route memory aRoute)
    = mint_setup(ustbAmount, collateralGreaterBreachStableLimit, USDTToken, 1, true);

    vm.prank(minter);
    UStbMintingContract.mint(aOrder, aRoute, aTakerSignature);

    uint128 collateralLessThanBreachesStableLimit = 989 * 10 ** 6;
    (IUStbMinting.Order memory bOrder, IUStbMinting.Signature memory bTakerSignature, IUStbMinting.Route memory bRoute)
    = mint_setup(ustbAmount, collateralLessThanBreachesStableLimit, USDTToken, 2, true);

    vm.expectRevert(InvalidStablePrice);
    vm.prank(minter);
    UStbMintingContract.mint(bOrder, bRoute, bTakerSignature);
  }

  function test_stables_limit_redeem_valid() public {
    vm.prank(address(UStbMintingContract));
    ustbToken.mint(beneficiary, 2500 * 10 ** 18);

    USDTToken.mint(2500 * 10 ** 6, benefactor); // initial mint

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 ustbAmount = 1000 * 10 ** 18; // 1,000 UStb

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    (IUStbMinting.Order memory orderLow, IUStbMinting.Signature memory signatureLow) =
      redeem_setup(ustbAmount, usdtAmountAtLowerLimit, USDTToken, 1, true);
    vm.prank(redeemer);
    UStbMintingContract.redeem(orderLow, signatureLow);

    (IUStbMinting.Order memory orderHigh, IUStbMinting.Signature memory signatureHigh) =
      redeem_setup(ustbAmount, usdtAmountAtUpperLimit, USDTToken, 2, true);
    vm.prank(redeemer);
    UStbMintingContract.redeem(orderHigh, signatureHigh);

    assertEq(USDTToken.balanceOf(beneficiary), usdtAmountAtLowerLimit + usdtAmountAtUpperLimit);
    assertEq(USDTToken.balanceOf(address(UStbMintingContract)), 0);
  }

  function test_stable_ratios_redeem_invalid() public {
    vm.prank(address(UStbMintingContract));
    ustbToken.mint(beneficiary, 2500 * 10 ** 18);

    USDTToken.mint(2500 * 10 ** 6, address(UStbMintingContract));

    uint128 stablesDeltaLimit = 100; // 100 bps
    vm.prank(owner);
    UStbMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 ustbAmount = 1000 * 10 ** 18; // 1,000 UStb

    address collateralAsset = address(USDTToken);

    // case 1
    uint128 collateralGreaterThanUStbAmount = 1011 * 10 ** 6; // 1011 USDT redeemed (greater than UStb)
    IUStbMinting.Order memory redeemOrder2 = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 2,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: collateralAsset,
      ustb_amount: ustbAmount,
      collateral_amount: collateralGreaterThanUStbAmount
    });

    vm.startPrank(beneficiary);
    ustbToken.approve(address(UStbMintingContract), ustbAmount);

    bytes32 digest2 = UStbMintingContract.hashOrder(redeemOrder2);
    IUStbMinting.Signature memory takerSignature2 =
      signOrder(beneficiaryPrivateKey, digest2, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.expectRevert(InvalidStablePrice);
    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder2, takerSignature2);

    // case 2
    uint128 collateralLessThanUStbAmount = 989 * 10 ** 6; // 989 USDT redeemed (less than UStb)
    IUStbMinting.Order memory redeemOrder1 = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 1,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: collateralAsset,
      ustb_amount: ustbAmount,
      collateral_amount: collateralLessThanUStbAmount
    });

    vm.startPrank(beneficiary);
    ustbToken.approve(address(UStbMintingContract), ustbAmount);

    bytes32 digest1 = UStbMintingContract.hashOrder(redeemOrder1);
    IUStbMinting.Signature memory takerSignature1 =
      signOrder(beneficiaryPrivateKey, digest1, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(owner);
    UStbMintingContract.grantRole(redeemerRole, redeemer);
    vm.stopPrank();

    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder1, takerSignature1);
  }
}
