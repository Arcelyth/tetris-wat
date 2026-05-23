const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

const importObject = {
    canvas:{
        getCtx: () => ctx
    },
    draw: {
        setFillColor: (ctx, r, g, b) => ctx.fillStyle = `rgb(${r}, ${g}, ${b})`,
        fillRect: (ctx, x, y, w, h) => ctx.fillRect(x, y, w, h),
        updateUI: (scores, lines) => {
            document.getElementById("scores").innerText = scores;
            document.getElementById("lines").innerText = lines;
        }
    },
    tool: {
        random: () => Math.floor(Math.random() * 7),
        alert: (scores) => alert("Game Over: " + scores) 
    }

}

WebAssembly.instantiateStreaming(fetch("./tetris.wasm"), importObject).then((obj) => {
    const exports = obj.instance.exports;
    exports.init();
    
    function gameLoop(timestamp = 0) {
        exports.update(timestamp);
        requestAnimationFrame(gameLoop);
    }

    requestAnimationFrame(gameLoop);

    document.addEventListener("keydown", (event) => {
        switch(event.code) {
            case "ArrowLeft": 
              exports.move(-1);
              break;
            case "ArrowRight":
              exports.move(1);
              break;
            case "ArrowUp": 
              exports.curRotate();
              break;
            case "ArrowDown":
              exports.drop();
              break;
        }
    });
})
