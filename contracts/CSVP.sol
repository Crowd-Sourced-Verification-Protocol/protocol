pragma solidity >=0.4.22 <0.6.0;
import "./Elo.sol";
import "./FixidityLib.sol";
import "./ExponentLib.sol";

/// @title Croud Source Verification Protocol
contract Csvp {

    using FixidityLib for FixidityLib.Fixidity;
    using LogarithmLib for FixidityLib.Fixidity;
    using ExponentLib for FixidityLib.Fixidity;
    
    struct Vote {
        uint rate; // Voter has to give the tweet a rating from 1 to 100.
        address id;
        uint voteTime;
    }
    
    ELO.Scores scores;
    FixidityLib.Fixidity fixidity;
    
    function fixiCheck() public view returns (int256) {
        return fixidity.power_any(int256(16 * fixidity.fixed_1), -2000000000000000);
    }
    
    // Tweet refers to any post on any social nw
    struct Tweet {
        uint rating;
        address addedBy;
        bool underReview;
        Vote[] votes;
    }

    mapping(address => bool) public voters;
    mapping(uint => Tweet) public tweets;

    address public owner;

    constructor() public {
        owner = msg.sender;
        fixidity.init(24);
    }

    function giveRightToVote(address voter) public {
        require(
            msg.sender == owner,
            "Only owner can give the right to vote"
        );
        require(voters[voter] == false, "Voter Already has voting right");
        voters[voter] = true;
    }

    function addTweet(uint tweetId) public  {
        require(tweets[tweetId].addedBy == address(0), "Tweet already exists");
        tweets[tweetId].addedBy = msg.sender;
        tweets[tweetId].underReview = true;
    }

    function addVote(uint tweetId, uint rating) public {
        require(voters[msg.sender] == true, "This address isn't authorized to vote");
        require(tweets[tweetId].addedBy != address(0), "Tweet isn't added for voting");
        require(tweets[tweetId].underReview == true, "Tweet closed for review");
        tweets[tweetId].votes.push(Vote({
            rate: rating,
            id: msg.sender,
            voteTime: block.timestamp
        }));
    }

    function calculateTweetRating (uint tweetId) public {
        require(tweets[tweetId].addedBy != address(0), "Tweet isn't added for voting");
        require(tweets[tweetId].underReview == true, "Poll already ended");
        tweets[tweetId].underReview = false;
        uint totalWeight = 0;
        uint totalRating = 0;
        for(uint i = 0; i < tweets[tweetId].votes.length; i++) {
            // (pseudo)Randomly select 50% of the votes
            address voterAddress = tweets[tweetId].votes[i].id;
            if(uint(voterAddress) * block.timestamp % 2 == 0) {
                totalWeight += scores.rating[voterAddress];
                totalRating += tweets[tweetId].votes[i].rate * scores.rating[voterAddress];
            }
        }
        tweets[tweetId].rating = totalRating / totalWeight;
        calculateNewReputation(tweetId);
    }

    function calculateNewReputation(uint tweetId) internal {
        // People who guessed should be rewarded with high reputation and others should be penalized 
        Vote[] memory votes = tweets[tweetId].votes;
        qSortVotes(votes, 0, votes.length - 1, tweets[tweetId].rating);
        address[] memory ranked_list = new address[](votes.length);
        for(uint i = 0; i < votes.length; i++) {
            ranked_list[i] = votes[i].id;
        }
        ELO.updateRatings(scores, ranked_list, fixidity);
    }
    
    function abs(int value) pure internal returns (uint){
        if (value>=0) return uint(value);
        else return uint(-1*value);
    }
    
    function compareVotes(Vote memory a, Vote memory b, uint tweetRating) internal pure returns (bool){
        if(abs(int(a.rate) - int(tweetRating)) != abs(int(b.rate) - int(tweetRating)))
            return abs(int(a.rate) - int(tweetRating)) < abs(int(b.rate) - int(tweetRating));
        return a.voteTime < b.voteTime;
    }
    
    function qSortVotes(Vote[] memory votes, uint left, uint right, uint tweetRating) internal pure{
        if(left >= right)
            return;
        (votes[left], votes[(left + right) / 2]) = (votes[(left + right) / 2], votes[left]);
        uint last = left;
        for(uint i = left + 1; i <= right; i++) {
            if(compareVotes(votes[i], votes[left], tweetRating)){
                last++;
                (votes[i], votes[last]) = (votes[last], votes[i]);
            }
        }
        (votes[left], votes[last]) = (votes[last], votes[left]);
        qSortVotes(votes, left, last - 1, tweetRating);
        qSortVotes(votes, last + 1, right, tweetRating);
    }
    
}
