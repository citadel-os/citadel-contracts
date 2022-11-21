const {fs} = require('file-system');

const CITADEL_MAX = 1024;

var sektProps = [
    {
        addativeProbability: 0.0625,
        probability: 0.0625,
        value: "RELIK",
        max: 64,
        running: 64,
    },
    {
        addativeProbability: 0.1875,
        probability: 0.125,
        value: "DROTH XYL",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 0.4375,
        probability: .25,
        value: "IONSLAUGHT",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: .5625,
        value: "ELEKT",
        max: 576,
        running: 0,
    },
];

var engineProps = [
    {
        addativeProbability: 0.5039,
        probability: 0.5039,
        value: "HAG GOTOR",
        max: 516,
        running: 0,
    },
    {
        addativeProbability: 0.7539,
        probability: .25,
        value: "CHOBAKK",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.8789,
        probability: .125,
        value: "TELUM MAK",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 0.9414,
        probability: .0625,
        value: "STROGOTHT",
        max: 64,
        running: 0,
    },
    {
        addativeProbability: 0.97265,
        probability: .03125,
        value: "FULTACHT MAK",
        max: 32,
        running: 0,
    },
    {
        addativeProbability: 0.98827,
        probability: 0.01562,
        value: "GLUASAD",
        max: 16,
        running: 0,
    },
    {
        addativeProbability: 0.99608,
        probability: 0.00781,
        value: "DSGILL MAK",
        max: 8,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: 0.00390,
        value: "DREADNAUGHT",
        max: 4,
        running: 0,
    },
];

var weaponsProps = [
    {
        addativeProbability: 0.5039,
        probability: 0.5039,
        value: "RRAKATAKHT FUROR",
        max: 516,
        running: 0,
    },
    {
        addativeProbability: 0.7539,
        probability: .25,
        value: "AG HALMAHHER",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.8789,
        probability: .125,
        value: "TELUM FUROR",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 0.9414,
        probability: .0625,
        value: "HALMAHHER FUROR",
        max: 64,
        running: 0,
    },
    {
        addativeProbability: 0.97265,
        probability: .03125,
        value: "DAG VERSTACKT",
        max: 32,
        running: 0,
    },
    {
        addativeProbability: 0.98827,
        probability: 0.01562,
        value: "VEERDACHT MAGH",
        max: 16,
        running: 0,
    },
    {
        addativeProbability: 0.99608,
        probability: 0.00781,
        value: "MARBHADH GHXST",
        max: 8,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: 0.00390,
        value: "DEI IUDICIUM",
        max: 4,
        running: 0,
    },
];

var shieldProps = [
    {
        addativeProbability: 0.5039,
        probability: 0.5039,
        value: "DAG SGIATH",
        max: 516,
        running: 0,
    },
    {
        addativeProbability: 0.7539,
        probability: .25,
        value: "XZCID MAGH",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.8789,
        probability: .125,
        value: "TELUM RATIO",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 0.9414,
        probability: .0625,
        value: "UNGARDROTHH",
        max: 64,
        running: 0,
    },
    {
        addativeProbability: 0.97265,
        probability: .03125,
        value: "DSGRILL RATIO",
        max: 32,
        running: 0,
    },
    {
        addativeProbability: 0.98827,
        probability: 0.01562,
        value: "DASKENWAFT",
        max: 16,
        running: 0,
    },
    {
        addativeProbability: 0.99608,
        probability: 0.00781,
        value: "MYSTERIUM",
        max: 8,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: 0.00390,
        value: "MARBHADH GREINE",
        max: 4,
        running: 0,
    },
];

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
        let sekt, engine = "";
        let citadel = {};
        if (i < 64) {
            sekt = "RELIK";
        } else {
            sekt = getRandomProperty(sektProps);
        }

        // if (i < 16) {
        //     citadel.name = nameProps[i];
        // } else {
        //     citadel.name = "CITADEL " + sekt;
        // }
        citadel.name = "CITADEL " + i;
        
        citadel.description = "CITADEL " + i;
        citadel.tokenId = i;
        if (i < 10) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmbjBhE5VZ7NVF5Q7yHK2qV82mzcysmh3wTog8PBuVvwqw/CITADEL000" + i +".png";
        }else if (i < 64) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmbjBhE5VZ7NVF5Q7yHK2qV82mzcysmh3wTog8PBuVvwqw/CITADEL00" + i +".png";
        } else if (i < 128) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmZnyEt8kGpatKFYxkmcarTSZqAAGLNB4Jzi3Bnxkp8yRC";
        } else if (i < 192) {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmbjBhE5VZ7NVF5Q7yHK2qV82mzcysmh3wTog8PBuVvwqw/CITADEL0" + i +".png";
        }
         else {
            citadel.image = "https://gateway.pinata.cloud/ipfs/QmZnyEt8kGpatKFYxkmcarTSZqAAGLNB4Jzi3Bnxkp8yRC";
        }
        
        citadel.attributes = [];
        engine = getRandomProperty(engineProps);
        weapons = getRandomProperty(weaponsProps);
        shield = getRandomProperty(shieldProps);

        citadel.attributes = 
        [
            {
                trait_type: "GENERATION",
                value: 0
            },
            {
                trait_type: "SEKT",
                value: sekt
            },
            {
                trait_type: "ENGINE",
                value: engine
            },
            {
                trait_type: "WEAPONS",
                value: weapons
            },
            {
                trait_type: "SHIELD",
                value: shield
            },
        ]
        
        CITADEL[i] = citadel;
    }
}

function printCitadel() {
    for (let i = 0; i < CITADEL_MAX; i++) {
        const citadel = CITADEL[i];
        //console.log("SEKT: " + citadel["SEKT"] + " ENGINE:" + citadel["ENGINE"]);
        //console.log(JSON.stringify(citadel));
        console.log(citadel.tokenId + " " + citadel.attributes[1].value)
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
