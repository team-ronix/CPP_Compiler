// should error: switch quantity must be an integer expression
float quantity = 2;

int main () {
switch ("abc") {
case 1:
    quantity = quantity + 1.0;
    break;
default:
    quantity = 0.0;
    break;
}
    return 0;
}