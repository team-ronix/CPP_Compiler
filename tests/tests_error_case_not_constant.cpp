// should error: case label is not a constant expression
int z = 2;
int x = 1;

switch (x) {
case z:
    x = 10;
    break;
default:
    x = 0;
    break;
}
