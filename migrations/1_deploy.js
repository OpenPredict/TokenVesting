const TokenVesting = artifacts.require("TokenVesting");
const ERC20        = artifacts.require("ERC20Mock");

const ethers = require('ethers')

module.exports = async function (deployer, network, accounts) {
    console.log("network: " + network)
    process.env.NETWORK = network
    contracts= []
    if(network == "development") {
        contracts['ERC20'] = await ERC20.new("OpenPredict Token", "OPT", ethers.utils.parseUnits('9900000'));
        contracts['TokenVesting'] = await TokenVesting.new(
                contracts['ERC20'].address, 
                true,
                [
                        accounts[0],
                        accounts[1],
                ]);

        // add all the schedules
        await contracts['TokenVesting'].addSchedule(
            "Presale",
            1629504000, 
            12,
            ethers.utils.parseUnits('58883.225'),
            ['0x748c2d0b604e4f45045e417dfdeb2589dd4d98f8', '0x2091E206a53cC8B985EA3b5e45051dC5A7dD580B']
        );

        await contracts['TokenVesting'].addSchedule(
                "Community Incentives",
                1618963200,
                11,
                ethers.utils.parseUnits('65809.21'),
                ['0x653ec89a0571a753daebbcacc9154d9c5040a1ef','0xc0Be5bBC19E25e29AE264CCE8dF4E194814514ef']
        );

        await contracts['TokenVesting'].addSchedule(
                "Staking Rewards",
                1618963200, 
                17,
                ethers.utils.parseUnits('26784.72'),
                ['0xb2cb3693b42e6692ff9a7e1ac03c955493ef7a12', '0x783eB084eC2600dD1f820b38d58f539Ff2418Fa6']
        );

        await contracts['TokenVesting'].addSchedule(
                "Team",
                1642723200, 
                12,
                ethers.utils.parseUnits('49500'),
                ['0x842e4b2ab896a6e3685814f7eae1a971245f9799', '0xe6F52F02665b55Bad9B1883d4a702E7772Ca1102']
        );

        await contracts['TokenVesting'].addSchedule(
                "Advisors",
                1645401600,
                6,
                ethers.utils.parseUnits('66000'),
                ['0x08828d78f95bf81fea023c6d5d23f523476c6073', '0x086141bF1a78027362237E2BF310402645259bbA']
        );

        await contracts['TokenVesting'].addSchedule(
                "Foundation",
                1629504000,
                12,
                ethers.utils.parseUnits('82500'),
                ['0xa994beecaf10d8c146a494c1055ea43405109117', '0x35749FB8DC122128b7Ea9B6Bc445Eb8f5f2090Dd',]
        );

        await contracts['TokenVesting'].addSchedule(
                "Marketing",
                1618963200,
                17,
                ethers.utils.parseUnits('27500'),
                ['0xdae0bda785836af951b0cc5d85de50a2df854e5b', '0x13eeF71F8d5D86B2E2820a0c6327809D7D06A668']
        );


        Object.keys(contracts).forEach((key) => {
            console.log(key + " address: " + contracts[key].address)
        })
    }
};