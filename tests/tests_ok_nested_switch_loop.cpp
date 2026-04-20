// should pass: switch nested inside loop with continue/break
int i = 0;
while (i < 5) {
    i++;
    switch (i) {
        case 1:
            continue;
        case 3:
            break;
    }
}
