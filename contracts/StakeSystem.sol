// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeSystem is ERC20{

        constructor() ERC20("OracleStake Token", "Oracus") {

        }

        mapping(address => bool) internal tokenExist;

        address[] public StakeHolders;

        mapping(address => bool) internal userExist;
        address[] public StakeTokens;

        //map tokenContract to tokenstakers
        mapping(address => address[]) public  tokenStakers;


        //staking details
        struct StakeDetail {
            uint256 stakeAmount;
            uint256 accruedReward;
            uint256 lastTime;//last time user interacted with contract
        }

        //takes token contracts and maps it to the token staker which maps to the token user struct which is the stakeDetail
        mapping(address => mapping(address => StakeDetail)) public tokenStakeRecord;


        function stakeToken(address _tokenContractAddress, uint256 _amount) public {
            if(!tokenExist[_tokenContractAddress]) {
                //add 
                addTokenToRecord(_tokenContractAddress);
            }
             
            if(!userExist[msg.sender]) {
                addUserToRecord(msg.sender);
            }

            StakeDetail storage MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];

            if(MyStakeDetail.lastTime == 0) {
                addUserToTokenRecord(_tokenContractAddress, msg.sender);
            }


            require(IERC20(_tokenContractAddress).transferFrom(msg.sender, address(this), _amount), "Failed transaction: transferfrom");



            MyStakeDetail.stakeAmount += _amount;
            MyStakeDetail.lastTime = block.timestamp;
        }

        function getStakeHolders() external view returns(address[] memory ){
            return StakeTokens;
        }
        function getStakersByTokens(address _tokenContractAddress) external view returns (address[] memory) {
            return tokenStakers[_tokenContractAddress];
        }

        
        function getStakeTokens() external view returns(address[] memory ){
            return StakeHolders;
        }

        



        //contract returns 20% of what you staked per hour
        function calculateReward(uint256 _stakeAmount, uint256 _lastTime) internal view returns (uint256) {
            uint256 period = block.timestamp - _lastTime;
            return (_stakeAmount * period) / 7200;
        }

        function claimReward(address _tokenContractAddress, uint256 _rewardAmount) public {
            StakeDetail storage MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];

            uint256 newReward = calculateReward(MyStakeDetail
            .stakeAmount, MyStakeDetail.lastTime);

             MyStakeDetail.accruedReward += newReward;
             MyStakeDetail.lastTime = block.timestamp;

             require(_rewardAmount <= MyStakeDetail.accruedReward, "You don't have enough claimable reward");

             _mint(msg.sender, _rewardAmount);
             MyStakeDetail.accruedReward -= _rewardAmount;


        }

        function withdrawStake(address _tokenContractAddress, uint256 _amount) public {
            StakeDetail storage MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];

            require(MyStakeDetail.stakeAmount >= _amount, "insufficiaent amount");
            MyStakeDetail.accruedReward += calculateReward(MyStakeDetail.stakeAmount, MyStakeDetail.lastTime);

            IERC20(_tokenContractAddress).transfer(msg.sender, _amount);
        }

        function checkRewardValue(address _tokenContractAddress, address _stakeHolder) public view returns(uint256) {
            //we are putting this in memory because we are not storing to state 
                StakeDetail memory MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];

                return MyStakeDetail.accruedReward + calculateReward(MyStakeDetail.stakeAmount, MyStakeDetail.lastTime);
        }




        function addTokenToRecord(address _tokenContractAddress) internal {
            tokenExist[_tokenContractAddress] = true;
            StakeTokens.push(_tokenContractAddress);
        }

        function addUserToRecord(address _tokenContractAddress) internal {
            userExist[_tokenContractAddress] = true;
            StakeHolders.push(_tokenContractAddress);
        }

        function addUserToTokenRecord(address _tokenContractAddress, address _userAddress) internal{
            tokenStakers[_tokenContractAddress].push(_userAddress);
        }

}