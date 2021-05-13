//Elo Logic. Refer https://www.codechef.com/ratings for exactitude
#include <bits/stdc++.h>
using namespace std;
#define abs(a) ((a) > 0 ? (a) : -(a))
#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) > (b) ? (a) : (b))

map<int, double> ratings;
map<int, double> volatility;
map<int, int> times_played;

//If someone is new, his rating is 1500
double get_rating(int address){
    if(ratings.find(address) == ratings.end())
        return ratings[address] = 1500;
    return ratings[address];
}

//If someone is new, his volatility is 125
double get_volatility(int address){
    if(volatility.find(address) == volatility.end())
        return volatility[address] = 125;
    return volatility[address];
}

static double inline elo_ab(double rating_a, double rating_b, double volatility_a, double volatility_b) {
    return 1 / (1 + pow(4, (rating_a - rating_b) / pow(volatility_a * volatility_a + volatility_b * volatility_b, 0.5)));
}

double find_competition_factor(const vector<int> ranked_list) {
    int n = ranked_list.size();

    double mean_rating = 0;
    for(int i = 0; i < n; i++)
        mean_rating += get_rating(ranked_list[i]);
    mean_rating /= n;

    double mean_squared_volatility = 0;
    for(int i = 0; i < n; i++)
        mean_squared_volatility += get_volatility(ranked_list[i]) * get_volatility(ranked_list[i]);
    mean_squared_volatility /= n; 

    double variance = 0;
    for(int i = 0; i < n; i++)
        variance += (get_rating(ranked_list[i]) - mean_rating) * (get_rating(ranked_list[i]) - mean_rating);
    variance /= n - 1;
    
    return pow(mean_squared_volatility + variance, 0.5);

}

//Takes ranked_list in sorted order of ranks
void update_ratings(vector<int> ranked_list){
    int N = ranked_list.size();
    double cf = find_competition_factor(ranked_list);

    for(int i = 0; i < N; i++) {
            
            double actual_rank = i + 2;
            double expected_rank = 0;
            //For loop for calculating expected rank
            for(int j = 0; j < N; j++)
                if(i != j)
                    expected_rank += elo_ab(get_rating(ranked_list[i]), get_rating(ranked_list[j]),
                                    get_volatility(ranked_list[i]), get_volatility(ranked_list[j]));
                
            double actual_performance = log2(N / (actual_rank - 1)) / 2;
            double expected_performance = log2(N / (expected_rank - 1)) / 2;

            int tp = times_played[ranked_list[i]];

            double rating_weight = (tp * 0.4 + 0.2) / (tp * 0.7 + 0.6);
            double volatility_weight = (tp * 0.5 + 0.8) / (tp + 0.6);

            //Update Ratings
            int max_rating = 100 + 75 / (tp + 1) + 50000 / (abs(get_rating(ranked_list[i]) - 1500) + 500);
            double old_rating = get_rating(ranked_list[i]);
            ratings[ranked_list[i]] = max(max_rating, 
                    get_rating(ranked_list[i]) + (actual_performance - expected_performance) * cf * rating_weight);

            //Update Volatility
            volatility[ranked_list[i]] = pow((volatility_weight * (get_rating(ranked_list[i]) - old_rating) * 
                    (get_rating(ranked_list[i]) - old_rating) + get_volatility(ranked_list[i]) * get_volatility(ranked_list[i])) / (volatility_weight + 1.1), 0.5);
            if(get_volatility(ranked_list[i]) < 75)
                volatility[ranked_list[i]] = 75;
            if(get_volatility(ranked_list[i]) > 200)
                volatility[ranked_list[i]] = 200;
    }
}

int main() {
    vector<int> ranked_list = {1, 2, 3, 4, 5, 6, 7, 8};
    update_ratings(ranked_list);
    for(auto x: ratings)
        printf("%d: %f\n", x.first, x.second);
}

