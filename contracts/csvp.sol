pragma solidity >=0.4.22 <0.6.0;

/// @title Croud Source Verification Protocol
contract Csvp {

    struct Voter {
        uint reputation; //reputation bw 1-1000
        address id;
    }
    
    // Tweet refers to any post on any social nw, will add more fields later
    struct Tweet {
        uint id;
        uint rating;
        address addedBy;
        uint votesNumber;
        Voter[] tweetVoters;
    }

    mapping(address => Voter) public voters;
    mapping(uint => Tweet) public tweets;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function giveRightToVote(address voter) public {
        require(
            msg.sender == owner,
            "Only owner can give the right to vote"
        );
        // @todo add to approved voters list
    }

    function addTweet(address addedBy, uint tweetId) public  {
        Voter[] memory votersList;
        Tweet memory t = tweets[tweetId]; 
        t.id = tweetId;
        t.rating = 0;
        t.addedBy = addedBy;
        t.votesNumber = 0;
        t.tweetVoters = votersList;
    }

    //On 100th Vote, this function will calculate the rating of the tweet
    function rateTweet(uint rating, uint tweetId) public {
        // Tweet tweet = Tweet{tweetId: tweetId};

        require(tweets[tweetId].votesNumber < 100);
        
        // @todo put a check for if a voter has already voted for a particular tweet
        
        Voter memory v = voters[msg.sender];
        // @todo also send reputaiton here
        tweets[tweetId].tweetVoters.push(v);

        // if(votes[tweet].length == 100) {
        //     //Time to calculate final rating of the Tweet
        //     uint finalRating = 0;
        //     for(uint i = 0; i < 100; i++) {
        //         finalRating += votes[tweet][i].rating * (reputation / 1000); // Find a way to normalize the ratings
        //     }
        //     finalRating /= 100;

        //     tweetRating[tweet] = finalRating;
        // }
        // calculateNewReputation(tweet);
    }

    function calculateTweetRating (uint tweetId) public 
        returns (uint rating_)
    {
        for (uint r = 0; r < tweets[tweetId].votesNumber; r++) {
            rating_ += tweets[tweetId].tweetVoters[r].reputation;
        }
    }

    function calculateNewReputation(uint tweetId) internal {
        // People who guessed should be rewarded with high reputation and others should be penalized 
        // @todo: To implement https://codeforces.com/blog/entry/102 
    }
}
