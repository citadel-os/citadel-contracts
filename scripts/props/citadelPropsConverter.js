const {fs} = require('file-system');

const CITADEL_MAX = 1024;


let CITADEL = [];

function main() {
    for (let i = 0; i < CITADEL_MAX; i++) {

        const fileName = "output/" + i;
        let rawdata = fs.readFileSync(fileName);
        let citadel = JSON.parse(rawdata);
        CITADEL[i] = citadel;
    }
}

function printCitadel() {
    var sektStr = "uint8[] public sektMultiple = ["
    var techStr = "uint8[] public techProp = ["
    var engineStr = "uint8[] public engineProp = ["
    var weaponsStr = "uint8[] public weaponsProp = ["
    var shieldStr = "uint8[] public shieldProp = ["
    for (let i = 0; i < 1024; i++) {
        const citadel = CITADEL[i];
        sektMultiple = 2;
        switch(citadel.attributes[1].value) {
            case "RELIK":
                sektMultiple = 16;
                break;
            case "DROTH XYL":
                sektMultiple = 8;
                break;
            case "IONSLAUGHT":
                sektMultiple = 4;
                break;
            default:
                sektMultiple = 2;
                break;
        }
        engine = 0;
        switch(citadel.attributes[2].value) {
            case "CHOBAKK":
                engine = 1;
                break;
            case "TELUM MAK":
                engine = 2;
                break;
            case "STROGOTHT":
                engine = 3;
                break;
            case "FULTACHT MAK":
                engine = 4;
                break;
            case "GLUASAD":
                engine = 5;
                break;
            case "DSGILL MAK":
                engine = 6;
                break;
            case "DREADNAUGHT":
                engine = 7;
                break;
        }
        weapon = 0;
        switch(citadel.attributes[3].value) {
            case "AG HALMAHHER":
                weapon = 1;
                break;
            case "TELUM FUROR":
                weapon = 2;
                break;
            case "HALMAHHER FUROR":
                weapon = 3;
                break;
            case "DAG VERSTACKT":
                weapon = 4;
                break;
            case "VEERDACHT MAGH":
                weapon = 5;
                break;
            case "MARBHADH GHXST":
                weapon = 6;
                break;
            case "DEI IUDICIUM":
                weapon = 7;
                break;
        }
        shield = 0;
        switch(citadel.attributes[4].value) {
            case "XZCID MAGH":
                shield = 1;
                break;
            case "TELUM RATIO":
                shield = 2;
                break;
            case "UNGARDROTHH":
                shield = 3;
                break;
            case "DSGRILL RATIO":
                shield = 4;
                break;
            case "DASKENWAFT":
                shield = 5;
                break;
            case "MYSTERIUM":
                shield = 6;
                break;
            case "MARBHADH GREINE":
                shield = 7;
                break;
        }
        tech = 0;
        switch(citadel.attributes[5].value) {
            case "MILITANT ALGORITHMS":
                tech = 1;
                break;
            case "ANTIMATTER ANNIHILATION":
                tech = 2;
                break;
            case "PROPULSION":
                tech = 3;
                break;
            case "POSTHUMANISM":
                tech = 4;
                break;
            case "ECOLOGICAL EXTRACTION":
                tech = 5;
                break;
            case "TECHNOCRACY":
                tech = 6;
                break;
            case "PROGINATOR PSI":
                tech = 7;
                break;
        }
        sektStr += sektMultiple + ",";
        techStr += tech + ",";
        weaponsStr += weapon + ",";
        engineStr += engine + ",";
        shieldStr += shield + ",";
    }
    sektStr += "];";
    techStr += "];";
    weaponsStr += "];";
    engineStr += "];";
    shieldStr += "];";
    console.log(weaponsStr);
    console.log(engineStr);
    console.log(shieldStr);
    console.log(sektStr);
}




main();
printCitadel();