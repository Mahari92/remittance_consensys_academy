var Remittance = artifacts.require("./Remittance.sol");

var expectedExceptionPromise = function (action, gasToUse) {
  return new Promise(function (resolve, reject) {
    try {
      resolve(action());
    } catch (e) {
      reject(e);
    }
  })
    .then(function (txn) {
      // https://gist.github.com/xavierlepretre/88682e871f4ad07be4534ae560692ee6
      return web3.eth.getTransactionReceiptMined(txn);
    })
    .then(function (receipt) {
      // We are in Geth
      assert.equal(receipt.gasUsed, gasToUse, "should have used all the gas");
    })
    .catch(function (e) {
      if ((e + "").indexOf("invalid JUMP") || (e + "").indexOf("out of gas") > -1) {
        // We are in TestRPC
      } else if ((e + "").indexOf("please check your gas amount") > -1) {
        // We are in Geth for a deployment
      } else {
        throw e;
      }
    });
};

contract('Remittance', function (accounts) {
  var instance;
  var pass1 = "hola";
  var hash1, doubleHash1;
  var pass2 = "adios";
  var hash2, doubleHash2;

  beforeEach(function (done) {
    Remittance.deployed().then(function (_instance) { //deploy it
      instance = _instance;
      var passwords = [pass1, pass2];
      Promise.all(passwords.map((password) => instance.hashIt(password, { from: accounts[0] })))
        .then(hashes => {
          hash1 = hashes[0];
          hash2 = hashes[1];
          return Promise.all(hashes.map((hash) => instance.hashIt(hash, { from: accounts[0] })));
        }).then(doubleHashes => {
          doubleHash1 = doubleHashes[0];
          doubleHash2 = doubleHashes[1];
          done();
        })
    })
  })

  it("should register a challenge", () => {
    return instance.registerChallenge(doubleHash1, doubleHash2, 10000, { from: accounts[0], value: 120000000000000 })
      .then(() => {
        return instance.challenges(accounts[0], { from: accounts[0] });
      }).then((challenge) => {
        assert.equal(challenge[1], doubleHash1);
        assert.equal(challenge[2], doubleHash2);
      });
  });

  it("should be able to solve a challenge", () => {

    return instance.registerChallenge(doubleHash1, doubleHash2, 10000, { from: accounts[1], value: 120000000000000 })
      .then(() => {
        return instance.solveChallenge(hash1, hash2, accounts[1], { from: accounts[2] })
      });
  });

  it("shouldnt be able to create a new challenge with other one opened", () => {
    return instance.registerChallenge(doubleHash1, doubleHash2, 10000, { from: accounts[1], value: 120000000000000 })
      .then(() => {
        return expectedExceptionPromise(function () {
          return MyContract.new(doubleHash1, doubleHash2, 10000, { from: accounts[1], value: 120000000000000, gas: 3000000 });
        }, 3000000);
      });
  });

});
