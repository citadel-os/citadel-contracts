const {fs} = require('file-system');

function main() {
    fileName = "output-pilot/pilot.sql";

    for(i=0; i<=1106; i++) {
        const fileName = "output-pilot-final/" + i;
        let rawdata = fs.readFileSync(fileName);
        let pilot = JSON.parse(rawdata);

        pilotSQL = "INSERT INTO pilot(id, death, subjugation) values(" + i + ", '" + pilot.attributes[2].value + "', '" + pilot.attributes[1].value + "');\n"
        
        fs.appendFile("pilot-sql/pilot.sql", pilotSQL, function (err) {});
    }

}


main();