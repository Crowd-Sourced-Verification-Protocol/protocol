/**
 * Refer https://www.codechef.com/ratings for exactitude
 */
pragma solidity ^0.4.17;
import "./FixidityLib.sol";
import "./LogarithmLib.sol";
import "./ExponentLib.sol";

library ELO {

    using FixidityLib for FixidityLib.Fixidity;
    using LogarithmLib for FixidityLib.Fixidity;
    using ExponentLib for FixidityLib.Fixidity;
    
    struct Scores {
        mapping(address => uint) rating;
        mapping(address => uint) volatility;
        mapping(address => uint) experience;
    }
    
    //Getters
    function getRating(Scores storage self, address player) internal view returns (uint) {
        if (self.rating[player] == 0) {
            return 1500;
        }
        return self.rating[player];
    }

    function getVolatility(Scores storage self, address player) internal view returns (uint) {
        if (self.rating[player] == 0) {
            return 125;
        }
        return self.rating[player];
    }

    function getExperience(Scores storage self, address player) internal view returns (uint) {
        return self.experience[player];
    }

    //Setters
    function setRating(Scores storage self, address player, uint rating) internal {
        self.rating[player] = rating;
    }

    function setVolatility(Scores storage self, address player, uint volatility) internal {
        if (volatility < 75) {
            self.volatility[player] = 75;
        }
        else if (volatility > 200) {
            self.volatility[player] = 200;
        }
        else 
            self.volatility[player] = volatility;
    }

    function incrementExperience(Scores storage self, address player) internal {
        self.experience[player]++;
    }

//Returns a fixed valuee
    function elo_ab(FixidityLib.Fixidity storage fixidity, uint rating_a, uint rating_b, uint volatility_a, uint volatility_b) view internal returns (int256) {
        int256 vol_sqrt = int256(volatility_a * volatility_a + volatility_b * volatility_b);
        vol_sqrt *= fixidity.fixed_1; //converting vol_sq to a fixed number
        vol_sqrt = fixidity.root_n(vol_sqrt, 2);
        
        int256 t = fixidity.subtract(int256(rating_a) * fixidity.fixed_1, int256(rating_b) * fixidity.fixed_1);
        t = fixidity.divide(t, vol_sqrt);
        t = fixidity.power_any(4 * fixidity.fixed_1, t);
        
        return fixidity.reciprocal(fixidity.add(fixidity.fixed_1, t));
    }

//Returns a fixed value
    function findCompetitionFactor(Scores storage self, address[] memory ranked_list, FixidityLib.Fixidity storage fixidity) view internal returns (int256) {
        int256 n = int256(ranked_list.length) * fixidity.fixed_1; //n is fixed_1
        
        int256 mean_rating = 0;
        for(uint i = 0; i < ranked_list.length; i++) {
            mean_rating += int256(getRating(self, ranked_list[i]));
        }
        mean_rating *= fixidity.fixed_1; //converting mean_rating to a fixed number
        mean_rating = fixidity.divide(mean_rating, n);
        
        int256 mean_squared_volatility = 0;
        for(i = 0; i < ranked_list.length; i++) {
            mean_squared_volatility += int256(getVolatility(self, ranked_list[i]) * getVolatility(self, ranked_list[i]));
        }
        mean_squared_volatility *= fixidity.fixed_1; //converting mean_squared_volatility to a fixed number
        mean_squared_volatility = fixidity.divide(mean_squared_volatility, n);
        
        int256 variance = 0;
        for(i = 0; i < ranked_list.length; i++) {
            int256 mean_diff = fixidity.subtract(int256(getRating(self, ranked_list[i])) * fixidity.fixed_1, mean_rating);
            mean_diff = fixidity.multiply(mean_diff, mean_diff);
            variance = fixidity.add(variance, mean_diff);
        }
        variance = fixidity.divide(variance, fixidity.subtract(n, fixidity.fixed_1));
        
        return fixidity.root_n(fixidity.add(mean_squared_volatility, variance), 2);
    }
    
    function updateRatings(Scores storage self, address[] memory ranked_list, FixidityLib.Fixidity storage fixidity) public {
        int256 n = int256(ranked_list.length) * fixidity.fixed_1; //n is fixed_1
        int256 cf = findCompetitionFactor(self, ranked_list, fixidity);
        
        for(uint i = 0; i < ranked_list.length; i++) {
            int256 actual_rank = int256(i + 1) * fixidity.fixed_1;
            int256 expected_rank = 0;
            
            //For loop for calculating expected ranked_list
            for(uint j = 0; j < ranked_list.length; j++) 
                if(i != j) {
                    expected_rank = fixidity.add(expected_rank, 
                                    elo_ab(fixidity, getRating(self, ranked_list[i]), getRating(self, ranked_list[j]), getVolatility(self, ranked_list[i]), getVolatility(self, ranked_list[j])));
                }
                
            int256 actual_performance = fixidity.log_any(fixidity.divide(n, actual_rank), 2 * fixidity.fixed_1);
            int256 expected_performance = fixidity.log_any(fixidity.divide(n, fixidity.subtract(expected_rank, fixidity.fixed_1)), 2 * fixidity.fixed_1);
            
            int256 tp = int256(getExperience(self, ranked_list[i])) * fixidity.fixed_1;
            int256 rating_weight = fixidity.divide(fixidity.add(fixidity.multiply(tp, 4 * fixidity.fixed_1 / 10),  2 * fixidity.fixed_1 / 10),
                                    fixidity.add(fixidity.multiply(tp, 7 * fixidity.fixed_1 / 10),  6 * fixidity.fixed_1 / 10));
            int256 vol_weight = fixidity.divide(fixidity.add(fixidity.multiply(tp, 5 * fixidity.fixed_1 / 10),  8 * fixidity.fixed_1 / 10),
                                    fixidity.add(tp, 6 * fixidity.fixed_1 / 10));
                                    
            int256 maxRating = 100 + 75 / (tp + 1) + 50000 / (abs((int256(getRating(self, ranked_list[i]))) - 1500) + 500); //NOT FIXED
            
            int256 oldRating = int256(getRating(self, ranked_list[i])); //NOT FIXED
            
            //Update Ratings
            int256 ratingChange = fixidity.multiply(fixidity.multiply(fixidity.subtract(actual_performance, expected_performance), cf), rating_weight);
            ratingChange /= fixidity.fixed_1; //Unfixing
            int256 newRating = oldRating + ratingChange;
            if(newRating < maxRating)
                setRating(self, ranked_list[i], uint(newRating));
            else
                setRating(self, ranked_list[i], uint(maxRating));
                
            //Update volatility
            int256 volatilitySq = int256(getVolatility(self, ranked_list[i]));
            volatilitySq *= volatilitySq;
            volatilitySq *= fixidity.fixed_1; //Fixing
            
            int256 ratingChangeSq = int256(getRating(self, ranked_list[i])) - oldRating;
            ratingChangeSq * ratingChangeSq;
            ratingChangeSq *= fixidity.fixed_1; //Fixing
            
            int256 newVolatility = fixidity.add(fixidity.multiply(vol_weight, ratingChangeSq), volatilitySq);
            newVolatility = fixidity.divide(newVolatility, fixidity.add(vol_weight, 11 * fixidity.fixed_1 / 10));
            newVolatility = fixidity.root_n(newVolatility, 2);
            newVolatility /= fixidity.fixed_1; //Unfixing
            setVolatility(self, ranked_list[i], uint(newVolatility));
            
            incrementExperience(self, ranked_list[i]);
        }
    }
    
    function abs(int value) pure internal returns (int){
        if (value>=0) return value;
        else return -1*value;
    }
    
}
