void main() {
  var point = (x: 10, y: 20);
  var (:x, :y) = point; // ❌ FAILS
  print('x=$x, y=$y');
}
