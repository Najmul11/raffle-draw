// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Raffle {
    uint16 public ticketCost;
    uint16 public totalEntries;
    uint16 public maxEntries;

    bool public raffleStatus;
    bool public prizeDistributed ;


    address payable  public owner;


    // to count total entries of individual wallet
    mapping(address=>uint16) public playerTotalEntries;
  

    // all entries respect to totalEntries, contains duplicate address for maintaing odds
    address[] private allPlayers;
    // all unique players
    address[] public players;

    constructor() {
        ticketCost=1;
        raffleStatus = false;
        prizeDistributed=true;
        maxEntries=5;

        owner = payable(msg.sender);

    }

    modifier onlyOwner {
        require(msg.sender== owner,"Only owner can perform the action");
        _;
    }


    function startRaffle() public onlyOwner{
        require(!raffleStatus, "Raffle is already started");
        require(prizeDistributed, "Please Select winner for previous raffle.");


        raffleStatus=true;
        prizeDistributed=false;
    }

    function buyTicket(uint16 _entries) public payable {

        require(raffleStatus, "Raffle not yet started");
        require(maxEntries>totalEntries, "No ticket left");
        require(maxEntries-totalEntries>=_entries,"Please lower your entries");

        require(msg.value==_entries * ticketCost * 1 ether, " Please send required amount" );

        for (uint16 index = 0; index < _entries; index++) {
            allPlayers.push(msg.sender);
        }

        if(!isPlayer(msg.sender)) players.push(msg.sender);
        playerTotalEntries[msg.sender] += _entries;
        totalEntries += _entries;

        
       
    }


    function isPlayer(address _player) private view returns(bool){
        for (uint256 index = 0; index < players.length; index++) {
            if(players[index] == _player) return true;
        }
        return false;
    }


    function endRaffle() public onlyOwner{
        require(raffleStatus,"Raffle is not started yet");
        raffleStatus=false;
    }


    function selectWinner() public  onlyOwner{
         require(allPlayers.length > 0, "No players in the raffle");
         require(!raffleStatus, "Raffle is still on");

        // select winner
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))));
        uint256 winningIndex = randomNumber % allPlayers.length;
        address payable winner = payable(allPlayers[winningIndex]);


        // distribute price
        uint256 balance = address(this).balance;
        uint256 prizeAmount = (balance * 80) / 100;
        winner.transfer(prizeAmount);


        prizeDistributed=true;



        // reset variables for a new raffle 
        delete totalEntries;
        delete allPlayers;
        delete players;
        resetPlayerTotalEntries();

    }

    function resetPlayerTotalEntries() private{
        for (uint256 index = 0; index < players.length; index++) {
            delete playerTotalEntries[players[index]];
        }
    }





    function getPlayers() public view returns(address[] memory){
         return players;
    }


    // core owner functions==================================================

    function changeTicketCost(uint16 _ticketCost) public onlyOwner{
        require(!raffleStatus, "Raffle is still on");
        ticketCost = _ticketCost;
    }


    function contractBalance() public  view returns(uint256){
        return address(this).balance;
    }

    function withdrawBalance() public onlyOwner{
        require(prizeDistributed, "Please select a winner first");
        require(address(this).balance>0,"There is no balance to withdraw");
        

        uint256 balanceAmount = address(this).balance;
        owner.transfer(balanceAmount);
    }


    function resetsContract() public onlyOwner {

        require(!raffleStatus, "Raffle is still on");
        require(prizeDistributed, "Please Select winner for previous raffle.");

        delete allPlayers;
        delete players;
        raffleStatus = false;
        ticketCost = 1;
        totalEntries = 0;
        resetPlayerTotalEntries();
    }

}