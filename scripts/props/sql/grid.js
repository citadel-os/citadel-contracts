const {fs} = require('file-system');

function main() {
    fileName = "output-grid/grid.sql";

    for(i=0; i<=1023; i++) {
        multiple = gridMultiple(i);
        gridSQL = "INSERT INTO grid(id, isLit, multiple) values(" + i + ", false, " + multiple + ");\n"
        
        fs.appendFile(fileName, gridSQL, function (err) {});
    }

}

function gridMultiple(_gridId) {
    multiple = 1;
    if(_gridId >= 410 && _gridId <= 615) {
        multiple = 1.1;
        if(_gridId >= 460 && _gridId <= 564) {
            multiple = 1.2;
        }
        if(_gridId >= 487 && _gridId <= 537) {
            multiple = 1.25;
        }
    }
    return multiple;
}



main();