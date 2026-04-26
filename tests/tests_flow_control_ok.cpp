int main () {
    int a = 0;
    int sum = 0;

    if (a == 0) {
        sum = 1;
    }

    if (a == 0) {
        sum = 1;
    } else {
        sum = 2;
    }

    if (a == 0) {
        sum = 1;
    } else if (a > 0) {
        sum = 2;
    } else {
        sum = 3;
    }

    if (a > 0) 
        sum = sum + 10; 
    else 
        sum = sum + 20;

    if (a > 0) 
        sum = sum + 10; 
    else if (a < 0)
        sum = sum + 20;

    if (a > 0) 
        sum = sum + 10; 
    else if (a < 0)
        sum = sum + 20;
    else
        sum = sum + 30;
    

    while (a < 3) {
        if (a == 1) {
            a = a + 1;
            continue;
        }
        sum = sum + a;
        a = a + 1;
    }

    while (true) {
        if(sum > 100) {
            break;
        }
        sum = sum + 10;
    }

    while ('a') {
        if(sum > 100) {
            break;
        }
        sum = sum + 10;
    }

    do {
        sum = sum + 2;
    } while (sum < 10);

    for (int i = 0; i < 4; i = i + 1) {
        if (i == 2) {
            continue;
        }

        switch (i) {
            case 0:
                sum = sum + 10;
                break;
            case 1:
                sum = sum + 20;
                break;
            default:
                sum = sum + 30;
        }

        if (sum > 80) {
            break;
        }
    }
    int i = 0;
    for( ; i < 5; i = i + 1) {
        if (i == 3) {
            break;
        }
        sum = sum + i;
    }

     for( ;i < 5;) {
        if (i == 3) {
            break;
        }
        sum = sum + i;
    }

    for( ;; i = i + 1) {
        if (i == 3) {
            break;
        }
        sum = sum + i;
    }


    for(;;) {
        if (i == 3) {
            break;
        }
        i = i + 1;
        sum = sum + i;
    }

    int flag = 0;
    switch (sum) {
        case 10:
            flag = 1;
            break;
        case 20:
            flag = 2;
            break;
        default:
            flag = 3;
    }


    switch (sum) {
        case 10:
        case false:
            flag = 1;
            break;
        case true == true:
            flag = 1;
            break;
        case 1+ 2:
            flag = 2;
            break;
        case 'a':
            flag = 2;
            break;
        case 'b' + 1:
            flag = 2;
            break;
        default:
            flag = 3;
    }

    bool ok = flag != 0;
    return ok;
}