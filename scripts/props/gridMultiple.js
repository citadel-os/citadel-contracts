const {fs} = require('file-system');

function main() {
    let grid = [];
    for(i=0; i <= 1023; i++) {
        multiple = getGridMultiple(i);
        grid.push(multiple);
    }
    writeGrid(grid);
}

function getGridMultiple(_gridId) {
    let multiple = 0;
    if(_gridId >= 410 && _gridId <= 615) {
        multiple = 10;
        if(_gridId >= 460 && _gridId <= 564) {
            multiple = 20; 
        }
        if(_gridId >= 487 && _gridId <= 537) {
            multiple = 25;
        }
    }
    
    return multiple;
}


function writeGrid(grid) {
    console.log("write");
    console.log(grid);
    fileName = "grid.csv";
    
    fs.writeFileSync(fileName, JSON.stringify(grid));
}


main();