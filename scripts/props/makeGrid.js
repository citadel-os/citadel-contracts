const {fs} = require('file-system');

function main() {
    let grid = [];
    for(i=1; i <= 100; i++) {
        for(j=1; j <= 100; j++) {
            multiple = gridMultiple(i, j);
            grid.push(multiple);
        }
    }
    console.log(grid);
    writeGrid(grid);
}

function gridMultiple(x, y) {
    multiple = 1;
    if(x >= 40 && y >= 40 && x <= 60 && y <= 60) {
        multiple = 1.1;
        if(x >= 45 && x <= 55) {
            multiple = 1.2; 
        }
        if(y >= 45 && y <= 55) {
            multiple = 1.2; 
        }
        if(x == 50 && y == 50) {
            multiple = 1.25;
        }
    }
    return multiple;
}

function writeGrid(grid) {
    console.log("write");
    fileName = "output-grid/grid.json";
    fs.writeFileSync(fileName, JSON.stringify(grid));
}


main();