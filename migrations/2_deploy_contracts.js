var Fundraising = artifacts.require("./Fundraising.sol");

module.exports = function (deployer) {
  deployer.deploy(Fundraising);
};
