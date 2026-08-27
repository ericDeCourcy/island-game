
const ROWS = 16;
const COLS = 16;

/*
window.buffer = Array.from({ length: ROWS }, () =>
  Array.from({ length: COLS }, () => "empty")
);
*/

startpoint = 800;

window.buffer = Array.from({ length: ROWS }, (_, y) =>
    Array.from({ length: COLS }, (_, x) => ({ x: startpoint - (x * 42) + (y*42), y: 200 + (x*24) + (y*24), src: x > 7 && y > x ? 'fuzzygrass-b.png': (x + y) % 3 == 0 ? 'fuzzygrass-c.png' : 'fuzzygrass.png' }))  
);



dogpos = computeOffset(10,5,1);
window.buffer.push([
  { ...dogpos, src: 'OrangeDoggy-idle-lightoutline-gimped.gif' }
]);

plantpos = computeOffset(7,6,1);
window.buffer.push([ 
    { ...plantpos, src: 'redplant-defleck.gif'}
]);

pos = computeOffset(5,5,1);
window.buffer.push([{...pos, src: 'redplant-lifecycle.gif'}
]);

snailpos = computeOffset(2,10,1);
window.buffer.push([
  {...snailpos, src: 'BlueSnail-deflecked.gif'}
]);

birdpos = computeOffset(15,1,2);  // Note that this is at height 2, just for aesthetics (it is a bird)
window.buffer.push([
  {...birdpos, src: 'redbird-flap-gimped.gif'}
]);

shroompos = computeOffset(2,2,1);
window.buffer.push([
  {...shroompos, src: 'mushrooms-deflecked.gif'}
]);

function computeOffset(row, col, height = 0) {
  return {
    x: startpoint - (col * 42) + (row * 42),
    y: 200 + (col * 24) + (row * 24) - (height * 48)
  };
}