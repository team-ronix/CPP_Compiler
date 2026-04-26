// should error: duplicate case value in switch statement
int x = 1;
switch (x) {
case 1:
    x = 10;
    break;
case 2:
    x = 20;
    break;
case 1:
    x = 30;
    break;
default:
    x = 0;
    break;
}
