// should pass: nested block scope and lookup
int a = 1;
{
    int b = a + 2;
    {
        int c = b + a;
        c = c + 1;
    }
    b = b + 1;
}
