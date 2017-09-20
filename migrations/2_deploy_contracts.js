var Wallet = artifacts.require("./wallet/Wallet.sol");
var IcxToken = artifacts.require("./token/IcxToken.sol");
var IconCrawSale = artifacts.require("./ico/IconCrawSale");

module.exports = function(deployer) {
  deployer.deploy(Wallet);
  deployer.deploy(IcxToken, "400340000000000000000000000", Wallet);
  deployer.deploy(IconCrawSale, Wallet, "400340000000000000000000000", 2500);




};
