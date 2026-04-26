// should error: switch quantity must be an integer expression
float quantity = 2.5;

switch (quantity) {
case 1:
    quantity = quantity + 1.0;
    break;
default:
    quantity = 0.0;
    break;
}
