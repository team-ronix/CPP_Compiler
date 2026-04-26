int main () {
    int a = 12;
    int b = 5;
    int c = 0;
    float f = 2.5;
    float g = 4;
    char ch = 'A';
    bool flag = 1;

    c = a + b;
    c = c - 3;
    c = c * 2;
    c = c / 7;
    c = c % 3;

    f = f + g;
    f = f - 1;
    f = f * 2;
    f = f / 3;

    int fromChar = ch;
    float mixed = a + f;

    a++;
    a--;

    a += 2;
    a -= 1;
    a *= 3;
    a /= 2;
    a %= 5;

    bool c1 = a < b;
    bool c2 = a > b;
    bool c3 = a <= b;
    bool c4 = a >= b;
    bool c5 = a == b;
    bool c6 = a != b;

    bool l1 = c1 && c2;
    bool l2 = c1 || c2;
    bool l3 = !c1;

    flag = l1 || l3;
    return 0;
}