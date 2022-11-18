const {fs} = require('file-system');

const PILOT_MAX = 2048;

var subjugationProps = [
    {
        addativeProbability: 0.5,
        probability: 0.5,
        value: "HERMETIC STRACHT",
        max: 1024,
        running: 0,
    },
    {
        addativeProbability: 0.75,
        probability: .25,
        value: "POTENTATE COERCION",
        max: 512,
        running: 0,
    },
    {
        addativeProbability: 0.875,
        probability: .125,
        value: "DREDGE NOBILITY",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.9375,
        probability: .0625,
        value: "ALKAHEST DRIFT",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 0.96875,
        probability: .03125,
        value: "CRHONA THROT",
        max: 64,
        running: 0,
    },
    {
        addativeProbability: 0.984375,
        probability: 0.01562,
        value: "SIF COMMANDER",
        max: 32,
        running: 0,
    },
    {
        addativeProbability: 0.9921875,
        probability: 0.00781,
        value: "PSIONIC FUROR",
        max: 16,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: 0.00781,
        value: "TECHNOCRAT ARMAMENT",
        max: 16,
        running: 0,
    },
];

var kultProps = [
    {
        addativeProbability: 0.25,
        probability: 0.25,
        value: "KULT GEHEIM",
        max: 512,
        running: 0,
    },
    {
        addativeProbability: 0.375,
        probability: .125,
        value: "DØD ENGEL",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.5,
        probability: .125,
        value: "STALKROTH",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.625,
        probability: .125,
        value: "KULT GOR",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.75,
        probability: .125,
        value: "KLINGE",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.875,
        probability: .125,
        value: "DALK STRACHT",
        max: 256,
        running: 0,
    },
    {
        addativeProbability: 0.9375,
        probability: .0625,
        value: "YS DIABOLI",
        max: 128,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: .0625,
        value: "GRÅTER DJEVEL",
        max: 128,
        running: 0,
    },
];

var deathPilotProps = [
    {
        addativeProbability: 0.03125,
        probability: 0.03125,
        value: "ETERNAL",
        max: 64,
        running: 0,
    },
    {
        addativeProbability: 1,
        probability: 0.96875,
        value: "VOID",
        max: 1984,
        running: 0,
    }
];

let PILOT = [];

function main() {
    for (let i = 0; i < PILOT_MAX; i++) {
        
        pilot = {};
        pilot.tokenId = i;
        pilot.name = "PILOT " + i;
        pilot.description = "PILOT " + i;
        pilot.image = "https://gateway.pinata.cloud/ipfs/QmPqgDBStUJeKa6bYugsX5WjpYDaypMaHJBzZnYjX7qztH";
        pilot.attributes = [];
        
        // let subjugation, kult, death = "";
        subjugation = getRandomProperty(subjugationProps);
        // kult = getRandomProperty(kultProps);
        death = getRandomProperty(deathPilotProps);

        pilot.attributes = 
        [
            {
                trait_type: "GENERATION",
                value: 0
            },
            {
                trait_type: "SUBJUGATION",
                value: subjugation
            },
            {
                trait_type: "DEATH",
                value: death
            }
            // {
            //     trait_type: "KULT",
            //     value: kult
            // },
        ]
        
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

//main();
//printPilot();
//writePilot();
