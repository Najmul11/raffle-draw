// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



contract RaffleDraw is Helpers {
    address payable public owner;
    uint256 public platformFee;

    struct Player{
        address player;
        uint32 tickets;
    }


    uint16 totalCampaign;

    // campaign data
    struct Campaign{
        uint16 id;
        string title;
        string banner;

        uint16 maxEntries;
        uint16 totalEntries;
        uint256 ticketCost;

        address[] allPlayersWithOdds;

        // players with entries
        Player[]  players;


        bool raffleStatus;
        bool prizeDistributed;
    }

    Campaign[] public campaigns;

    event CampaignCreated(uint16 indexed campaignId, string title, string banner);
    event TicketBought(address indexed player, uint16 campaignId, uint16 entriesBought);
    event RaffleStarted(uint16 indexed campaignId);
    event CampaignEnded(uint16 indexed campaignId);
    event TicketPriceChanged(uint16 indexed campaignId, uint256 newTicketCost);
    event WinnerSelected(uint16 indexed campaignId, address winner, uint256 prizeAmount);
    event CampaignReset(uint16 indexed campaignId);





    constructor(){
        owner= payable(msg.sender);
        platformFee = 5;
    }

    modifier onlyOwner{
        require(msg.sender==owner, "You are not authorized");
        _;
    }

    function  createCampaign(
        string memory _title,
        string memory _banner,
        uint16 _maxEntries,
        uint256 _ticketCost
        ) public onlyOwner{

        Campaign storage newCampaign = campaigns.push();

        newCampaign.id = totalCampaign;
        newCampaign.title = _title;
        newCampaign.banner = _banner;
        newCampaign.maxEntries = _maxEntries;
        newCampaign.ticketCost = _ticketCost;
        newCampaign.raffleStatus = true;
        newCampaign.prizeDistributed = false;


        totalCampaign++;

        emit CampaignCreated(newCampaign.id, newCampaign.title, newCampaign.banner);
    }

       function getAllCampaigns() public view returns(Campaign[] memory) {
        return campaigns;
    }

    
    function getSingleCampaign(uint16 _campaignId) public view returns(Campaign memory) {
        Campaign memory targetCampaign = campaigns[_campaignId];
        return targetCampaign ;
    }


    function buyTicket(uint16 _campaignId, uint16 _entries) public payable{
        Campaign storage targetCampaign = campaigns[_campaignId];

        require(targetCampaign.raffleStatus==true, "Campaign is not live at the moment");
        require(targetCampaign.maxEntries>targetCampaign.totalEntries , "No ticket left");
        require(targetCampaign.maxEntries-targetCampaign.totalEntries>=_entries,"Please lower your entries");

        require(msg.value==_entries * targetCampaign.ticketCost * 1 ether, " Please send required amount" );

        targetCampaign.totalEntries += _entries;
        targetCampaign.players.push(Player(msg.sender, _entries));


        for (uint256 index = 0; index < _entries; index++) {
            targetCampaign.allPlayersWithOdds.push(msg.sender);
        }

        emit TicketBought(msg.sender, _campaignId, _entries);
    }

    function startRaffle (uint16 _campaignId) public onlyOwner{
        require(!campaigns[_campaignId].raffleStatus, "Raffle is on already");
        require(campaigns[_campaignId].prizeDistributed, "Please Select winner for previous raffle.");

        Campaign storage targetCampaign = campaigns[_campaignId];
        targetCampaign.raffleStatus=false;

        emit RaffleStarted(_campaignId);

    }


    function endCampaign(uint16 _campaignId) public onlyOwner{
        require(campaigns[_campaignId].raffleStatus, "Campaign is not live to end.");

        Campaign storage targetCampaign = campaigns[_campaignId];
        targetCampaign.raffleStatus=false;

        emit CampaignEnded(_campaignId);
    } 


    function changeTicketPrice(uint16 _campaignId, uint256 _ticketCost) public onlyOwner{
        require(!campaigns[_campaignId].raffleStatus, "Raffle must be off. ");

        require(campaigns[_campaignId].prizeDistributed, "Please distribute prize for the previous raffle. ");

        Campaign storage targetCampaign = campaigns[_campaignId];

        targetCampaign.ticketCost=_ticketCost;

        emit TicketPriceChanged(_campaignId, _ticketCost);
    }

    function contractBalance() public  view returns(uint256){
        return address(this).balance;
    }

    function setPlatformFee(uint256 _platformFee) public onlyOwner{
        require(_platformFee<=20);
        platformFee = _platformFee;
    } 


    function selectWinner(uint16 _campaignId) public onlyOwner{
        require(campaigns[_campaignId].allPlayersWithOdds.length > 0, "No players in the raffle");
        require(!campaigns[_campaignId].raffleStatus, "Raffle is still on");

        Campaign storage targetCampaign = campaigns[_campaignId];

        // select winner
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))));
        uint256 winningIndex = randomNumber % targetCampaign.allPlayersWithOdds.length;
        address payable winner = payable(targetCampaign.allPlayersWithOdds[winningIndex]);

        uint256 fee = (targetCampaign.totalEntries * 1 ether  *platformFee)/100;
        uint256 winnerPrize =( targetCampaign.totalEntries * 1 ether )-fee;

        (bool sent ,)=payable(winner).call{value:winnerPrize}("");

        if(sent) owner.transfer(fee);

        emit WinnerSelected(_campaignId, winner, winnerPrize);

        resetCampaign(_campaignId);

    }


    function resetCampaign(uint16 _campaignId) public onlyOwner {
        Campaign storage targetCampaign = campaigns[_campaignId];

        // Reset campaign data
        targetCampaign.totalEntries = 0;
        targetCampaign.raffleStatus = true;
        targetCampaign.prizeDistributed = false;
        delete targetCampaign.allPlayersWithOdds;
        delete targetCampaign.players;

        emit CampaignReset(_campaignId);
    }
    
}

 
