var Remittance = artifacts.require("./Remittance.sol");

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
    return instance.registerChallenge(doubleHash1, doubleHash2, 10000, { from: accounts[0],value: 120000000000000 })
      .then(() => {
        return instance.challenges(accounts[0], { from: accounts[0] });
      }).then((challenge) => {
        assert.equal(challenge[1], doubleHash1);
        assert.equal(challenge[2], doubleHash2);
      });
  });

  it("should be able to solve a challenge", () => {

    return instance.registerChallenge(doubleHash1, doubleHash2, 10000, { from: accounts[1],value: 120000000000000 })
      .then(() => {
        return instance.solveChallenge(hash1, hash2, accounts[1], { from: accounts[2] })
      });
  });

});
