// should error: calling undefined function
int x;
int a = x + 1;
int main(int x = 4) {
    x = x + 1;
    return x;
}
