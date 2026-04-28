int test(int x)
{
    return x;
}

int main()
{
    int x = 'x';
    int y = 1.5;
    int z = true;
    float a = 1;
    char b = 65;
    bool c = 0;
    int d = test(1.5);
    int e = test(true);
    int f = test('x');
    bool g = 0.1;
    bool h = 'A';
    float j = 'B';
    int n = test(2.7);
    return 0;
}
