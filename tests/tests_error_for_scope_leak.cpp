// should error: i should not leak outside for scope
for (int i = 0; i < 2; i = i + 1) {
}
i = 7;
