void doNothing()
{
}

int identity(int x)
{
    return x;
}

int add(int a, int b)
{
    return a + b;
}

int rec(int x)
{
    if (x <= 0)
    {
        return 0;
    }
    else
    {
        return x + rec(x - 1);
    }
}

int allBranchesReturn(int x)
{
    if (x > 0)
    {
        return 1;
    }
    else
    {
        return -1;
    }
}

int switchAllReturn(int x)
{
    switch (x)
    {
    case 1:
        return 10;
        break;
    case 2:
        return 20;
        break;
    default:
        return 0;
        break;
    }
}

int switchFallThrough(int x)
{
    switch (x)
    {
    case 1:
    case 2:
        return 10;
        break;
    default:
        return 0;
        break;
    }
}

int withDefault(int a, int b = 5)
{
    return a + b;
}

int multiDefault(int a = 1, int b = 2)
{
    return a + b;
}

int globalVal = 42;

int readGlobal()
{
    return globalVal;
}

int main()
{
    // 9. explicit args
    int r1 = add(3, 4);

    // 10. default args
    int r2 = withDefault(10);
    int r3 = multiDefault();

    // 11. nested calls
    int r4 = add(identity(2), add(1, 1));

    // 12. global then local with same name — inner shadows outer
    int globalVal = 99;
    int r5 = globalVal;

    // 13. inner scope shadows
    int x = 1;
    {
        int x = 2;
        x = x + 1;
    }
    x = x + 10;

    // 14. sibling scopes — same name in each, no conflict
    {
        int tmp = 1;
        tmp = tmp + 1;
    }
    {
        int tmp = 2;
        tmp = tmp + 2;
    }

    // 15. read global through function
    int r6 = readGlobal();

    // 16. void function call as statement
    doNothing();

    // 17. Deeply nested scopes — variables visible in inner, not after
    {
        int level1 = 1;
        {
            int level2 = level1 + 1;
            {
                int level3 = level2 + 1;
                level3 = level3 + level1;
            }
        }
    }

    // 18. Reassigning a parameter inside function body (done via local var)
    int p = 5;
    p = add(p, 1);

    // 19. Function result used directly in expression
    int r7 = add(1, 2) + add(3, 4);

    // 20. allBranchesReturn called — no warning expected
    int r8 = allBranchesReturn(10);
    int r9 = allBranchesReturn(-5);

    return 0;
}
