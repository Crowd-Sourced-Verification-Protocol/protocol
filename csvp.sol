pragma solidity >=0.4.22 <0.6.0;

/// @title Croud Source Verification Protocol
contract Csvp {

    struct Vote {
        address voter;
        uint reputation; //reputation bw 1-1000
        uint rating; //rating bw 1-1000
    }
    
    // Tweet refers to any post on any social nw, will add more fields later
    struct Tweet {
        uint tweetId;
    }

    mapping(Tweet => Vote[]) public votes; 
    mapping(address => uint) public reputation; //Reputation is always a positive number. Reputation equals 0 means unrated
    mapping(Tweet => uint) public tweetRating; 

    constructor() public {}

    //On 100th Vote, this function will calculate the rating of the tweet
    function rateTweet(uint rating, uint tweetId) public {
        Tweet tweet = Tweet{tweetId: tweetId};

        require(votes[tweet].length < 100);

        votes[tweet].push(
            Vote{
                voter: msg.sender,
                reputation: reputation[msg.sender], 
                rating: rating
            });
        
        if(votes[tweet].length == 100) {
            //Time to calculate final rating of the Tweet
            uint finalRating = 0;
            for(uint i = 0; i < 100; i++) {
                finalRating += votes[tweet][i].rating * (reputation / 1000); // Find a way to normalize the ratings
            }
            finalRating /= 100;

            tweetRating[tweet] = finalRating;
        }
        calculateNewReputation(tweet);
    }

    function calculateNewReputation(Tweet tweet) internal {
        // People who guessed should be rewarded with high reputation and others should be penalized 
        //TODO: To implement https://codeforces.com/blog/entry/102 
    }
}
