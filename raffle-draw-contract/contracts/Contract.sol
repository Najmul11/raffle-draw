// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract RaffleDraw {
    address payable public owner;

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
        Player[] players;

        mapping(address=>uint16) individualEntries;

        bool raffleStatus;
        bool prizeDistributed;
    }

    Campaign[] public campaigns;

    constructor(){
        owner= payable(msg.sender);
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

        Campaign memory newCampaign;

        newCampaign.id=totalCampaign;
        newCampaign.title=_title;
        newCampaign.banner=_banner;
        newCampaign.maxEntries=_maxEntries;
        newCampaign.ticketCost=_ticketCost;
        newCampaign.raffleStatus=true;
        newCampaign.prizeDistributed=false;

        campaigns.push(newCampaign);

        totalCampaign++;

    } 

    function getAllCampaigns() public view returns(Campaign[] memory) {
        return campaigns;
    }

    function buyTicket(uint16 _campaignId, uint16 _entries) public payable{
        Campaign storage targetCampaign = campaigns[_campaignId];

        require(targetCampaign.raffleStatus==true, "Campaign is not live at the moment");
        require(targetCampaign.maxEntries>targetCampaign.totalEntries , "No ticket left");
        require(targetCampaign.maxEntries-targetCampaign.totalEntries>=_entries,"Please lower your entries");

        require(msg.value==_entries * targetCampaign.ticketCost * 1 ether, " Please send required amount" );

        targetCampaign.totalEntries += _entries;
        targetCampaign.players.push(Player(msg.sender, _entries));


        individualEntries[msg.sender] +=_entries;

        for (uint256 index = 0; index < _entries; index++) {
            targetCampaign.allPlayersWithOdds.push(msg.sender);
        }
    }



    function getEntriesOfIndividual(uint16 _campaignId, address _playerAddress) public returns(uint16){
        Campaign memory targetCampaign=campaigns[_campaignId];
        return targetCampaign.individualEntries[_playerAddress];
    }
}