const from = eth.accounts[0];
const contractDeployer = "0x1d150cF750647f5fC40F959fa9C2840d271b006f";
eth.sendTransaction({
  from: from,
  to: contractDeployer,
  value: web3.toWei(100, "ether"),
});
// PK: de3fbeb0b5ee58bcd434755b8e5c0c1f6e96866f4c552414336916c13b09b9f7
