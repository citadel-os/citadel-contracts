Game Contracts MVP

citadel nft
pilot nft
drakma
citadel game
citadel lit
pilot lit

game contract
	imports
		- citadel nft
		- pilot nft
		- citadel lit
        - pilot lit
	implements
		- stake to faction
		- claiming
		- grid
		- raid


citadel lit (no public functions)
	- level
	- shield, weapon system, engine
	- fleet
	- mines
	- calc OP
	- calc DP
    - mine drakma
	- raise fleet


fleet
purchase
upgrade academy
uplevel

game contract
staking => stake citadel, pilot. research tech. build fleet. 
mining => mine drakma. claim drakma. 
grid => 8096 tiles. each has id. coordinates and mining rate. lit by flag.

raid(from, to, fleet[], pilot)
combat => calculates offensive power (from). calculates defensive power (to). assigns damage. takes drakma.
offensive power => fleet count 


