// should pass: loop variable stays inside loop scope
for (int i = 0; i < 2; i = i + 1) {
    int t = i;
}
int k = 5;
