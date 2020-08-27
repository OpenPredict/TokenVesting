const TokenVesting = artifacts.require("TokenVesting");

module.exports = function (deployer) {
  deployer.deploy(TokenVesting);
};
