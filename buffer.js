
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