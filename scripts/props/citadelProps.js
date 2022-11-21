const {fs} = require('file-system');

const CITADEL_MAX = 1024;

/*
PRESERVATIVE ALGORITHMS 516
MILITANT ALGORITHMS 256
ANTIMATTER ANNIHILATION 128
PROPULSION 64
POSTHUMANISM 32
ECOLOGICAL EXTRACTION 16
TECHNOCRACY 8
PROGINATOR PSI 4
*/
var techProps = [
    {
        addativeProbability: 0.5,
        probability: 0.5,
        value: "PRESERVATIVE ALGORITHMS",
        max: 512,
        running: 0,
    },
    {
        addativeProbability: 0.75,
        probability: .25,
        value: "MILITANT ALGORITHMS",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.875,
        probability: .125,
        value: "ANTIMATTER ANNIHILATION",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 0.9375,
        probability: .0625,
        value: "PROPULSION",
        max: 64,
        running: 0,
    },
    {
        addativeProbability: 0.96875,
        probability: .03125,
        value: "POSTHUMANISM",
        max: 32,
        running: 0,
    },
    {
        addativeProbability: 0.98437,
        probability: 0.01562,
        value: "ECOLOGICAL EXTRACTION",
        max: 16,
        running: 0,
    },
    {
        addativeProbability: 0.99218,
        probability: 0.00781,
        value: "TECHNOCRACY",
        max: 8,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: 0.00781,
        value: "PROGINATOR PSI",
        max: 8,
        running: 0,
    },
]


var nameProps = [
    "KALYFATE",
    "RREZTR PEZ",
    "THROSKENVORE",
    "SCARABOR",
    "ATAKSTAR",
    "SONCE",
    "LEIDENHEFT",
    "DONNERZUG",
    "TODLIEB",
    "TECAR",
    "GOR TACHT",
    "MAASDRACHT",
    "HEFTIG DEI",
    "ISKIL MAK",
    "HEFTIG DEI",
    "KILIGNIK",
]

let CITADEL = [];

function main() {
    for (let i = 0; i < CITADEL_MAX; i++) {

        const fileName = "output/" + i;
        let rawdata = fs.readFileSync(fileName);
        let citadel = JSON.parse(rawdata);
        citadel.attributes[0].display_type = "number";

        if (i < 10) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmcLvBkXVYTM4W8hcf35gLioXR3WeeYnKz9y2EUgdPmLNe/CITADEL000" + i +".png";
        } else if (i < 100) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmcLvBkXVYTM4W8hcf35gLioXR3WeeYnKz9y2EUgdPmLNe/CITADEL00" + i +".png";
        } else if (i < 1000) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmcLvBkXVYTM4W8hcf35gLioXR3WeeYnKz9y2EUgdPmLNe/CITADEL0" + i +".png";
        } else if (i < 1024) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmcLvBkXVYTM4W8hcf35gLioXR3WeeYnKz9y2EUgdPmLNe/CITADEL" + i +".png";
        }  

        CITADEL[i] = citadel;

    }

}

function printCitadel() {
    for (let i = 0; i < CITADEL_MAX; i++) {
        const citadel = CITADEL[i];
        //console.log("SEKT: " + citadel["SEKT"] + " ENGINE:" + citadel["ENGINE"]);
        //console.log(JSON.stringify(citadel));
        console.log(citadel.tokenId + " " + citadel.attributes[1].value + " " + citadel.attributes[5].value)
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

function writeCitadel() {
    console.log("write");
    for (let i = 0; i < CITADEL_MAX; i++) {
        citadel = CITADEL[i];
        fileName = "output/" + i;
        fs.writeFileSync(fileName, JSON.stringify(citadel));
    }
}


main();
printCitadel();
writeCitadel();
