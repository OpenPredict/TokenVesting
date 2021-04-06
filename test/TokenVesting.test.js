const ERC20 = artifacts.require('ERC20Mock');
const TokenVesting = artifacts.require('TokenVesting');


const assert = require("chai").assert;
const truffleAssert = require('truffle-assertions');
const { AssertionError } = require("chai");

const ethers = require("ethers");

// test specific constants
contracts = []

SECS_DAILY = 86400;
FULL_PERIOD = 2629746;

advanceTime = (time) => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [time],
        id: new Date().getTime()
      }, (err, result) => {
        if (err) { return reject(err) }
        return resolve(result)
      })
    })
  }

function sendRpc(method, params) {
    return new Promise((resolve) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method,
            params: params || [],
            id: new Date().getTime(),
        }, (err, res) => { resolve(res); });
    });
}

contract("TokenStaking", async (accounts) => {

    beforeEach( async () => {
        contracts['ERC20'] = await ERC20.new("OpenPredict Token", "OPT", ethers.utils.parseUnits('9900000'));
        contracts['TokenVesting'] = await TokenVesting.new(contracts['ERC20'].address, true);

        // add all the schedules
        await contracts['TokenVesting'].addSchedule(
            "Presale",
            1629504000, 
            12,
            ethers.utils.parseUnits('58883.225'),
            [accounts[1], accounts[2]]
        );

        await contracts['TokenVesting'].addSchedule(
                "Community Incentives",
                1618963200,
                11,
                ethers.utils.parseUnits('65809.21'),
                [accounts[1], accounts[2]]
        );

        await contracts['TokenVesting'].addSchedule(
                "Staking Rewards",
                1618963200, 
                17,
                ethers.utils.parseUnits('26784.72'),
                [accounts[1], accounts[2]]
        );

        await contracts['TokenVesting'].addSchedule(
                "Team",
                1642723200, 
                12,
                ethers.utils.parseUnits('49500'),
                [accounts[1], accounts[2]]
        );

        await contracts['TokenVesting'].addSchedule(
                "Advisors",
                1645401600,
                6,
                ethers.utils.parseUnits('66000'),
                [accounts[1], accounts[2]]
        );

        await contracts['TokenVesting'].addSchedule(
                "Foundation",
                1629504000,
                12,
                ethers.utils.parseUnits('82500'),
                [accounts[1], accounts[2]]
        );

        await contracts['TokenVesting'].addSchedule(
                "Marketing",
                1618963200,
                17,
                ethers.utils.parseUnits('27500'),
                [accounts[1], accounts[2]]
        );


        Object.keys(contracts).forEach((key) => {
            console.log(key + " address: " + contracts[key].address)
        })

        // send tokens to contract..
        console.log('send tokens to vesting contract..')
        await contracts['ERC20'].transfer(contracts['TokenVesting'].address, ethers.utils.parseUnits('8666680.54'));
    })

    it("Random schedule selection should vest correctly", async () => {
        
        let numSchedules = await contracts['TokenVesting'].getNumSchedules();
        let scheduleIndex = Math.floor(Math.random() * numSchedules);
        console.log('scheduleIndex: ' + scheduleIndex);
        let schedule = await contracts['TokenVesting'].schedules(scheduleIndex);
        console.log('schedule: ' + JSON.stringify(schedule));
        let startPeriod = schedule['startPeriod'];
        let numPeriods = schedule['numPeriods'];

        var currentTime = Math.floor(new Date().getTime() / 1000);
        if(startPeriod > currentTime){
            console.log('currentTime: ' + currentTime);
            console.log('startPeriod: ' + startPeriod);
            var mineUntil = startPeriod - currentTime - (14 * SECS_DAILY);
            console.log('mineUntil: ' + mineUntil);
            await advanceTime(mineUntil);
            await sendRpc('evm_mine');
        }

        for(let i=0; i < numPeriods; i++){
            console.log('period: ' + i);
            await truffleAssert.reverts(
                contracts['TokenVesting'].release(scheduleIndex, {from: accounts[3]}),
                "_releasableIdx: no vesting for sender."
            );
            // advance time by 1 week, try vest 
            await advanceTime(7 * SECS_DAILY);
            await sendRpc('evm_mine');

            await truffleAssert.reverts(
                contracts['TokenVesting'].release(scheduleIndex, {from: accounts[1]}),
                "_releasableIdx: no tokens are due."
            );

            await truffleAssert.reverts(
                contracts['TokenVesting'].release(scheduleIndex, {from: accounts[2]}),
                "_releasableIdx: no tokens are due."
            );

            //advance by 3 weeks, vest successfully
            await advanceTime(FULL_PERIOD - (7 * SECS_DAILY));
            await sendRpc('evm_mine');
            await contracts['TokenVesting'].release(scheduleIndex, {from: accounts[1]});
            await contracts['TokenVesting'].release(scheduleIndex, {from: accounts[2]});
        }
    
        //verify balance of claim tokens is correct..
        let balanceFirst = await contracts['ERC20'].balanceOf(accounts[1]);
        let balanceSecond = await contracts['ERC20'].balanceOf(accounts[2]);

        
        assert.equal(schedule['amountPerPeriod'].mul(numPeriods).toString(), balanceFirst.toString());
        assert.equal(schedule['amountPerPeriod'].mul(numPeriods).toString(), balanceSecond.toString());
    })
})