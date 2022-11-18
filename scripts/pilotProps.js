const {fs} = require('file-system');

const PILOT_MAX = 2048;
let PILOT = [];
pilotToReveal = [
    5,
    262,
    266,
    267,
    268,
    269,
    270,
    271,
    273,
    274,
    275,
    276,
    277,
    278,
    280,
    281,
    282,
    283,
    284,
    286,
    288,
    289,
    290,
    291,
    292,
    293,
    294,
    295,
    296,
    297,
    298,
    299,
    300,
    301,
    302,
    303,
    305,
    306,
    307,
    308,
    309,
    310,
    312,
    313,
    314,
    315,
    316,
    317,
    319,
    320,
    321,
    322,
    323,
    324,
    325,
    326,
    328,
    329,
    330,
    332,
    333,
    334,
    335,
    336,
    337,
    338,
    340,
    341,
    342,
    343,
    344,
    345
];


function main() {


    for (let i = 0; i < PILOT_MAX; i++) {

        const fileName = "output-pilot-final/" + i;
        let rawdata = fs.readFileSync(fileName);
        let pilot = JSON.parse(rawdata);
        pilot.image = "https://gateway.pinata.cloud/ipfs/QmPqgDBStUJeKa6bYugsX5WjpYDaypMaHJBzZnYjX7qztH";
        if(pilotToReveal.find(element => element == i)) {
            pilot.image = "https://gateway.pinata.cloud/ipfs/QmawkutBS3biQLsRG3ofiazbu5H3DeRczyqT5JseK6AbvF/PILOT" + i + ".png";
        }

        PILOT[i] = pilot;
    }

}

function printPilot() {
    for (let i = 0; i < PILOT_MAX; i++) {
        const pilot = PILOT[i];
        console.log(pilot.tokenId + " " + pilot.attributes[1].value + " " + pilot.attributes[2].value)
    }
}

function getRandomProperty(props) {
    var num = Math.random();
    for (let i = 0; i < props.length; i++) {
        prop = props[i];
        if (num < prop["addativeProbability"]) {
            if(prop["running"] < prop["max"]) {
                running = prop["running"] + 1
                props[i].running = running;
                rarity = prop["probability"] * 100
                return prop["value"];
            } else {
                return getRandomProperty(props);
            }
        }
    }
}

function writePilot() {
    console.log("write");
    for (let i = 0; i < PILOT_MAX; i++) {
        pilot = PILOT[i];
        fileName = "output-pilot-final/" + i;
        fs.writeFileSync(fileName, JSON.stringify(pilot));
    }
}


main();
printPilot();
writePilot();
